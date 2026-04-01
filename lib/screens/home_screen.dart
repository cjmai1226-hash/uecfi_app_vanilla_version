import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../services/ad_service.dart';
import '../providers/settings_provider.dart';
import 'menu/edit_profile_screen.dart';
import 'comments_screen.dart';
import 'forms/create_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildEmptyState(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No posts yet!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to share something with the community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textColor.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text(
                'Share a Post',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset('assets/images/image.png'),
        ),
        title: const Text('Community Feed'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getCommunityPostsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading feed: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(context);
              }

              // Filter out explicitly reported arrays synchronously
              final posts = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isReported'] != true;
              }).toList();

              if (posts.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                itemCount: posts.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                    if (index == posts.length) return const AdBannerWidget();
                  final postDoc = posts[index];
                  final data = postDoc.data() as Map<String, dynamic>;

                  final likedBy = List<String>.from(data['likedBy'] ?? []);
                  final isLiked = likedBy.contains(settings.userId);

                  final postNode = {
                    'id': postDoc.id,
                    'username': data['authorNickname'] ?? 'Unknown',
                    'avatarIndex': data['avatarIndex'] ?? 0,
                    'time': _formatTimestamp(data['timestamp']),
                    'content': data['content'] ?? '',
                    'likes': data['likes'] ?? 0,
                    'comments': data['comments'] ?? 0,
                    'isLiked': isLiked,
                  };

                  return _PostCard(
                    key: ValueKey(postNode['id']),
                    post: postNode,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    }
    return '';
  }
}

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const _PostCard({super.key, required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _isExpanded = false;
  late bool _isLiked;
  late int _likesCount;

  // Truncation constraints
  final int _textLimit = 150;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post['isLiked'] ?? false;
    _likesCount = widget.post['likes'] ?? 0;
  }

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post['likes'] != widget.post['likes'] ||
        oldWidget.post['isLiked'] != widget.post['isLiked']) {
      _likesCount = widget.post['likes'] ?? 0;
      _isLiked = widget.post['isLiked'] ?? false;
    }
  }

  void _toggleLike() {
    final currentUserUid = context.read<SettingsProvider>().userId;
    final bool currentlyLiked = _isLiked;

    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _likesCount++ : _likesCount--;
    });
    FirestoreService().togglePostLike(
      widget.post['id'],
      currentlyLiked,
      currentUserUid,
    );
  }

  void _handleCommentAttempt(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    // Explicit Identity Rule: Must have valid Email, District, and Position remotely logged.
    if (settings.email.isEmpty ||
        settings.email == 'user@example.com' ||
        settings.district.isEmpty ||
        settings.position.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Profile Required',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You must complete your Identity Profile Setup (including District and Position strings mapped securely into the Cloud) before participating in Community discussions!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
              child: const Text(
                'Setup Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Provide routing to the physical Commenting Modal Sheet!
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(postNode: widget.post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final String content = widget.post['content'] ?? '';
    final bool isLongText = content.length > _textLimit;

    final String displayText = (_isExpanded || !isLongText)
        ? content
        : '${content.substring(0, _textLimit)}...';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                radius: 20,
                child: Icon(
                  SettingsProvider.avatarIcons[widget.post['avatarIndex'] ?? 0],
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post['username'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    Text(
                      widget.post['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  color: textColor.withValues(alpha: 0.5),
                ),
                onSelected: (value) async {
                  if (value == 'report') {
                    await FirestoreService().reportPost(widget.post['id']);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Post reported and hidden.'),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Report Post',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Body Content
          Text(
            displayText,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: textColor.withValues(alpha: 0.9),
            ),
          ),

          // Show More / Less Toggle
          if (isLongText)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  _isExpanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
          Divider(color: textColor.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 8),

          // Interaction Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InteractionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                label: '$_likesCount',
                color: _isLiked
                    ? Colors.redAccent
                    : textColor.withValues(alpha: 0.6),
                onTap: _toggleLike,
              ),
              _InteractionButton(
                icon: Icons.chat_bubble_outline,
                label: '${widget.post['comments']}',
                color: textColor.withValues(alpha: 0.6),
                onTap: () => _handleCommentAttempt(context),
              ),
              _InteractionButton(
                icon: Icons.ios_share_outlined,
                label: 'Share',
                color: textColor.withValues(alpha: 0.6),
                onTap: () {
                  final textToShare =
                      '${widget.post['username']} shared on UECFI: "${widget.post['content']}"';
                  SharePlus.instance.share(ShareParams(text: textToShare));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../providers/settings_provider.dart';
import '../services/ad_service.dart';
import 'comments_screen.dart';
import 'forms/create_post_screen.dart';
import 'search_screen.dart';
import '../utils/color_utils.dart';
import 'menu/profile_screen.dart';
import '../widgets/main_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenDrawer});

  final VoidCallback? onOpenDrawer;

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No posts yet!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to share something with the community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text('Share a Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: 'Community Forum',
        onOpenDrawer: onOpenDrawer,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirestoreService().getCommunityPostsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text('Error loading feed: ${snapshot.error}'),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(context),
                    );
                  }

                  final posts = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['isReported'] != true;
                  }).toList();

                  if (posts.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(context),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final postDoc = posts[index];
                        final data = postDoc.data() as Map<String, dynamic>;

                        final likedBy = List<String>.from(
                          data['likedBy'] ?? [],
                        );
                        final isLiked = likedBy.contains(settings.userId);

                        final postNode = {
                          'id': postDoc.id,
                          'username': data['authorNickname'] ?? 'Unknown',
                          'authorEmail': data['authorEmail'] ?? '',
                          'time': _formatTimestamp(data['timestamp']),
                          'content': data['content'] ?? '',
                          'likes': data['likes'] ?? 0,
                          'comments': data['comments'] ?? 0,
                          'isLiked': isLiked,
                        };

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PostCard(
                            key: ValueKey(postNode['id']),
                            post: postNode,
                          ),
                        );
                      }, childCount: posts.length),
                    ),
                  );
                },
              );
            },
          ),
          const SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 32),
                AdBannerWidget(),
                SizedBox(height: 80), // To avoid overlapping with FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('New Post'),
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
  final int _textLimit = 200;
  final GlobalKey _menuKey = GlobalKey();

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

    if (settings.email.isEmpty ||
        settings.email == 'user@example.com' ||
        settings.district.isEmpty ||
        settings.position.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Profile Required'),
          content: const Text(
            'Complete your Profile Setup before participating in discussions!',
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
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: const Text('Setup Profile'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(postNode: widget.post),
    );
  }

  void _showReportDialog() {
    final settings = context.read<SettingsProvider>();
    final reasons = [
      'Spam',
      'Harassment',
      'False Information',
      'Inappropriate Content',
      'Hate Speech',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a reason for reporting this post:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...reasons.map(
              (reason) => ListTile(
                title: Text(reason),
                onTap: () async {
                  Navigator.pop(ctx);
                  await FirestoreService().reportPost(
                    postId: widget.post['id'],
                    reason: reason,
                    reportedBy: settings.email,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Post reported as "$reason".'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String content = widget.post['content'] ?? '';
    final bool isLongText = content.length > _textLimit;
    final String displayText = (_isExpanded || !isLongText)
        ? content
        : '${content.substring(0, _textLimit)}...';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.post['username'] == 'DEVELOPER'
                      ? Colors.amber.shade700
                      : ColorUtils.getAvatarColor(widget.post['username']),
                  radius: 22,
                  child: widget.post['username'] == 'DEVELOPER'
                      ? const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 24,
                        )
                      : Text(
                          widget.post['username'].isNotEmpty
                              ? widget.post['username'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post['username'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        widget.post['time'],
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  key: _menuKey,
                  icon: const Icon(Icons.more_horiz_rounded, size: 20),
                  onPressed: () {
                    final RenderBox button =
                        _menuKey.currentContext!.findRenderObject()
                            as RenderBox;
                    final RenderBox overlay =
                        Overlay.of(context).context.findRenderObject()
                            as RenderBox;
                    final RelativeRect position = RelativeRect.fromRect(
                      Rect.fromPoints(
                        button.localToGlobal(Offset.zero, ancestor: overlay),
                        button.localToGlobal(
                          button.size.bottomRight(Offset.zero),
                          ancestor: overlay,
                        ),
                      ),
                      Offset.zero & overlay.size,
                    );
                    showMenu<String>(
                      context: context,
                      position: position,
                      items: [
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Report Post',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.post['authorEmail'] == context.read<SettingsProvider>().email)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Edit Post',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ).then((value) {
                      if (!mounted) return;
                      if (value == 'report') {
                        _showReportDialog();
                      } else if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatePostScreen(
                              postToEdit: widget.post,
                            ),
                          ),
                        );
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (isLongText)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _isExpanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                _InteractionPill(
                  icon: _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  label: '$_likesCount',
                  isHighlighted: _isLiked,
                  highlightColor: Colors.redAccent,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 12),
                _InteractionPill(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${widget.post['comments']}',
                  onTap: () => _handleCommentAttempt(context),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  onPressed: () {
                    final text =
                        '${widget.post['username']} shared: "${widget.post['content']}"';
                    SharePlus.instance.share(ShareParams(text: text));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlighted;
  final Color? highlightColor;
  final VoidCallback onTap;

  const _InteractionPill({
    required this.icon,
    required this.label,
    this.isHighlighted = false,
    this.highlightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isHighlighted
        ? (highlightColor ?? colorScheme.primary)
        : colorScheme.onSurfaceVariant;

    return Material(
      color: isHighlighted ? color.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: isHighlighted
                  ? color.withValues(alpha: 0.2)
                  : colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

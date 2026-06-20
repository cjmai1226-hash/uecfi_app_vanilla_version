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
import 'menu/profile_screen.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/chatgpt_design_system.dart';
import '../utils/color_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenDrawer});

  final VoidCallback? onOpenDrawer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.forum_rounded,
                size: 64,
                color: isDark ? Colors.white : const Color(0xFF0F0F0F),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No posts yet!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to share something with the community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final containerBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08);

    final String initial = settings.nickname.isNotEmpty
        ? settings.nickname[0].toUpperCase()
        : 'U';
    final Color avatarBg = ColorUtils.getAvatarColor(settings.nickname);

    return GestureDetector(
      onTap: () => CreatePostScreen.show(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: settings.nickname == 'DEVELOPER'
                  ? Colors.amber.shade700
                  : avatarBg,
              child: settings.nickname == 'DEVELOPER'
                  ? const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Text(
                  settings.nickname.isNotEmpty
                      ? "What's on your mind, ${settings.nickname}?"
                      : "What's on your mind?",
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
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
      appBar: MainAppBar(
        title: 'Community Forum',
        onOpenDrawer: widget.onOpenDrawer,
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
          SliverToBoxAdapter(
            child: _buildComposer(context),
          ),
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
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
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
  late bool _isLiked;
  late int _likesCount;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String content = widget.post['content'] ?? '';

    final avatarBg = widget.post['username'] == 'DEVELOPER'
        ? Colors.amber.shade700
        : ColorUtils.getAvatarColor(widget.post['username']);
    final avatarFg = Colors.white;

    return ChatGPTCard(
      borderRadius: 16.0,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: avatarBg,
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
                        style: TextStyle(
                          color: avatarFg,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      widget.post['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.65,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: _menuKey,
                icon: const Icon(Icons.more_horiz_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF),
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                ),
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
                    if (!context.mounted) return;
                    if (value == 'report') {
                      _showReportDialog();
                    } else if (value == 'edit') {
                      CreatePostScreen.show(context, postToEdit: widget.post);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinkifiedText(
            text: content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w400,
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
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF),
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isHighlighted
        ? (highlightColor ?? (isDark ? Colors.white : Colors.black))
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final borderColor = isHighlighted
        ? color.withValues(alpha: 0.3)
        : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1));

    return Material(
      color: isHighlighted 
          ? color.withValues(alpha: 0.1) 
          : (isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFEFEF)).withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
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

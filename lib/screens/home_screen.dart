import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../providers/settings_provider.dart';
import '../services/ad_service.dart';
import 'comments_screen.dart';
import 'forms/create_post_screen.dart';
import 'menu/profile_screen.dart';
import 'search_screen.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/chatgpt_design_system.dart';
import '../utils/color_utils.dart';
import 'menu/bible_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenDrawer});

  final VoidCallback? onOpenDrawer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTipIndex = 0;

  static const String _bibleActionLabel = 'click here!';

  final List<String> _quickTips = [
    "Do you know the UECFI App now has an Ilocano Bible added to it? You can find it at the App Drawer or ",
    "Do you know that the UECFI App can help you learn to play a guitar and ukulele? Just activate it in the Settings, enable 'Show Chords & Shapes', and choose which chord instrument you want to play!",
    "Do you know you can submit your created songs in the UECFI App? Just go to the App Drawer and tap 'Submit Song'!",
    "Do you know you can contribute to your own local church by properly mapping it and adding a contact person to help other brothers and sisters in case of a spiritual mission? Just choose your local center and press Suggest Edit!",
  ];

  /// Parallel list: if non-null, the tip gets a tappable 'click here' label appended.
  late final List<VoidCallback?> _quickTipActions;

  @override
  void initState() {
    super.initState();
    _quickTipActions = [
      // Tip 0: Ilocano Bible — navigate to BibleScreen
      () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BibleScreen()),
          ),
      null, // Tip 1: no action
      null, // Tip 2: no action
      null, // Tip 3: no action
    ];
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekdays = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final weekday = weekdays[date.weekday % 7];
    final month = months[date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
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

  Widget _buildWelcomeHeader(BuildContext context, SettingsProvider settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String displayName = settings.nickname.isNotEmpty
        ? settings.nickname
        : 'User';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colorScheme.primary.withValues(alpha: 0.25),
                  colorScheme.primary.withValues(alpha: 0.05),
                ]
              : [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.church_rounded,
                color: isDark ? colorScheme.primary : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'UECFI APP',
                style: TextStyle(
                  color: isDark ? colorScheme.onSurface : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hello, $displayName! 👋',
            style: TextStyle(
              color: isDark ? colorScheme.onSurface : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(DateTime.now()),
            style: TextStyle(
              color: isDark
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChatGPTCard(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tips_and_updates_rounded,
                color: Colors.amber,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK TIP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: Builder(
                      key: ValueKey<int>(_currentTipIndex),
                      builder: (context) {
                        final tipText = _quickTips[_currentTipIndex];
                        final tipAction = _quickTipActions[_currentTipIndex];
                        final baseStyle = TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: colorScheme.onSurface,
                        );
                        if (tipAction == null) {
                          return Text(tipText, style: baseStyle);
                        }
                        return Text.rich(
                          TextSpan(
                            style: baseStyle,
                            children: [
                              TextSpan(text: tipText),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: tipAction,
                                  child: Text(
                                    _bibleActionLabel,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Dots Indicator
                      Row(
                        children: List.generate(_quickTips.length, (index) {
                          final isActive = index == _currentTipIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: isActive ? 16 : 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.3,
                                    ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      // Left Button
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _currentTipIndex =
                                (_currentTipIndex - 1 + _quickTips.length) %
                                _quickTips.length;
                          });
                        },
                      ),
                      // Right Button
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _currentTipIndex =
                                (_currentTipIndex + 1) % _quickTips.length;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

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
          // 1. Welcome Card Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            sliver: SliverToBoxAdapter(
              child: _buildWelcomeHeader(context, settings),
            ),
          ),

          // 2. Quick Tips Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(child: _buildQuickTips(context)),
          ),

          // 4. Community Feed Title
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _buildSectionHeader(context, 'Community Forum'),
            ),
          ),

          // 5. Community Posts Stream List
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirestoreService().getCommunityPostsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error loading feed: ${snapshot.error}'),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: _buildEmptyState(context),
                      ),
                    );
                  }

                  final posts = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['isReported'] != true;
                  }).toList();

                  if (posts.isEmpty) {
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: _buildEmptyState(context),
                      ),
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

          // 6. Ad Banner space
          const SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 24),
                AdBannerWidget(),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => CreatePostScreen.show(context),
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
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

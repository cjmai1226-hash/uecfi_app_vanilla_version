import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

/// A clean container card that adapts between dark and light themes
/// with a thin border and rounded corners.
class ChatGPTCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;

  const ChatGPTCard({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// A premium high-contrast tag or badge that adapts to the theme.
class ChatGPTTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double fontSize;

  const ChatGPTTag({
    super.key,
    required this.label,
    this.icon,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white : const Color(0xFF0F0F0F);
    final fgColor = isDark ? const Color(0xFF0F0F0F) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: fgColor),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: fgColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A text field that combines a label above and styled TextFormField.
class ChatGPTTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextStyle? style;

  const ChatGPTTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1);
    final focusedBorderColor = colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: labelColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: icon != null
                  ? Icon(icon, color: colorScheme.primary.withValues(alpha: 0.7), size: 20)
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: focusedBorderColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.error, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// A representation of HTML page metadata for link previews.
class LinkMetadata {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;

  const LinkMetadata({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });
}

/// An in-memory cache for fetched link metadata to prevent redundant requests.
class LinkMetadataCache {
  static final Map<String, LinkMetadata> _cache = {};
  static LinkMetadata? get(String url) => _cache[url];
  static void set(String url, LinkMetadata data) => _cache[url] = data;
}

/// Helper to decode standard HTML entities from scraping.
String? _decodeHtmlEntities(String? input) {
  if (input == null) return null;
  return input
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
}

/// Fetches link metadata asynchronously by requesting the target URL
/// and parsing Open Graph meta tags.
Future<LinkMetadata?> fetchLinkMetadata(String urlString) async {
  try {
    String cleanUrl = urlString;
    if (cleanUrl.toLowerCase().startsWith('www.')) {
      cleanUrl = 'https://$cleanUrl';
    }
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null) return null;

    final response = await http.get(uri).timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final body = response.body;
      return parseHtmlMetadata(cleanUrl, body);
    }
  } catch (e) {
    debugPrint('Error fetching metadata: $e');
  }
  return null;
}

/// Parses title, description, and image values from HTML meta tags.
LinkMetadata parseHtmlMetadata(String url, String htmlBody) {
  String? getMetaValue(String property) {
    final regex1 = RegExp(
      '<meta[^>]*property=["\']$property["\'][^>]*content=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final regex2 = RegExp(
      '<meta[^>]*content=["\']([^"\']*)["\'][^>]*property=["\']$property["\']',
      caseSensitive: false,
    );
    final regex3 = RegExp(
      '<meta[^>]*name=["\']$property["\'][^>]*content=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final regex4 = RegExp(
      '<meta[^>]*content=["\']([^"\']*)["\'][^>]*name=["\']$property["\']',
      caseSensitive: false,
    );

    final match = regex1.firstMatch(htmlBody) ?? 
                  regex2.firstMatch(htmlBody) ?? 
                  regex3.firstMatch(htmlBody) ?? 
                  regex4.firstMatch(htmlBody);

    return match?.group(1);
  }

  String? title = _decodeHtmlEntities(getMetaValue('og:title') ?? getMetaValue('twitter:title'));
  if (title == null) {
    final titleRegex = RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false);
    title = _decodeHtmlEntities(titleRegex.firstMatch(htmlBody)?.group(1)?.trim());
  }

  final description = _decodeHtmlEntities(getMetaValue('og:description') ?? 
                      getMetaValue('twitter:description') ?? 
                      getMetaValue('description'));

  final imageUrl = getMetaValue('og:image') ?? 
                   getMetaValue('twitter:image');

  return LinkMetadata(
    url: url,
    title: title,
    description: description,
    imageUrl: imageUrl,
  );
}

/// A monochromatic horizontal card that displays scraped URL metadata.
class LinkPreviewCard extends StatefulWidget {
  final String url;

  const LinkPreviewCard({super.key, required this.url});

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  LinkMetadata? _metadata;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void didUpdateWidget(covariant LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadMetadata();
    }
  }

  Future<void> _loadMetadata() async {
    final isDirectImage = RegExp(r'\.(jpg|jpeg|png|gif|webp)(\?.*)?$', caseSensitive: false).hasMatch(widget.url);
    if (isDirectImage) {
      if (mounted) {
        setState(() {
          _metadata = LinkMetadata(url: widget.url, imageUrl: widget.url);
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    final cached = LinkMetadataCache.get(widget.url);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _metadata = cached;
          _isLoading = false;
          _hasError = cached.title == null && cached.description == null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _metadata = null;
      });
    }

    final data = await fetchLinkMetadata(widget.url);
    if (!mounted) return;

    if (data != null && (data.title != null || data.description != null || data.imageUrl != null)) {
      LinkMetadataCache.set(widget.url, data);
      setState(() {
        _metadata = data;
        _isLoading = false;
      });
    } else {
      // Prevent spamming failing endpoints by caching an empty mock metadata
      final errorMeta = LinkMetadata(url: widget.url);
      LinkMetadataCache.set(widget.url, errorMeta);
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _launchUrl() async {
    String cleanUrl = widget.url;
    if (cleanUrl.toLowerCase().startsWith('www.')) {
      cleanUrl = 'https://$cleanUrl';
    }
    final Uri? uri = Uri.tryParse(cleanUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Error launching url: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final cardBg = isDark ? const Color(0xFF242424) : const Color(0xFFF2F2F2);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    final isDirectImage = RegExp(r'\.(jpg|jpeg|png|gif|webp)(\?.*)?$', caseSensitive: false).hasMatch(widget.url);
    if (isDirectImage) {
      String domain = widget.url;
      try {
        String temp = domain.replaceAll(RegExp(r'https?://'), '');
        if (temp.startsWith('www.')) temp = temp.substring(4);
        int slashIdx = temp.indexOf('/');
        if (slashIdx != -1) {
          domain = temp.substring(0, slashIdx);
        } else {
          domain = temp;
        }
      } catch (_) {}

      return Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.network(
                widget.url,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 160,
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9),
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.image_rounded,
                      size: 14,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        domain.toLowerCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      );
    }

    if (_isLoading) {
      // Skeleton loader matching design system
      return Container(
        margin: const EdgeInsets.only(top: 10),
        height: 86,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  bottomLeft: Radius.circular(11),
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 12,
                      width: 140,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 200,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final meta = _metadata;
    if (meta == null) return const SizedBox.shrink();

    String domain = widget.url;
    try {
      String temp = domain.replaceAll(RegExp(r'https?://'), '');
      if (temp.startsWith('www.')) temp = temp.substring(4);
      int slashIdx = temp.indexOf('/');
      if (slashIdx != -1) {
        domain = temp.substring(0, slashIdx);
      } else {
        domain = temp;
      }
    } catch (_) {}

    return GestureDetector(
      onTap: _launchUrl,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (meta.imageUrl != null && meta.imageUrl!.isNotEmpty)
                SizedBox(
                  width: 86,
                  child: Image.network(
                    meta.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        child: Icon(
                          Icons.link_rounded,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 86,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  child: Icon(
                    Icons.link_rounded,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        meta.title ?? 'Link Preview',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (meta.description != null && meta.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          meta.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                            height: 1.2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        domain.toLowerCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A stateful widget that automatically identifies links (starting with http://, https://, or www.)
/// in text, makes them clickable, launches them in the system browser, and shows rich link previews.
/// Properly manages the lifecycle of gesture recognizers to avoid memory leaks.
class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;

  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final defaultStyle = widget.style ?? TextStyle(
      fontSize: 15,
      color: colorScheme.onSurface,
    );

    // Matches http://, https://, or www. followed by non-whitespace characters
    final urlRegex = RegExp(r'(https?:\/\/[^\s]+|www\.[^\s]+)', caseSensitive: false);

    final List<InlineSpan> spans = [];
    final matches = urlRegex.allMatches(text);
    int lastMatchEnd = 0;
    String? firstUrl;

    for (final match in matches) {
      // Plain text before the matched URL
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      String urlText = match.group(0)!;
      String trailingPunctuation = '';

      // Separate trailing punctuation (e.g. dots, commas, exclamation marks, parentheses)
      // from the URL text.
      final punctuationRegExp = RegExp(r'[.,!?\)\}\]\;\\:]+$');
      final punctuationMatch = punctuationRegExp.firstMatch(urlText);
      if (punctuationMatch != null) {
        trailingPunctuation = punctuationMatch.group(0)!;
        urlText = urlText.substring(0, urlText.length - trailingPunctuation.length);
      }

      firstUrl ??= urlText;

      // Don't add the raw URL text to the spans — the preview card below handles it visually.
      // Trailing punctuation after a URL is also dropped since it would look odd standalone.

      lastMatchEnd = match.end;
    }

    // Remaining plain text after the last URL
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }

    // Only show the text widget if there is non-URL text to display
    final hasVisibleText = spans.isNotEmpty;

    if (firstUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasVisibleText)
            Text.rich(TextSpan(children: spans)),
          LinkPreviewCard(url: firstUrl),
        ],
      );
    }

    return Text.rich(TextSpan(children: spans));
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius = 16.0,
    this.padding,
    this.border,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ??
                (isDark
                    ? Colors.white.withValues(alpha: opacity)
                    : Colors.white.withValues(alpha: opacity + 0.1)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ChatGPTButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double height;

  const ChatGPTButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.height = 60,
  });

  @override
  State<ChatGPTButton> createState() => _ChatGPTButtonState();
}

class _ChatGPTButtonState extends State<ChatGPTButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;

    if (isDisabled) {
      backgroundColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08);
      foregroundColor = isDark ? Colors.white30 : Colors.black38;
    } else {
      backgroundColor = isDark ? Colors.white : const Color(0xFF0F0F0F);
      foregroundColor = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    }

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _controller.forward(),
      onTapUp: isDisabled ? null : (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: isDisabled ? null : () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foregroundColor,
                    ),
                  )
                : DefaultTextStyle(
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    child: IconTheme(
                      data: IconThemeData(color: foregroundColor),
                      child: widget.child,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}


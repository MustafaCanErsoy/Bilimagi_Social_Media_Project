import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

/// Markdown viewer widget for displaying formatted content (v8.0)
class MarkdownViewer extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final bool selectable;

  const MarkdownViewer({
    super.key,
    required this.text,
    this.baseStyle,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return Text(
        'Icerik yok',
        style: TextStyle(
          color: AppTheme.getTextTertiary(context),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final lines = text.split('\n');
    final widgets = <Widget>[];
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Code block
      if (line.startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        widgets.add(_buildCodeBlock(context, codeLines.join('\n')));
        i++;
        continue;
      }

      widgets.add(_buildLine(context, line));
      i++;
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );

    return selectable ? SelectionArea(child: content) : content;
  }

  Widget _buildLine(BuildContext context, String line) {
    final style = baseStyle ?? Theme.of(context).textTheme.bodyMedium;

    // Headers
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: _buildInlineText(
          context,
          line.substring(4),
          style?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: _buildInlineText(
          context,
          line.substring(3),
          style?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: _buildInlineText(
          context,
          line.substring(2),
          style?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Horizontal rule
    if (line == '---' || line == '***' || line == '___') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(color: Theme.of(context).dividerColor),
      );
    }

    // Quote
    if (line.startsWith('> ')) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppTheme.primaryColor,
              width: 3,
            ),
          ),
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
        ),
        child: _buildInlineText(
          context,
          line.substring(2),
          style?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    // Unordered list
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, top: 3, bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6, right: 8),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(child: _buildInlineText(context, line.substring(2), style)),
          ],
        ),
      );
    }

    // Numbered list
    final numberMatch = RegExp(r'^(\d+)\. ').firstMatch(line);
    if (numberMatch != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, top: 3, bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${numberMatch.group(1)}.',
                style: style?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            Expanded(
              child: _buildInlineText(
                context,
                line.substring(numberMatch.end),
                style,
              ),
            ),
          ],
        ),
      );
    }

    // Empty line
    if (line.isEmpty) {
      return const SizedBox(height: 12);
    }

    // Regular paragraph
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: _buildInlineText(context, line, style),
    );
  }

  Widget _buildCodeBlock(BuildContext context, String code) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green.shade300
                : Colors.green.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineText(BuildContext context, String text, TextStyle? style) {
    final spans = _parseInlineFormatting(context, text, style);

    return RichText(
      text: TextSpan(
        style: style ?? Theme.of(context).textTheme.bodyMedium,
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseInlineFormatting(
    BuildContext context,
    String text,
    TextStyle? baseStyle,
  ) {
    final spans = <InlineSpan>[];
    var remaining = text;

    while (remaining.isNotEmpty) {
      // Inline code
      final codeMatch = RegExp(r'`(.+?)`').firstMatch(remaining);
      // Bold
      final boldMatch = RegExp(r'\*\*(.+?)\*\*').firstMatch(remaining);
      // Italic
      final italicMatch = RegExp(r'(?<!\*)\*([^*]+?)\*(?!\*)').firstMatch(remaining);
      // Link
      final linkMatch = RegExp(r'\[(.+?)\]\((.+?)\)').firstMatch(remaining);

      // Find earliest match
      Match? firstMatch;
      String? type;

      final matches = [
        if (codeMatch != null) (match: codeMatch, type: 'code'),
        if (boldMatch != null) (match: boldMatch, type: 'bold'),
        if (italicMatch != null) (match: italicMatch, type: 'italic'),
        if (linkMatch != null) (match: linkMatch, type: 'link'),
      ];

      for (final m in matches) {
        if (firstMatch == null || m.match.start < firstMatch.start) {
          firstMatch = m.match;
          type = m.type;
        }
      }

      if (firstMatch == null) {
        spans.add(TextSpan(text: remaining));
        break;
      }

      // Add text before match
      if (firstMatch.start > 0) {
        spans.add(TextSpan(text: remaining.substring(0, firstMatch.start)));
      }

      // Add formatted text
      switch (type) {
        case 'code':
          spans.add(WidgetSpan(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                firstMatch.group(1)!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: (baseStyle?.fontSize ?? 14) - 1,
                  color: Colors.pink.shade700,
                ),
              ),
            ),
          ));
          break;
        case 'bold':
          spans.add(TextSpan(
            text: firstMatch.group(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ));
          break;
        case 'italic':
          spans.add(TextSpan(
            text: firstMatch.group(1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ));
          break;
        case 'link':
          final linkText = firstMatch.group(1)!;
          final linkUrl = firstMatch.group(2)!;
          spans.add(WidgetSpan(
            child: GestureDetector(
              onTap: () => _launchUrl(linkUrl),
              child: Text(
                linkText,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.primaryColor,
                ),
              ),
            ),
          ));
          break;
      }

      remaining = remaining.substring(firstMatch.end);
    }

    return spans;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

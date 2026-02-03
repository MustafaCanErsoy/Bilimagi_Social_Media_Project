import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Simple Markdown editor with formatting buttons (v8.0)
class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int? maxLines;
  final bool showPreview;
  final ValueChanged<String>? onChanged;

  const MarkdownEditor({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines,
    this.showPreview = true,
    this.onChanged,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (selection.isCollapsed) {
      // No selection, insert at cursor
      final newText = text.substring(0, selection.start) +
          prefix +
          suffix +
          text.substring(selection.start);
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    } else {
      // Wrap selection
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: selection.end + prefix.length + suffix.length,
      );
    }

    widget.onChanged?.call(widget.controller.text);
  }

  void _insertAtLineStart(String prefix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    // Find start of current line
    int lineStart = selection.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    final newText = text.substring(0, lineStart) +
        prefix +
        text.substring(lineStart);
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: selection.start + prefix.length,
    );

    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formatting toolbar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              // Formatting buttons
              _ToolbarButton(
                icon: Icons.format_bold,
                tooltip: 'Kalin',
                onPressed: () => _insertMarkdown('**', '**'),
              ),
              _ToolbarButton(
                icon: Icons.format_italic,
                tooltip: 'Italik',
                onPressed: () => _insertMarkdown('*', '*'),
              ),
              _ToolbarButton(
                icon: Icons.link,
                tooltip: 'Link',
                onPressed: () => _showLinkDialog(),
              ),
              _ToolbarButton(
                icon: Icons.format_list_bulleted,
                tooltip: 'Liste',
                onPressed: () => _insertAtLineStart('- '),
              ),
              _ToolbarButton(
                icon: Icons.format_list_numbered,
                tooltip: 'Numarali Liste',
                onPressed: () => _insertAtLineStart('1. '),
              ),
              _ToolbarButton(
                icon: Icons.title,
                tooltip: 'Baslik',
                onPressed: () => _insertAtLineStart('## '),
              ),
              _ToolbarButton(
                icon: Icons.format_quote,
                tooltip: 'Alinti',
                onPressed: () => _insertAtLineStart('> '),
              ),
              const Spacer(),
              // Preview toggle
              if (widget.showPreview) ...[
                const VerticalDivider(width: 1),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Duzenle'),
                    Tab(text: 'Onizleme'),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Editor / Preview
        Expanded(
          child: widget.showPreview
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEditor(),
                    _buildPreview(),
                  ],
                )
              : _buildEditor(),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: TextField(
        controller: widget.controller,
        maxLines: widget.maxLines,
        expands: widget.maxLines == null,
        textAlignVertical: TextAlignVertical.top,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Markdown formatinda yazin...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: MarkdownPreview(text: widget.controller.text),
      ),
    );
  }

  Future<void> _showLinkDialog() async {
    final urlController = TextEditingController();
    final textController = TextEditingController();

    // Check if there's selected text
    final selection = widget.controller.selection;
    if (!selection.isCollapsed) {
      textController.text = selection.textInside(widget.controller.text);
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Link metni',
                hintText: 'Ornek: Buraya tiklayin',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'text': textController.text,
              'url': urlController.text,
            }),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (result != null && result['url']!.isNotEmpty) {
      final text = result['text']!.isEmpty ? result['url']! : result['text']!;
      _insertMarkdown('[', ']($text${result['url']})');
    }
  }
}

/// Toolbar button widget
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 18,
    );
  }
}

/// Simple markdown preview (basic rendering)
class MarkdownPreview extends StatelessWidget {
  final String text;

  const MarkdownPreview({super.key, required this.text});

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

    for (final line in lines) {
      widgets.add(_buildLine(context, line));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildLine(BuildContext context, String line) {
    // Headers
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          line.substring(4),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          line.substring(3),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          line.substring(2),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    // Quote
    if (line.startsWith('> ')) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppTheme.primaryColor,
              width: 3,
            ),
          ),
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
        child: _buildInlineFormatting(context, line.substring(2)),
      );
    }

    // List items
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(child: _buildInlineFormatting(context, line.substring(2))),
          ],
        ),
      );
    }

    // Numbered list
    final numberMatch = RegExp(r'^(\d+)\. ').firstMatch(line);
    if (numberMatch != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${numberMatch.group(1)}. '),
            Expanded(
                child: _buildInlineFormatting(
                    context, line.substring(numberMatch.end))),
          ],
        ),
      );
    }

    // Empty line
    if (line.isEmpty) {
      return const SizedBox(height: 8);
    }

    // Regular paragraph
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _buildInlineFormatting(context, line),
    );
  }

  Widget _buildInlineFormatting(BuildContext context, String text) {
    // Simple implementation - just handle bold and italic
    final spans = <TextSpan>[];
    var remaining = text;

    while (remaining.isNotEmpty) {
      // Bold
      final boldMatch = RegExp(r'\*\*(.+?)\*\*').firstMatch(remaining);
      // Italic
      final italicMatch = RegExp(r'\*(.+?)\*').firstMatch(remaining);
      // Link
      final linkMatch = RegExp(r'\[(.+?)\]\((.+?)\)').firstMatch(remaining);

      Match? firstMatch;
      String? type;

      if (boldMatch != null) {
        firstMatch = boldMatch;
        type = 'bold';
      }
      if (italicMatch != null &&
          (firstMatch == null || italicMatch.start < firstMatch.start)) {
        // Make sure it's not part of bold
        if (boldMatch == null || italicMatch.start != boldMatch.start) {
          firstMatch = italicMatch;
          type = 'italic';
        }
      }
      if (linkMatch != null &&
          (firstMatch == null || linkMatch.start < firstMatch.start)) {
        firstMatch = linkMatch;
        type = 'link';
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
          spans.add(TextSpan(
            text: firstMatch.group(1),
            style: TextStyle(
              color: AppTheme.primaryColor,
              decoration: TextDecoration.underline,
            ),
          ));
          break;
      }

      remaining = remaining.substring(firstMatch.end);
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: spans,
      ),
    );
  }
}

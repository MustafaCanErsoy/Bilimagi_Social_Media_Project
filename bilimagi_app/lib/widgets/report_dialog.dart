import 'package:flutter/material.dart';
import '../models/report.dart';
import '../core/theme.dart';

/// Dialog for reporting content
class ReportDialog extends StatefulWidget {
  final String title;
  final String targetName;

  const ReportDialog({
    super.key,
    required this.title,
    required this.targetName,
  });

  /// Returns a map with 'reason' and optional 'details' if submitted, null if cancelled
  static Future<Map<String, String>?> show(
    BuildContext context, {
    required String title,
    required String targetName,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => ReportDialog(
        title: title,
        targetName: targetName,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Raporlanan: ${widget.targetName}',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sebep seçin:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            ...ReportReason.all.map((reason) => RadioListTile<String>(
                  title: Text(ReportReason.getLabel(reason)),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              decoration: InputDecoration(
                labelText: 'Ek detaylar (opsiyonel)',
                hintText: 'Daha fazla bilgi ekleyin...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  Navigator.pop(context, {
                    'reason': _selectedReason!,
                    if (_detailsController.text.trim().isNotEmpty)
                      'details': _detailsController.text.trim(),
                  });
                },
          child: const Text('Raporla'),
        ),
      ],
    );
  }
}

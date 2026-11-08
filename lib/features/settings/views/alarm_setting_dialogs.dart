import 'package:flutter/material.dart';

Future<int?> requestCustomRadius(BuildContext context, int current) async {
  final controller = TextEditingController(text: '$current');
  final radius = await showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Custom trigger radius'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Distance',
          suffixText: 'meters',
          helperText: 'Enter a value from 50 to 5,000 m.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value != null && value >= 50 && value <= 5000) {
              Navigator.pop(dialogContext, value);
            }
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
  controller.dispose();
  return radius;
}

Future<double?> requestWarningDistance(
  BuildContext context,
  double current,
) async {
  var value = current.clamp(.5, 5).toDouble();
  return showDialog<double>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('First warning distance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${value.toStringAsFixed(1)} km'),
            Slider(
              value: value,
              min: .5,
              max: 5,
              divisions: 9,
              onChanged: (next) => setDialogState(() => value = next),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, value),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

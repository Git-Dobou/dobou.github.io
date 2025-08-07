import 'package:flutter/material.dart';

class AdvancedLabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  final EdgeInsets padding;
  final bool showDivider;
  final Color? color;

  const AdvancedLabelValueRow({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (value == null || value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, 
            child: Text(label, 
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(color:  color ?? colorScheme.onSurface , fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

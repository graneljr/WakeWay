import 'package:flutter/material.dart';

import '../../core/theme/wake_colors.dart';
import 'icon_tile.dart';

class LabeledIconRow extends StatelessWidget {
  const LabeledIconRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.color = WakeColors.blue,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        IconTile(
          icon: icon,
          color: color,
          background: color.withValues(alpha: .09),
          size: 44,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: WakeColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: WakeColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
    return onTap == null
        ? row
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: row,
          );
  }
}

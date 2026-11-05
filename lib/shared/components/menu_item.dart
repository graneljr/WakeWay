import 'package:flutter/material.dart';
import 'package:wakeway/ui.dart';

class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 3),
    leading: Icon(icon, color: WakeColors.blue, size: 22),
    title: Text(
      title,
      style: const TextStyle(
        color: WakeColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: WakeColors.muted, fontSize: 11),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: WakeColors.muted),
    onTap: onTap,
  );
}
import 'package:flutter/material.dart';
import 'package:wakeway/shared/components/menu_item.dart';
import 'package:wakeway/shared/ui.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.onSaved,
    required this.onOfflineMaps,
    required this.onSettings,
    required this.onGpsStatus,
    required this.onHistory,
  });

  final VoidCallback onSaved;
  final VoidCallback onOfflineMaps;
  final VoidCallback onSettings;
  final VoidCallback onGpsStatus;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            'More',
            subtitle: 'Everything for a smoother ride.',
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: WakeColors.blueSoft,
                  child: Icon(Icons.person_rounded, color: WakeColors.blue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arman',
                        style: TextStyle(
                          color: WakeColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your commute, made restful.',
                        style: TextStyle(color: WakeColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: WakeColors.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Your WakeWay'),
          const SizedBox(height: 9),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            child: Column(
              children: [
                MenuItem(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'Saved destinations',
                  subtitle: 'Home, work, and favorite places',
                  onTap: onSaved,
                ),
                const Divider(height: 1, color: WakeColors.line),
                MenuItem(
                  icon: Icons.map_outlined,
                  title: 'Offline maps',
                  subtitle: 'Manage downloaded areas',
                  onTap: onOfflineMaps,
                ),
                const Divider(height: 1, color: WakeColors.line),
                MenuItem(
                  icon: Icons.history_rounded,
                  title: 'Trip history',
                  subtitle: 'See your recent rides',
                  onTap: onHistory,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('App & device'),
          const SizedBox(height: 9),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            child: Column(
              children: [
                MenuItem(
                  icon: Icons.tune_rounded,
                  title: 'Alarm settings',
                  subtitle: 'Sound, radius, and snooze',
                  onTap: onSettings,
                ),
                const Divider(height: 1, color: WakeColors.line),
                MenuItem(
                  icon: Icons.shield_outlined,
                  title: 'GPS & permissions',
                  subtitle: 'Location and background access',
                  onTap: onGpsStatus,
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          Center(
            child: Column(
              children: [
                const BrandMark(size: 34),
                const SizedBox(height: 8),
                const Text(
                  'WakeWay  ·  Version 1.0.0',
                  style: TextStyle(color: WakeColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

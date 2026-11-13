import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wakeway/core/storage/preferences_service.dart';
import 'package:wakeway/shared/components/menu_item.dart';
import 'package:wakeway/shared/ui.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({
    super.key,
    required this.onSaved,
    required this.onOfflineMaps,
    required this.onSettings,
    required this.onGpsStatus,
    required this.onHistory,
    required this.onSync,
    required this.onCheckForUpdates,
    required this.isCheckingForUpdates,
  });

  final VoidCallback onSaved;
  final VoidCallback onOfflineMaps;
  final VoidCallback onSettings;
  final VoidCallback onGpsStatus;
  final VoidCallback onHistory;
  final Future<void> Function() onSync;
  final VoidCallback onCheckForUpdates;
  final bool isCheckingForUpdates;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String? _userName;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final savedName = await PreferencesService.getUserName();
    final name = savedName?.trim();
    if (!mounted) return;

    setState(() {
      _userName = name?.isNotEmpty == true ? name : null;
    });
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await widget.onSync();
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName ?? 'Unknown User',
                        style: const TextStyle(
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
                  onTap: widget.onSaved,
                ),
                const Divider(height: 1, color: WakeColors.line),
                MenuItem(
                  icon: Icons.map_outlined,
                  title: 'Offline maps',
                  subtitle: 'Manage downloaded areas',
                  onTap: widget.onOfflineMaps,
                ),
                const Divider(height: 1, color: WakeColors.line),
                MenuItem(
                  icon: Icons.history_rounded,
                  title: 'Trip history',
                  subtitle: 'See your recent rides',
                  onTap: widget.onHistory,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('Data & backup'),
          const SizedBox(height: 9),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.cloud_sync_rounded,
                      color: WakeColors.blue,
                      size: 23,
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep your data backed up',
                            style: TextStyle(
                              color: WakeColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Sync saved places and trip history across devices.',
                            style: TextStyle(
                              color: WakeColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSyncing ? null : _syncData,
                    icon: _isSyncing
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(_isSyncing ? 'Syncing…' : 'Sync now'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('App updates'),
          const SizedBox(height: 9),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.system_update_alt_rounded,
                      color: WakeColors.blue,
                      size: 23,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Keep WakeWay up to date',
                            style: TextStyle(
                              color: WakeColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            Platform.isAndroid
                                ? 'Check GitHub Releases for the latest Android version.'
                                : 'Install WakeWay updates through the iOS App Store.',
                            style: const TextStyle(
                              color: WakeColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (Platform.isAndroid) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.isCheckingForUpdates
                          ? null
                          : widget.onCheckForUpdates,
                      icon: widget.isCheckingForUpdates
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.system_update_alt_rounded),
                      label: Text(
                        widget.isCheckingForUpdates
                            ? 'Checking for updates…'
                            : 'Check for updates',
                      ),
                    ),
                  ),
                ],
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
                  onTap: widget.onSettings,
                ),
                const Divider(height: 1, color: WakeColors.line),
                MenuItem(
                  icon: Icons.shield_outlined,
                  title: 'GPS & permissions',
                  subtitle: 'Location and background access',
                  onTap: widget.onGpsStatus,
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
                  'WakeWay  ·  App updates',
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

import 'package:flutter/material.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';

enum AlarmSoundChoice { wakeWayTone, classicTone, systemRingtone, deviceMusic }

Future<void> showAlarmSoundPicker(
  BuildContext context,
  WakeWayViewModel controller,
  ValueChanged<String> onSelected,
) async {
  final choice = await showModalBottomSheet<AlarmSoundChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.music_note_rounded),
            title: const Text('WakeWay alarm'),
            onTap: () => Navigator.pop(context, AlarmSoundChoice.wakeWayTone),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Classic alarm'),
            onTap: () => Navigator.pop(context, AlarmSoundChoice.classicTone),
          ),
          ListTile(
            leading: const Icon(Icons.ring_volume_rounded),
            title: const Text('Choose a device ringtone'),
            onTap: () =>
                Navigator.pop(context, AlarmSoundChoice.systemRingtone),
          ),
          ListTile(
            leading: const Icon(Icons.library_music_rounded),
            title: const Text('Choose music from this device'),
            onTap: () => Navigator.pop(context, AlarmSoundChoice.deviceMusic),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null) return;

  try {
    String? selectedName;
    switch (choice) {
      case AlarmSoundChoice.wakeWayTone:
        selectedName = 'WakeWay alarm';
        await controller.setAlarmSound(selectedName);
      case AlarmSoundChoice.classicTone:
        selectedName = 'Classic alarm';
        await controller.setAlarmSound(selectedName);
      case AlarmSoundChoice.systemRingtone:
        selectedName = await controller.pickSystemRingtone();
      case AlarmSoundChoice.deviceMusic:
        selectedName = await controller.pickDeviceMusic();
    }
    if (selectedName != null) onSelected(selectedName);
  } on Object catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not select alarm audio: $error')),
    );
  }
}

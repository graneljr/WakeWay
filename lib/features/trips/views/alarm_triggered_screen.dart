import 'package:flutter/material.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';

class AlarmTriggeredScreen extends StatefulWidget {
  const AlarmTriggeredScreen({
    super.key,
    required this.destination,
    required this.controller,
    required this.onStop,
    required this.onSnooze,
  });
  final String destination;
  final WakeWayViewModel controller;
  final VoidCallback onStop;
  final VoidCallback onSnooze;

  @override
  State<AlarmTriggeredScreen> createState() => _AlarmTriggeredScreenState();
}

class _AlarmTriggeredScreenState extends State<AlarmTriggeredScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: .91,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFFFF5F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 27),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, color: WakeColors.red, size: 10),
                  const SizedBox(width: 7),
                  const Text(
                    'WAKEWAY ALARM',
                    style: TextStyle(
                      color: WakeColors.red,
                      letterSpacing: 1.4,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onStop,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: WakeColors.ink,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 144,
                  height: 144,
                  decoration: const BoxDecoration(
                    color: WakeColors.redSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.notifications_active_rounded,
                      size: 69,
                      color: WakeColors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 31),
              const Text(
                'You’re close to\nyour destination!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WakeColors.ink,
                  fontSize: 31,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Wake up and get ready to get off.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WakeColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: WakeColors.green,
                      size: 19,
                    ),
                    SizedBox(width: 7),
                    Text(
                      widget.destination,
                      style: const TextStyle(
                        color: WakeColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      widget.controller.formatDistance(
                        widget.controller.distanceToAlarmMeters,
                      ),
                      style: TextStyle(
                        color: WakeColors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Stop alarm',
                icon: Icons.stop_circle_outlined,
                color: WakeColors.red,
                onPressed: widget.onStop,
                height: 60,
              ),
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: widget.onSnooze,
                  icon: const Icon(Icons.snooze_rounded),
                  label: Text(
                    'Snooze · ${widget.controller.snoozeMinutes} min',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WakeColors.ink,
                    side: const BorderSide(color: Color(0xFFE8D9D7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please mind your belongings as you get off.',
                style: TextStyle(color: WakeColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

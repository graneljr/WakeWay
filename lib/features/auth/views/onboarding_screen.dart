import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wakeway/core/storage/preferences_service.dart';
import 'package:wakeway/features/auth/viewmodels/authentication_view_model.dart';
import 'package:wakeway/features/auth/views/login.dart';
import 'package:wakeway/features/auth/views/register.dart';
import 'package:wakeway/shared/ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 4;

  final PageController _pageController = PageController();
  int _pageIndex = 0;
  bool _isFinishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _advance() {
    if (_pageIndex == _pageCount - 1) {
      _finish();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish({bool openLogin = false}) async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    await PreferencesService.completeOnboarding();
    if (!mounted) return;

    final nextScreen = LoginScreen(controller: AuthenticationViewModel());
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => nextScreen));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WakeColors.canvas,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final heroHeight = math
              .min(338.0, math.max(265.0, constraints.maxHeight * .42))
              .toDouble();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 508),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 15),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pageCount,
                        onPageChanged: (index) =>
                            setState(() => _pageIndex = index),
                        itemBuilder: (context, index) => SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _OnboardingPage(
                            index: index,
                            heroHeight: heroHeight,
                          ),
                        ),
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _buildHeader() => Row(
    children: [
      const BrandMark(size: 42),
      const SizedBox(width: 11),
      const Expanded(
        child: Text(
          'WakeWay',
          style: TextStyle(
            color: WakeColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
      ),
      TextButton(
        onPressed: _isFinishing ? null : () => _finish(),
        style: TextButton.styleFrom(
          foregroundColor: WakeColors.muted,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: const Text('Skip'),
      ),
    ],
  );

  Widget _buildFooter() {
    final hasProgress = _pageIndex > 0;
    final hasLoginLink = _pageIndex == 0 || _pageIndex == _pageCount - 1;
    final buttonLabel = switch (_pageIndex) {
      0 || 3 => 'Get started',
      _ => 'Next',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasProgress) ...[
          _PageProgress(currentStep: _pageIndex),
          const SizedBox(height: 17),
        ],
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton(
            onPressed: _isFinishing ? null : _advance,
            style: FilledButton.styleFrom(
              backgroundColor: WakeColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(buttonLabel),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
          ),
        ),
        if (hasLoginLink) ...[
          const SizedBox(height: 19),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: WakeColors.muted, fontSize: 13),
              ),
              TextButton(
                onPressed: _isFinishing ? null : () => _finish(openLogin: true),
                style: TextButton.styleFrom(
                  foregroundColor: WakeColors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Log in'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.index, required this.heroHeight});

  final int index;
  final double heroHeight;

  static const _eyebrows = [
    'YOUR COMMUTE, AT EASE',
    'STEP 1 OF 3',
    'STEP 2 OF 3',
    'STEP 3 OF 3',
  ];

  static const _titles = [
    'Sleep through the ride.\nWake at the right time.',
    'Choose your usual\ndestination.',
    'Set your wake-up\npoint on the route.',
    "Start your trip.\nWe'll watch your stop.",
  ];

  static const _descriptions = [
    'Set your stop and let WakeWay watch the route.\nWe’ll alert you as you get close.',
    'Search for a place or pick it on the map.\nSave your regular stop for next time.',
    'Choose where WakeWay should alert you,\njust before you reach your destination.',
    'Start monitoring when you board. WakeWay\nwill alert you as you get close.',
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _OnboardingArtwork(index: index, height: heroHeight),
      const SizedBox(height: 29),
      Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          _eyebrows[index],
          style: const TextStyle(
            color: WakeColors.blue,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      const SizedBox(height: 13),
      if (index == 0)
        RichText(
          text: const TextSpan(
            style: TextStyle(
              color: WakeColors.ink,
              fontSize: 31,
              height: 1.22,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
            children: [
              TextSpan(text: 'Sleep through the ride.\nWake at the '),
              TextSpan(
                text: 'right time.',
                style: TextStyle(color: WakeColors.blue),
              ),
            ],
          ),
        )
      else
        Text(
          _titles[index],
          style: const TextStyle(
            color: WakeColors.ink,
            fontSize: 31,
            height: 1.22,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
      const SizedBox(height: 12),
      Text(
        _descriptions[index],
        style: const TextStyle(
          color: WakeColors.muted,
          fontSize: 14,
          height: 1.55,
        ),
      ),
    ],
  );
}

class _OnboardingArtwork extends StatelessWidget {
  const _OnboardingArtwork({required this.index, required this.height});

  final int index;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: switch (index) {
      0 => const _WelcomeArtwork(),
      1 => const _DestinationArtwork(),
      2 => _WakePointArtwork(height: height),
      _ => _TripMonitoringArtwork(height: height),
    },
  );
}

class _WelcomeArtwork extends StatelessWidget {
  const _WelcomeArtwork();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _NightRoadPainter()),
        Positioned(
          left: 16,
          top: 18,
          child: _ArtworkChip(
            icon: Icons.nightlight_round,
            label: 'A CALMER COMMUTE',
            iconColor: const Color(0xFFE1AC39),
            background: Colors.white.withValues(alpha: .96),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 10,
          child: _ArtworkInfoCard(
            icon: Icons.notifications_active_rounded,
            eyebrow: 'WAKEWAY ALARM',
            label: 'Ready near your stop',
            width: 252,
            iconColor: const Color(0xFFD9A62F),
            iconBackground: const Color(0xFFFFF4D5),
          ),
        ),
      ],
    ),
  );
}

class _DestinationArtwork extends StatelessWidget {
  const _DestinationArtwork();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: IllustratedMapPainter(
            alarmPoint: const Offset(.80, .20),
            activeTrip: false,
          ),
        ),
        Positioned(
          left: 16,
          top: 18,
          child: _ArtworkChip(
            icon: Icons.place_rounded,
            label: 'CHOOSE A PLACE',
            iconColor: WakeColors.blue,
          ),
        ),
        Positioned(
          left: 20,
          bottom: 10,
          child: _ArtworkInfoCard(
            icon: Icons.location_on_rounded,
            eyebrow: 'YOUR DESTINATION',
            label: 'Pick it on the map',
            width: 236,
            iconColor: WakeColors.blue,
            iconBackground: WakeColors.blueSoft,
          ),
        ),
      ],
    ),
  );
}

class _WakePointArtwork extends StatelessWidget {
  const _WakePointArtwork({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: LayoutBuilder(
      builder: (context, _) {
        final cardHeight = (height * .54).clamp(136.0, 182.0).toDouble();
        return Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: WakeColors.blueSoft)),
            const Positioned(
              right: -36,
              top: -45,
              child: _SoftCircle(size: 128, color: Color(0xFFDDE9FA)),
            ),
            const Positioned(
              left: -38,
              bottom: -42,
              child: _SoftCircle(size: 144, color: Color(0xFFDCE8F8)),
            ),
            Positioned(
              left: 18,
              top: 17,
              child: _ArtworkChip(
                icon: Icons.notifications_active_rounded,
                label: 'WAKE POINT SETUP',
                iconColor: WakeColors.red,
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              top: 64,
              height: cardHeight,
              child: _RouteChoiceCard(compact: cardHeight < 158),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 14,
              height: 56,
              child: _DarkInfoCard(
                icon: Icons.tune_rounded,
                eyebrow: 'PERSONALIZE YOUR ALERT',
                label: 'Wake a little before your stop',
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _RouteChoiceCard extends StatelessWidget {
  const _RouteChoiceCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(15, compact ? 10 : 13, 15, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 23,
              width: 23,
              decoration: const BoxDecoration(
                color: WakeColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: WakeColors.blue,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'YOUR SAVED ROUTE',
              style: TextStyle(
                color: WakeColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
              ),
            ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 7),
          const Text(
            'Choose a point before your destination',
            style: TextStyle(color: WakeColors.muted, fontSize: 10),
          ),
        ],
        const SizedBox(height: 3),
        const Expanded(child: _RouteTimeline()),
        if (!compact) ...[
          const Divider(height: 1, color: WakeColors.line),
          const SizedBox(height: 6),
          const Text(
            'Move the marker to choose where to wake.',
            style: TextStyle(color: WakeColors.muted, fontSize: 9),
          ),
        ],
      ],
    ),
  );
}

class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final center = constraints.maxWidth / 2;
      return SizedBox(
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 7,
              right: 7,
              top: 16,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE4EB),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              left: 7,
              right: center,
              top: 16,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: WakeColors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 10,
              child: _TimelineDot(color: WakeColors.blue),
            ),
            Positioned(
              left: center - 11,
              top: 5,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: WakeColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: WakeColors.red.withValues(alpha: .17),
                      blurRadius: 0,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 10,
              child: _TimelineDot(color: WakeColors.green),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TimelineLabel('START'),
                  _TimelineLabel('WAKE POINT', color: WakeColors.red),
                  _TimelineLabel('YOUR STOP'),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    padding: const EdgeInsets.all(5),
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

class _TimelineLabel extends StatelessWidget {
  const _TimelineLabel(this.label, {this.color = WakeColors.muted});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: color,
      fontSize: 8,
      fontWeight: FontWeight.w700,
      letterSpacing: .3,
    ),
  );
}

class _TripMonitoringArtwork extends StatelessWidget {
  const _TripMonitoringArtwork({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final phoneHeight = math.min(245.0, height * .73).toDouble();
        final phoneWidth = math
            .min(200.0, constraints.maxWidth * .6)
            .toDouble();
        return Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: WakeColors.greenSoft),
            ),
            const Positioned(
              right: -33,
              top: -42,
              child: _SoftCircle(size: 136, color: Color(0xFFD8EDE2)),
            ),
            const Positioned(
              left: -35,
              top: 175,
              child: _SoftCircle(size: 106, color: Color(0xFFDDEFE5)),
            ),
            Positioned(
              left: 18,
              top: 16,
              child: _ArtworkChip(
                icon: Icons.gps_fixed_rounded,
                label: 'TRIP MONITORING',
                iconColor: WakeColors.green,
                iconBackground: WakeColors.greenSoft,
              ),
            ),
            Positioned(
              top: 38,
              left: (constraints.maxWidth - phoneWidth) / 2,
              width: phoneWidth,
              height: phoneHeight,
              child: _TripPhone(height: phoneHeight),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              height: 72,
              child: _AlertPreview(),
            ),
          ],
        );
      },
    ),
  );
}

class _TripPhone extends StatelessWidget {
  const _TripPhone({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final ringSize = math.min(94.0, height * .39).toDouble();
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: WakeColors.navy,
        borderRadius: BorderRadius.circular(29),
        boxShadow: [
          BoxShadow(
            color: WakeColors.navy.withValues(alpha: .15),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'WAKEWAY TRIP',
                    style: TextStyle(
                      color: WakeColors.ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: WakeColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                color: WakeColors.blueSoft,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD5E3F2), width: 5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: ringSize - 6,
                    height: ringSize - 6,
                    child: CircularProgressIndicator(
                      value: .32,
                      strokeWidth: 4,
                      backgroundColor: Colors.transparent,
                      color: WakeColors.blue,
                    ),
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    color: WakeColors.blue,
                    size: 25,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'On your way',
              style: TextStyle(
                color: WakeColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Your alarm is ready',
              style: TextStyle(color: WakeColors.muted, fontSize: 8),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: .56,
                minHeight: 6,
                backgroundColor: WakeColors.line,
                color: WakeColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: WakeColors.navy.withValues(alpha: .08),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: WakeColors.redSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: WakeColors.red,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WAKEWAY ALERT',
                style: TextStyle(
                  color: WakeColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "You're getting close to your stop",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: WakeColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ArtworkChip extends StatelessWidget {
  const _ArtworkChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.iconBackground = WakeColors.blueSoft,
    this.background = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBackground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 12),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: WakeColors.ink,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .35,
          ),
        ),
      ],
    ),
  );
}

class _ArtworkInfoCard extends StatelessWidget {
  const _ArtworkInfoCard({
    required this.icon,
    required this.eyebrow,
    required this.label,
    required this.width,
    required this.iconColor,
    required this.iconBackground,
  });

  final IconData icon;
  final String eyebrow;
  final String label;
  final double width;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 54,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .96),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WakeColors.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WakeColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DarkInfoCard extends StatelessWidget {
  const _DarkInfoCard({
    required this.icon,
    required this.eyebrow,
    required this.label,
  });

  final IconData icon;
  final String eyebrow;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: WakeColors.navy,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFFD773), size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB9C9D7),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _PageProgress extends StatelessWidget {
  const _PageProgress({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(3, (index) {
      final isActive = currentStep == index + 1;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 14 : 7,
        height: 7,
        decoration: BoxDecoration(
          color: isActive ? WakeColors.blue : const Color(0xFFC8D3DD),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }),
  );
}

class _NightRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = WakeColors.navy);

    canvas.drawCircle(
      Offset(w * .81, h * .23),
      w * .15,
      Paint()..color = WakeColors.blue.withValues(alpha: .14),
    );
    canvas.drawCircle(
      Offset(w * .81, h * .23),
      w * .092,
      Paint()..color = const Color(0xFFFFD773),
    );
    canvas.drawCircle(
      Offset(w * .85, h * .19),
      w * .084,
      Paint()..color = WakeColors.navy,
    );

    final starPaint = Paint()..color = Colors.white.withValues(alpha: .82);
    for (final star in <Offset>[
      Offset(w * .17, h * .15),
      Offset(w * .34, h * .27),
      Offset(w * .63, h * .11),
      Offset(w * .92, h * .39),
    ]) {
      canvas.drawCircle(star, 1.5, starPaint);
    }

    final farHill = Path()
      ..moveTo(0, h * .63)
      ..cubicTo(w * .20, h * .49, w * .32, h * .64, w * .47, h * .68)
      ..cubicTo(w * .63, h * .72, w * .76, h * .55, w, h * .45)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(farHill, Paint()..color = const Color(0xFF173A5B));

    final nearHill = Path()
      ..moveTo(0, h * .74)
      ..cubicTo(w * .20, h * .62, w * .32, h * .72, w * .47, h * .80)
      ..cubicTo(w * .63, h * .90, w * .78, h * .67, w, h * .59)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(nearHill, Paint()..color = const Color(0xFF1B4669));

    final road = Path()
      ..moveTo(w * .03, h * .93)
      ..cubicTo(w * .27, h * .75, w * .34, h * .85, w * .48, h * .82)
      ..cubicTo(w * .64, h * .77, w * .69, h * .64, w * .96, h * .55);
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFF6D8499)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .105
        ..strokeCap = StrokeCap.round,
    );
    final centerLine = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final metric in road.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 21) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            math.min(distance + 9, metric.length).toDouble(),
          ),
          centerLine,
        );
      }
    }

    canvas.drawCircle(
      Offset(w * .14, h * .85),
      w * .035,
      Paint()..color = WakeColors.blue,
    );
    canvas.drawCircle(
      Offset(w * .14, h * .85),
      w * .035,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(w * .89, h * .60),
      w * .045,
      Paint()..color = WakeColors.red,
    );
    canvas.drawCircle(
      Offset(w * .89, h * .60),
      w * .045,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

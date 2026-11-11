import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakeway/features/auth/viewmodels/authentication_view_model.dart';
import 'package:wakeway/features/auth/views/register.dart';
import 'package:wakeway/features/navigation/views/home_shell.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.controller});

  final WakeWayViewModel controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _timer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 1850), _checkSession);
  }

  Future<void> _checkSession() async {
    if (!mounted || _isNavigating) return;

    _isNavigating = true;
    _timer?.cancel();

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    final isAuthenticated =
        session != null && session.user.emailConfirmedAt != null;

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomeShell(controller: widget.controller),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RegisterScreen(controller: AuthenticationViewModel()),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: SplashRoadPainter())),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(size: 94),
                    const SizedBox(height: 22),
                    Text(
                      'WakeWay',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sleep through the ride.\nWake at the right time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: WakeColors.muted, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: TextButton(
                onPressed: _checkSession,
                child: const Text('Get started'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

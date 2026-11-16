import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakeway/core/storage/preferences_service.dart';
import 'package:wakeway/features/auth/viewmodels/authentication_view_model.dart';
import 'package:wakeway/features/auth/views/privacy_policy_screen.dart';
import 'package:wakeway/features/navigation/views/home_shell.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AuthenticationViewModel controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthenticationViewModel get _auth => widget.controller;
  bool _hasAcceptedPrivacyPolicy = false;
  bool _isLoadingPrivacyPolicyAcceptance = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPrivacyPolicyAcceptance());
  }

  Future<void> _loadPrivacyPolicyAcceptance() async {
    final hasAccepted = await PreferencesService.hasAcceptedPrivacyPolicy();
    if (!mounted) return;

    setState(() {
      _hasAcceptedPrivacyPolicy = hasAccepted;
      _isLoadingPrivacyPolicyAcceptance = false;
    });
  }

  void _setPrivacyPolicyAcceptance(bool? accepted) {
    if (accepted == null || _isLoadingPrivacyPolicyAcceptance) return;

    setState(() => _hasAcceptedPrivacyPolicy = accepted);
    unawaited(PreferencesService.setPrivacyPolicyAccepted(accepted));
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  Future<void> _loginWithGoogle() async {
    if (_auth.isLoading || !_hasAcceptedPrivacyPolicy) return;

    FocusScope.of(context).unfocus();

    final success = await _auth.loginWithGoogle();

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _auth.errorMessage?['message'] ?? 'Google authentication failed.',
          ),
          backgroundColor: WakeColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login successful!'),
        backgroundColor: WakeColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomeShell(
          controller: WakeWayViewModel(
            authenticationRepository: _auth.authenticationRepository,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _auth,
    builder: (context, _) => Scaffold(
      backgroundColor: WakeColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const _Header(),

              Transform.translate(
                offset: const Offset(0, -48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: _buildLoginCard(),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Text(
                  'Your Google account is used to securely '
                  'access your WakeWay account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: WakeColors.muted, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildLoginCard() => SurfaceCard(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to WakeWay',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontSize: 21, letterSpacing: -.3),
        ),

        const SizedBox(height: 8),

        Text(
          'Sign in with your Google account to '
          'plan a smoother start to your day.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 28),

        if (_auth.errorMessage != null) ...[
          _ErrorNotice(
            message: _auth.errorMessage!['message'] ?? 'An error occurred.',
          ),
          const SizedBox(height: 18),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _hasAcceptedPrivacyPolicy,
              onChanged: _isLoadingPrivacyPolicyAcceptance
                  ? null
                  : _setPrivacyPolicyAcceptance,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'I have read and agree to the ',
                      style: TextStyle(color: WakeColors.muted, fontSize: 12),
                    ),
                    InkWell(
                      onTap: _openPrivacyPolicy,
                      borderRadius: BorderRadius.circular(4),
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: WakeColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed:
                _auth.isLoading ||
                    _isLoadingPrivacyPolicyAcceptance ||
                    !_hasAcceptedPrivacyPolicy
                ? null
                : _loginWithGoogle,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F1F1F),
              side: const BorderSide(color: Color(0xFF747775)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _auth.isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Signing in...'),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 12,
                        child: Image.asset(
                          'assets/images/google_g_logo.png',
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 42),
                        child: Text(
                          'Continue with Google',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF102A43), Color(0xFF174A74)],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
    ),
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          right: -66,
          top: 24,
          child: Container(
            height: 190,
            width: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .045),
            ),
          ),
        ),

        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 82),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const BrandMark(size: 50),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WakeWay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'A calmer way to wake up',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .72),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.5,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    'Sign in to continue your journey '
                    'with WakeWay.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .76),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: WakeColors.redSoft,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: WakeColors.red,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: WakeColors.red,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

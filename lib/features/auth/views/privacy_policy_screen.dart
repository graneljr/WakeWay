import 'package:flutter/material.dart';
import 'package:wakeway/shared/ui.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WakeColors.canvas,
    appBar: AppBar(
      leading: const BackButton(),
      title: const Text('Privacy Policy'),
      backgroundColor: WakeColors.canvas,
      surfaceTintColor: Colors.transparent,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SurfaceCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your privacy matters',
                        style: TextStyle(
                          color: WakeColors.ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This page explains what WakeWay uses to provide sign-in, saved places, maps, and trip alerts.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _PolicySection(
                  title: 'Account and sign-in',
                  body: 'When you sign in with Google, WakeWay receives the account details Google provides, such as your account ID, name, email address, and profile image. Supabase handles authentication and keeps your signed-in session.',
                ),
                const _PolicySection(
                  title: 'Location',
                  body: 'WakeWay uses your device location to show your position and monitor an active trip so it can alert you near your stop. Location permission can be changed in your device settings. Online map tiles and place searches use OpenStreetMap services.',
                ),
                const _PolicySection(
                  title: 'Saved places and trips',
                  body: 'Saved place names, addresses, coordinates, trip alarm points, settings, and trip history are stored on your device. When you are signed in, WakeWay can sync this data with your account through Supabase so it can be restored on another device.',
                ),
                const _PolicySection(
                  title: 'How information is used',
                  body: 'WakeWay uses this information to sign you in, show and save destinations, synchronize your backup, and provide trip alerts. The app stores working data locally so core features can remain available offline.',
                ),
                const _PolicySection(
                  title: 'Your choices',
                  body: 'You can manage location and notification permissions in your device settings. You can sign out of your WakeWay account at any time. Saved places and trip records already synced to your account may remain in the cloud after signing out.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: WakeColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.5),
          ),
        ],
      ),
    ),
  );
}

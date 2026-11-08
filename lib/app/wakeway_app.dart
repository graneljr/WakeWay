import 'package:flutter/material.dart';
import 'package:wakeway/features/auth/views/splash_screen.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';

class WakeWayApp extends StatelessWidget {
  const WakeWayApp({super.key, required this.controller});
  final WakeWayViewModel controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WakeWay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: WakeColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: WakeColors.blue,
          primary: WakeColors.blue,
          secondary: WakeColors.green,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: WakeColors.canvas,
          foregroundColor: WakeColors.ink,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: WakeColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: WakeColors.ink,
            fontSize: 30,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
          headlineSmall: TextStyle(
            color: WakeColors.ink,
            fontSize: 24,
            height: 1.18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: TextStyle(
            color: WakeColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: WakeColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: WakeColors.ink, fontSize: 15),
          bodyMedium: TextStyle(color: WakeColors.muted, fontSize: 13),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      home: SplashScreen(controller: controller),
    );
  }
}

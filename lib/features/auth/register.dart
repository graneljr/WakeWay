import 'package:flutter/widgets.dart';
import 'package:wakeway/features/auth/repositories/authentication.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
     super.key,
     required this.controller,
  });
  final Authentication controller;
  @override
  Widget build(BuildContext context) => SafeArea(
  );
}

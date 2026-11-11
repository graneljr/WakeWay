import 'package:flutter/material.dart';
import 'package:wakeway/app/wakeway_app.dart';
import 'package:wakeway/core/database/supabase_service.dart';
import 'package:wakeway/features/auth/repositories/authentication_repository.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  final authRepository = AuthenticationRepository();
  final viewModel = WakeWayViewModel(
    authenticationRepository: authRepository,
  );
  runApp(WakeWayApp(controller: viewModel));
}

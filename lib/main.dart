import 'package:flutter/material.dart';
import 'package:wakeway/app/wakeway_app.dart';
import 'package:wakeway/core/database/supabase_service.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final viewModel = WakeWayViewModel();
  await viewModel.initialize();
  await SupabaseService.initialize();
  runApp(WakeWayApp(controller: viewModel));
}

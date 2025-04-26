import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_scanner_app/core/di/locator.dart';
import 'package:qr_scanner_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:qr_scanner_app/presentation/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para Pigeon y otras inicializaciones
  setupLocator(); // Configura GetIt
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provee el AuthBloc a todo el árbol de widgets
    return BlocProvider(
      create: (_) =>
          locator<AuthBloc>(), // Obtiene la instancia Singleton del locator
      child: MaterialApp(
        title: 'QR Scanner App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomePage(), // Empieza en la HomePage
      ),
    );
  }
}

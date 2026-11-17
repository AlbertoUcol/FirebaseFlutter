import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/usuarios_repository.dart';
import 'views/usuarios_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.usuariosRepository});

  final UsuariosRepository? usuariosRepository;

  @override
  Widget build(BuildContext context) {
    final repository = usuariosRepository ??
        FirestoreUsuariosRepository(FirebaseFirestore.instance);

    return MaterialApp(
      title: 'Usuarios',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B5B),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
      ),
      home: UsuariosPage(repository: repository),
    );
  }
}

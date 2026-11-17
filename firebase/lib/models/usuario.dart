import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.nocuenta,
  });

  final String id;
  final String nombre;
  final String email;
  final String nocuenta;

  factory Usuario.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Usuario(
      id: document.id,
      nombre: data['nombre'] as String,
      email: data['email'] as String,
      nocuenta: data['nocuenta'] as String,
    );
  }

  Map<String, String> toMap() => {
        'nombre': nombre,
        'email': email,
        'nocuenta': nocuenta,
      };
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario.dart';

abstract interface class UsuariosRepository {
  Stream<List<Usuario>> watchUsuarios();

  Future<void> crearUsuario({
    required String nombre,
    required String email,
    required String nocuenta,
  });

  Future<void> actualizarUsuario({
    required String id,
    required String nombre,
    required String email,
    required String nocuenta,
  });

  Future<void> eliminarUsuario(String id);
}

class FirestoreUsuariosRepository implements UsuariosRepository {
  FirestoreUsuariosRepository(FirebaseFirestore firestore)
      : _usuarios = firestore.collection('usuarios');

  final CollectionReference<Map<String, dynamic>> _usuarios;

  @override
  Stream<List<Usuario>> watchUsuarios() {
    return _usuarios.snapshots().map(
          (snapshot) =>
              snapshot.docs.map(Usuario.fromDocument).toList(growable: false),
        );
  }

  @override
  Future<void> crearUsuario({
    required String nombre,
    required String email,
    required String nocuenta,
  }) async {
    await _usuarios.add({
      'nombre': nombre,
      'email': email,
      'nocuenta': nocuenta,
    });
  }

  @override
  Future<void> actualizarUsuario({
    required String id,
    required String nombre,
    required String email,
    required String nocuenta,
  }) async {
    await _usuarios.doc(id).update({
      'nombre': nombre,
      'email': email,
      'nocuenta': nocuenta,
    });
  }

  @override
  Future<void> eliminarUsuario(String id) async {
    await _usuarios.doc(id).delete();
  }
}

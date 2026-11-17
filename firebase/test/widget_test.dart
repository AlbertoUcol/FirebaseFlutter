import 'dart:async';

import 'package:firebase/main.dart';
import 'package:firebase/models/usuario.dart';
import 'package:firebase/services/usuarios_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('registra un usuario y valida los campos', (tester) async {
    final repository = _FakeUsuariosRepository();
    await tester.pumpWidget(MyApp(usuariosRepository: repository));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Aún no hay usuarios registrados.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Nuevo usuario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa el nombre.'), findsOneWidget);
    expect(find.text('Ingresa el correo electrónico.'), findsOneWidget);
    expect(find.text('Ingresa el número de cuenta.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('nombre-field')),
      'Ana Pérez',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('nocuenta-field')),
      '12345',
    );
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(repository.usuarios, hasLength(1));
    expect(repository.usuarios.single.nombre, 'Ana Pérez');
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Cuenta: 12345\nana@example.com'), findsOneWidget);

    await repository.dispose();
  });
}

class _FakeUsuariosRepository implements UsuariosRepository {
  final _updates = StreamController<List<Usuario>>.broadcast();
  List<Usuario> usuarios = [];
  int _nextId = 0;

  @override
  Stream<List<Usuario>> watchUsuarios() {
    return Stream<List<Usuario>>.multi((controller) {
      controller.add(usuarios);
      final subscription = _updates.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> crearUsuario({
    required String nombre,
    required String email,
    required String nocuenta,
  }) async {
    usuarios = [
      ...usuarios,
      Usuario(
        id: '${_nextId++}',
        nombre: nombre,
        email: email,
        nocuenta: nocuenta,
      ),
    ];
    _updates.add(usuarios);
  }

  @override
  Future<void> actualizarUsuario({
    required String id,
    required String nombre,
    required String email,
    required String nocuenta,
  }) async {
    usuarios = usuarios
        .map(
          (usuario) => usuario.id == id
              ? Usuario(
                  id: id,
                  nombre: nombre,
                  email: email,
                  nocuenta: nocuenta,
                )
              : usuario,
        )
        .toList();
    _updates.add(usuarios);
  }

  @override
  Future<void> eliminarUsuario(String id) async {
    usuarios = usuarios.where((usuario) => usuario.id != id).toList();
    _updates.add(usuarios);
  }

  Future<void> dispose() => _updates.close();
}

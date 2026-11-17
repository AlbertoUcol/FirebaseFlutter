import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/usuarios_repository.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key, required this.repository});

  final UsuariosRepository repository;

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  late final Stream<List<Usuario>> _usuariosStream;
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _usuariosStream = widget.repository.watchUsuarios();
  }

  Future<void> _showUsuarioForm({Usuario? usuario}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => UsuarioFormDialog(
        usuario: usuario,
        onSubmit: (nombre, email, nocuenta) {
          if (usuario == null) {
            return widget.repository.crearUsuario(
              nombre: nombre,
              email: email,
              nocuenta: nocuenta,
            );
          }
          return widget.repository.actualizarUsuario(
            id: usuario.id,
            nombre: nombre,
            email: email,
            nocuenta: nocuenta,
          );
        },
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            usuario == null
                ? 'Usuario registrado correctamente.'
                : 'Usuario actualizado correctamente.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmarEliminacion(Usuario usuario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Quieres eliminar a ${usuario.nombre}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(usuario.id));
    try {
      await widget.repository.eliminarUsuario(usuario.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado correctamente.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar el usuario: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingIds.remove(usuario.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Usuarios',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: colors.surface,
      ),
      body: StreamBuilder<List<Usuario>>(
        stream: _usuariosStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.cloud_off_outlined,
              message: 'No se pudieron cargar los usuarios.\n${snapshot.error}',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final usuarios = snapshot.data ?? const <Usuario>[];
          if (usuarios.isEmpty) {
            return const _MessageState(
              icon: Icons.group_outlined,
              message: 'Aún no hay usuarios registrados.\nAgrega uno para comenzar.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: usuarios.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return Card(
                elevation: 0,
                color: colors.surface,
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: Text(
                      usuario.nombre.isEmpty
                          ? '?'
                          : usuario.nombre.characters.first.toUpperCase(),
                    ),
                  ),
                  title: Text(
                    usuario.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Cuenta: ${usuario.nocuenta}\n${usuario.email}',
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar usuario',
                        onPressed: () => _showUsuarioForm(usuario: usuario),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Eliminar usuario',
                        onPressed: _deletingIds.contains(usuario.id)
                            ? null
                            : () => _confirmarEliminacion(usuario),
                        icon: _deletingIds.contains(usuario.id)
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        color: colors.error,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUsuarioForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo usuario'),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class UsuarioFormDialog extends StatefulWidget {
  const UsuarioFormDialog({
    super.key,
    required this.onSubmit,
    this.usuario,
  });

  final Usuario? usuario;
  final Future<void> Function(String nombre, String email, String nocuenta)
      onSubmit;

  @override
  State<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _emailController;
  late final TextEditingController _nocuentaController;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.usuario?.nombre ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _nocuentaController =
        TextEditingController(text: widget.usuario?.nocuenta ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _nocuentaController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        _nombreController.text.trim(),
        _emailController.text.trim(),
        _nocuentaController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo guardar el usuario: $error';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.usuario != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar usuario' : 'Nuevo usuario'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('nombre-field'),
                  controller: _nombreController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el nombre.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('email-field'),
                  controller: _emailController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Ingresa el correo electrónico.';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)) {
                      return 'Ingresa un correo electrónico válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('nocuenta-field'),
                  controller: _nocuentaController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Número de cuenta',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el número de cuenta.'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _guardar,
          icon: _isSaving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(isEditing ? 'Guardar cambios' : 'Registrar'),
        ),
      ],
    );
  }
}

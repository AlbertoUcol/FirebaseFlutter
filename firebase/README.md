# Administrador de usuarios con Flutter y Firebase

Aplicación Flutter para crear, consultar en tiempo real, editar y eliminar
documentos de la colección `usuarios` en Cloud Firestore. Cada documento usa
los campos `nombre`, `email` y `nocuenta` (todos de tipo texto).

## Configuración

1. Verifica que `lib/firebase_options.dart` y la configuración nativa
   correspondan a tu proyecto Firebase.
2. Habilita Cloud Firestore en Firebase Console y configura reglas que permitan
   las operaciones de lectura y escritura a los usuarios autorizados de tu app.
3. Instala dependencias y ejecuta la aplicación:

   ```sh
   flutter pub get
   flutter run
   ```

Firebase se inicializa al iniciar la app en `lib/main.dart`. La pantalla CRUD
está en `lib/views/usuarios_page.dart` y el acceso a Firestore en
`lib/services/usuarios_repository.dart`.

# Flutter App

1. Crear proyecto:
   ```bash
   flutter create flutter_app
   ```

2. Sustituir o agregar los archivos dentro de `lib/` con los provistos en esta plantilla.

3. Añadir dependencias y generar:
   ```bash
   cd flutter_app
   flutter pub get
   flutter pub add flutter_riverpod dio flutter_secure_storage form_field_validator json_annotation
   flutter pub add --dev build_runner json_serializable
   ```

4. Ejecutar en emulador Android (usa 10.0.2.2 para acceder al backend local):
   ```bash
   flutter run
   ```

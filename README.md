# qr_scanner_app

Aplicación Flutter para Android que escanee códigos QR usando la cámara nativa de Android (Kotlin + CameraX) y que implemente autenticación biométrica nativa (Kotlin + BiometricPrompt), todo dentro de una arquitectura limpia y con comunicación eficiente entre Flutter y Kotlin usando Pigeon.

Arquitectura Propuesta (Clean Architecture):

      
+-----------------------+      +--------------------+      +-------------------------+      +--------------------------+
|Presentation (Flutter) | ---> |   Domain (Dart)    | ---> |     Data (Dart/Kotlin)  | ---> |   Native (Kotlin/Android)|
|-----------------------|      |--------------------|      |-------------------------|      |--------------------------|
| - Widgets (Screens)   |      | - Entities         |      | - Repositories Impl     |      | - BiometricPrompt API    |
| - BLoCs / Cubits      |      | - Use Cases        |      | - Data Sources (Local/  |      | - CameraX API / ML Kit   |
| - Navigation          |      | - Repository Ports |      |   Remote/Native)        |      | - Room / SQLite          |
|                       |      |   (Interfaces)     |      |   - Pigeon Clients      |      | - EncryptedSharedPrefs   |
|                       |      |                    |      |   - sqflite / secure_   |      | - Pigeon Host Impl       |
|                       |      |                    |      |     storage             |      |                          |
+-----------------------+      +--------------------+      +-------------------------+      +--------------------------+

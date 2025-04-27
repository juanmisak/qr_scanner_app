# qr_scanner_app

Aplicación Flutter para Android que escanee códigos QR usando la cámara nativa de Android (Kotlin + CameraX) y que implemente autenticación biométrica nativa (Kotlin + BiometricPrompt), todo dentro de una arquitectura limpia y con comunicación eficiente entre Flutter y Kotlin usando Pigeon.

Arquitectura Propuesta (Clean Architecture):

      
+-----------------------+      +--------------------+      +-------------------------+      +--------------------------+
|Presentation (Flutter) | ---> |   Domain (Dart)    | ---> |     Data (Dart/Kotlin)  | ---> |   Native (Kotlin/Android)|
|-----------------------|      |--------------------|      |-------------------------|      |--------------------------|
| - Widgets (Screens)   |      | - Entities         |      | - Repositories Impl     |      | - BiometricPrompt API    |
| - BLoCs / Cubits      |      | - Use Cases        |      | - Data Sources (Local/  |      | - CameraX API / ML Kit   |
| - Navigation          |      | - Repository Ports |      |   Remote/Native)        |      | - SQLite                 |
|                       |      |   (Interfaces)     |      |   - Pigeon Clients      |      | - Pigeon Host Impl       |
|                       |      |                    |      |   - sqflite / secure_   |      |                          |
|                       |      |                    |      |     storage             |      |                          |
+-----------------------+      +--------------------+      +-------------------------+      +--------------------------+

## Flujo principal de Escaneo y guardado del historial de QRs

1. Flutter (ScannerPage): Usuario presiona el FAB -> Se pide permiso -> Si se concede -> Se dispara ScanRequested en ScannerBloc.

2. Flutter (ScannerBloc): Recibe ScanRequested -> Emite ScannerLoading -> Llama a StartQrScan (UseCase).

3. Flutter (StartQrScan -> ScanRepositoryImpl -> QrScannerNativeDataSourceImpl): Llama a _api.scanQrCode() (Cliente Pigeon).

4. Pigeon: Envía mensaje al lado nativo.

5. Kotlin (MainActivity.NativeQrScannerApi): Recibe la llamada scanQrCode -> Guarda el callback de Pigeon -> Lanza QrScannerActivity usando scanQrLauncher.

6. Kotlin (QrScannerActivity): Se inicia -> Pide permiso (si no lo tiene) -> Inicia CameraX -> bindPreviewAndAnalysis.

7. Kotlin (QrScannerActivity.processImageProxy): Recibe frames -> Llama a barcodeScanner.process().

8. ML Kit: Procesa la imagen.

9. Kotlin (QrScannerActivity.addOnSuccessListener): Si ML Kit detecta un QR (barcodes.isNotEmpty()) -> Obtiene rawValue -> Si rawValue no es null -> Llama a finishWithSuccess(rawValue).

10. Kotlin (QrScannerActivity.finishWithSuccess): Crea un Intent con el rawValue como extra -> Llama a setResult(Activity.RESULT_OK, intent) -> Llama a finish().

11. Kotlin (MainActivity.scanQrLauncher): Recibe el resultado RESULT_OK y el Intent -> Extrae el rawValue -> Crea QrScanResult(code = rawValue, cancelled = false) -> Llama a callback(Result.success(qrScanResult)) (el callback de Pigeon).

12. Pigeon: Envía el QrScanResult de vuelta a Flutter.

14. Flutter (QrScannerNativeDataSourceImpl -> ScanRepositoryImpl -> StartQrScan): Recibe el Right(QrScanResult).

15. Flutter (ScannerBloc): Recibe Right(qrScanResult) -> Ejecuta el fold Right -> Detecta code no nulo -> Emite ScanSuccess(code) -> Añade evento interno _SaveScanRequested(code).

16. Flutter (ScannerBloc): Recibe _SaveScanRequested -> Emite ScanSaveInProgress -> Llama a SaveScanResult (UseCase).

17. Flutter (SaveScanResult -> ScanRepositoryImpl -> ScanHistoryLocalDataSourceImpl): Guarda el ScanResult en SQLite.

18. Flutter (ScannerBloc): Recibe Right(id) del guardado -> Emite ScanSaveSuccess(code).

19. Flutter (ScannerPage.BlocListener): Detecta ScanSaveSuccess -> Muestra SnackBar de éxito -> Dispara LoadHistory en HistoryBloc.

20. Flutter (HistoryBloc): Recibe LoadHistory -> Emite HistoryLoading -> Llama a GetScanHistory -> Recibe la lista actualizada -> Emite HistoryLoaded(scans).

21. Flutter (ScannerPage.BlocBuilder): Detecta HistoryLoaded y reconstruye la ListView con el nuevo ítem.
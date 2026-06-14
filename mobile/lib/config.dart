/// Where the OpenSoundTouch backend (Spring Boot) is hosted.
///
/// In development, point this at your local backend (http://10.0.2.2:8080 on
/// Android emulator, http://localhost:8080 on web/Windows/iOS simulator).
/// Override at runtime by passing --dart-define=BACKEND_URL=https://your-host.
const String backendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:8080',
);

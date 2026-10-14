# StudyPet

StudyPet is an offline-first Flutter focus companion designed to work with a desktop StudyPet robot when available. The current build includes a polished demo mode so the core experience works without hardware.

## Run

Install Flutter 3.22+ (Dart 3.3+), then:

```bash
flutter pub get
dart format lib
flutter analyze
flutter test
flutter run
```

The project has been validated with Flutter 3.47.7 and Dart 3.13.5. Android builds additionally require the Android SDK; Linux and Chrome targets are available in the generated project.

## Demo mode

Demo mode is enabled by default. Start a session from Home, choose a subject, task, and duration, and use **End session** to save an interrupted session or let the timer finish. Home, Progress, and Rewards derive their values from locally persisted records. Settings can reset demo data or disable demo mode.

## Hardware integration

`DemoDeviceService` and `RealDeviceApiService` implement the same device boundary. Real mode is configured for your Raspberry Pi backend at `https://192.168.129.17:8000` by default and uses these existing endpoints:

* `GET /`
* `GET /status`
* `POST /session/start`
* `POST /session/stop`
* `POST /puzzle/answer`

The `/status` response is expected to include `session_active`, `study_state`, `eye_state`, `session_duration_seconds`, `closed_duration_seconds`, `alert_count`, and optionally `session_started_at`. A physical phone cannot use the computer's `localhost`; use the Raspberry Pi LAN IP. The app must never report real monitoring when the API is unavailable.

### Connect a Raspberry Pi

1. Run the Pi API on `0.0.0.0`, not only `127.0.0.1`. For example, with FastAPI:

   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

2. Find the Pi address:

   ```bash
   hostname -I
   ```

3. From the development computer and then from the phone, verify:

   ```bash
   curl -k https://PI_IP:8000/status
   ```

4. Put the phone and Pi on the same Wi-Fi/LAN. In the app open **Settings → Hardware connection**, enter `https://PI_IP:8000`, and select **Save and test**. This automatically disables demo mode.

5. Start a session. The app sends `POST /session/start` to the Pi before the timer begins and sends `POST /session/stop` when the session ends. During the session it polls `/status` and opens the puzzle dialog when `study_state` becomes `PUZZLE_REQUIRED`.

If the Pi uses a self-signed HTTPS certificate, Android and Chrome may reject it. For development, use a trusted certificate or expose plain HTTP only on the private LAN and enter `http://PI_IP:8000`. Do not expose an unauthenticated development API to the public internet. Chrome/web builds also require the Pi API to enable CORS for the app's origin.

## Structure

* `lib/models.dart` - typed domain models and enums
* `lib/services.dart` - local persistence, demo hardware, real API, streak calculation
* `lib/providers.dart` - Riverpod application state
* `lib/screens.dart` - navigation destinations and core flows
* `lib/widgets.dart` - reusable mascot, status, and section components

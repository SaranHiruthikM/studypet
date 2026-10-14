import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class LocalStore {
  LocalStore(this.prefs);
  final SharedPreferences prefs;
  List<StudyGoal> get goals =>
      decodeList(prefs.getString('goals')).map(StudyGoal.fromJson).toList();
  List<StudySession> get sessions => decodeList(prefs.getString('sessions'))
      .map(StudySession.fromJson)
      .toList();
  Future<void> saveGoals(List<StudyGoal> value) => prefs.setString(
      'goals', encodeList(value.map((e) => e.toJson()).toList()));
  Future<void> saveSessions(List<StudySession> value) => prefs.setString(
      'sessions', encodeList(value.map((e) => e.toJson()).toList()));
}

abstract class DeviceService {
  Future<void> healthCheck();
  Future<DeviceStatus> status();
  Future<BackendStatus> backendStatus();
  Future<void> startSession(StudySession session);
  Future<void> endSession();
  Future<bool> submitPuzzleAnswer(int answer);
}

class DemoDeviceService implements DeviceService {
  DeviceStatus _status = DeviceStatus(
    connected: true,
    monitoringAvailable: true,
    presence: PresenceState.present,
    activity: ActivityState.ready,
    deviceName: 'StudyPet Demo',
  );
  @override
  Future<void> healthCheck() async {}

  @override
  Future<DeviceStatus> status() async => _status;
  @override
  Future<void> startSession(StudySession session) async {
    _status = DeviceStatus(
      connected: true,
      monitoringAvailable: true,
      presence: PresenceState.present,
      activity: ActivityState.focusing,
      deviceName: 'StudyPet Demo',
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<void> endSession() async {
    _status = DeviceStatus(
      connected: true,
      monitoringAvailable: true,
      presence: PresenceState.present,
      activity: ActivityState.ready,
      deviceName: 'StudyPet Demo',
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<BackendStatus> backendStatus() async => const BackendStatus(
      sessionActive: true, studyState: 'MONITORING', eyeState: 'OPEN');

  @override
  Future<bool> submitPuzzleAnswer(int answer) async => answer == 42;
}

class RealDeviceApiService implements DeviceService {
  RealDeviceApiService(String baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
  final Dio _dio;
  @override
  Future<void> healthCheck() async {
    await _dio.get('/');
  }

  @override
  Future<DeviceStatus> status() async {
    final response = await _dio.get('/status');
    final data = response.data as Map<String, dynamic>;
    return DeviceStatus(
      connected: true,
      monitoringAvailable: true,
      presence: PresenceState.present,
      activity: _activity(data['study_state'] as String?),
      deviceName: 'StudyPet Raspberry Pi',
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<BackendStatus> backendStatus() async {
    final response = await _dio.get('/status');
    return BackendStatus.fromJson(response.data as Map<String, dynamic>);
  }

  ActivityState _activity(String? value) => switch (value) {
        'MONITORING' => ActivityState.focusing,
        'PUZZLE_REQUIRED' => ActivityState.challenge,
        'INACTIVE' => ActivityState.inactive,
        _ => ActivityState.unavailable,
      };
  @override
  Future<void> startSession(StudySession session) =>
      _dio.post('/session/start');

  @override
  Future<void> endSession() => _dio.post('/session/stop');

  @override
  Future<bool> submitPuzzleAnswer(int answer) async {
    final response =
        await _dio.post('/puzzle/answer', data: {'answer': answer});
    final data = response.data;
    if (data is bool) return data;
    if (data is String) return data.toLowerCase() == 'correct';
    if (data is Map<String, dynamic>) {
      return data['accepted'] == true ||
          data['correct'] == true ||
          data['success'] == true;
    }
    return false;
  }
}

int calculateStreak(List<StudySession> sessions, {DateTime? now}) {
  final today = DateTime(now?.year ?? DateTime.now().year,
      now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);
  final days = sessions
      .where((s) => s.status == SessionStatus.completed && s.actualMinutes > 0)
      .map(
          (s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
      .toSet();
  var streak = 0;
  var day = today;
  while (days.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'services.dart';

final prefsProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError());
final storeProvider =
    Provider<LocalStore>((ref) => LocalStore(ref.watch(prefsProvider)));
final demoModeProvider = StateProvider<bool>(
    (ref) => ref.watch(prefsProvider).getBool('demoMode') ?? true);
final apiBaseUrlProvider = StateProvider<String>((ref) =>
    ref.watch(prefsProvider).getString('apiBaseUrl') ??
    'https://192.168.129.17:8000');
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final deviceServiceProvider = Provider<DeviceService>((ref) {
  if (ref.watch(demoModeProvider)) return DemoDeviceService();
  return RealDeviceApiService(ref.watch(apiBaseUrlProvider));
});
final deviceProvider = FutureProvider<DeviceStatus>((ref) async {
  return ref.watch(deviceServiceProvider).status();
});

class StudyData extends StateNotifier<AsyncValue<void>> {
  StudyData(this.store) : super(const AsyncData(null));
  final LocalStore store;
  List<StudyGoal> goals = [];
  List<StudySession> sessions = [];
  Future<void> load() async {
    goals = store.goals;
    sessions = store.sessions;
    state = const AsyncData(null);
  }

  Future<void> addGoal(
      String subject, String task, int target, int duration) async {
    goals = [
      ...goals,
      StudyGoal(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          subject: subject,
          task: task,
          dailyTarget: target,
          sessionDuration: duration)
    ];
    await store.saveGoals(goals);
    state = const AsyncData(null);
  }

  Future<void> saveSession(StudySession session) async {
    sessions = [...sessions.where((s) => s.id != session.id), session];
    await store.saveSessions(sessions);
    state = const AsyncData(null);
  }

  Future<void> reset() async {
    goals = [];
    sessions = [];
    await store.saveGoals(goals);
    await store.saveSessions(sessions);
    state = const AsyncData(null);
  }
}

final studyDataProvider = StateNotifierProvider<StudyData, AsyncValue<void>>(
    (ref) => StudyData(ref.watch(storeProvider)));

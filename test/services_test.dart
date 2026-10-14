import 'package:flutter_test/flutter_test.dart';
import 'package:studypet/models.dart';
import 'package:studypet/services.dart';

void main() {
  StudySession session(DateTime day, SessionStatus status,
          [int minutes = 25]) =>
      StudySession(
        id: day.toIso8601String(),
        subject: 'Math',
        task: 'Practice',
        plannedMinutes: minutes,
        startedAt: day,
        status: status,
        actualMinutes: minutes,
      );

  test('streak counts consecutive completed local calendar days', () {
    final today = DateTime(2026, 10, 13, 20);
    final sessions = [
      session(DateTime(2026, 10, 13), SessionStatus.completed),
      session(DateTime(2026, 10, 12), SessionStatus.completed),
      session(DateTime(2026, 10, 11), SessionStatus.completed),
      session(DateTime(2026, 10, 9), SessionStatus.completed),
    ];

    expect(calculateStreak(sessions, now: today), 3);
  });

  test('interrupted sessions do not contribute to streaks', () {
    final today = DateTime(2026, 10, 13);
    expect(
      calculateStreak([session(today, SessionStatus.interrupted)], now: today),
      0,
    );
  });
}

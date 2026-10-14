import 'dart:convert';

enum SessionStatus { planned, active, completed, interrupted, cancelled }

enum PresenceState { present, absent, unknown }

enum ActivityState { ready, focusing, inactive, challenge, unavailable }

class StudyGoal {
  StudyGoal({
    required this.id,
    required this.subject,
    required this.task,
    required this.dailyTarget,
    required this.sessionDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedMinutes = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  final String id;
  final String subject;
  final String task;
  final int dailyTarget;
  final int sessionDuration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int completedMinutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'task': task,
        'dailyTarget': dailyTarget,
        'sessionDuration': sessionDuration,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedMinutes': completedMinutes,
      };
  factory StudyGoal.fromJson(Map<String, dynamic> j) => StudyGoal(
        id: j['id'],
        subject: j['subject'],
        task: j['task'],
        dailyTarget: j['dailyTarget'],
        sessionDuration: j['sessionDuration'],
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
        completedMinutes: j['completedMinutes'] ?? 0,
      );
}

class StudySession {
  StudySession({
    required this.id,
    required this.subject,
    required this.task,
    required this.plannedMinutes,
    required this.startedAt,
    required this.status,
    this.endedAt,
    this.actualMinutes = 0,
    this.goalId,
    this.points = 0,
  });
  final String id;
  final String subject;
  final String task;
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int actualMinutes;
  final SessionStatus status;
  final String? goalId;
  final int points;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'task': task,
        'plannedMinutes': plannedMinutes,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'actualMinutes': actualMinutes,
        'status': status.name,
        'goalId': goalId,
        'points': points,
      };
  factory StudySession.fromJson(Map<String, dynamic> j) => StudySession(
        id: j['id'],
        subject: j['subject'],
        task: j['task'],
        plannedMinutes: j['plannedMinutes'],
        startedAt: DateTime.parse(j['startedAt']),
        endedAt: j['endedAt'] == null ? null : DateTime.parse(j['endedAt']),
        actualMinutes: j['actualMinutes'] ?? 0,
        status: SessionStatus.values.byName(j['status']),
        goalId: j['goalId'],
        points: j['points'] ?? 0,
      );
}

class DeviceStatus {
  const DeviceStatus({
    this.connected = false,
    this.monitoringAvailable = false,
    this.presence = PresenceState.unknown,
    this.activity = ActivityState.unavailable,
    this.deviceName,
    this.lastUpdated,
  });
  final bool connected;
  final bool monitoringAvailable;
  final PresenceState presence;
  final ActivityState activity;
  final String? deviceName;
  final DateTime? lastUpdated;
}

class BackendStatus {
  const BackendStatus({
    this.sessionActive = false,
    this.studyState = 'IDLE',
    this.eyeState = 'UNKNOWN',
    this.sessionDurationSeconds = 0,
    this.closedDurationSeconds = 0,
    this.alertCount = 0,
    this.sessionStartedAt,
  });

  final bool sessionActive;
  final String studyState;
  final String eyeState;
  final int sessionDurationSeconds;
  final double closedDurationSeconds;
  final int alertCount;
  final DateTime? sessionStartedAt;

  bool get puzzleRequired => studyState.toUpperCase() == 'PUZZLE_REQUIRED';

  factory BackendStatus.fromJson(Map<String, dynamic> json) => BackendStatus(
        sessionActive: json['session_active'] == true,
        studyState: json['study_state'] as String? ?? 'UNKNOWN',
        eyeState: json['eye_state'] as String? ?? 'UNKNOWN',
        sessionDurationSeconds:
            (json['session_duration_seconds'] as num?)?.toInt() ?? 0,
        closedDurationSeconds:
            (json['closed_duration_seconds'] as num?)?.toDouble() ?? 0,
        alertCount: (json['alert_count'] as num?)?.toInt() ?? 0,
        sessionStartedAt:
            DateTime.tryParse(json['session_started_at'] as String? ?? ''),
      );
}

String encodeList(List<Map<String, dynamic>> values) => jsonEncode(values);
List<Map<String, dynamic>> decodeList(String? value) => value == null
    ? []
    : (jsonDecode(value) as List).cast<Map<String, dynamic>>();

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusSessionEntry {
  final int durationSeconds;
  final int remainingSeconds;
  final double riskScore;
  final DateTime timestamp;

  FocusSessionEntry({
    required this.durationSeconds,
    required this.remainingSeconds,
    required this.riskScore,
    required this.timestamp,
  });

  int get focusedSeconds {
    final value = durationSeconds - remainingSeconds;
    return value < 0 ? 0 : value;
  }

  bool get completed => remainingSeconds == 0;

  Map<String, dynamic> toJson() {
    return {
      'duration_seconds': durationSeconds,
      'remaining_seconds': remainingSeconds,
      'risk_score': riskScore,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FocusSessionEntry.fromJson(Map<String, dynamic> json) {
    return FocusSessionEntry(
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      remainingSeconds: (json['remaining_seconds'] as num?)?.toInt() ?? 0,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      timestamp:
          DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class UsageInsightsSummary {
  final int totalSessions;
  final int completedSessions;
  final int completionRatePercent;
  final int averageSessionSeconds;
  final int totalFocusedSeconds;
  final double averageRiskPercent;
  final int highRiskSessions;
  final int goalsAdded;
  final int weeklyFocusChangePercent;

  const UsageInsightsSummary({
    required this.totalSessions,
    required this.completedSessions,
    required this.completionRatePercent,
    required this.averageSessionSeconds,
    required this.totalFocusedSeconds,
    required this.averageRiskPercent,
    required this.highRiskSessions,
    required this.goalsAdded,
    required this.weeklyFocusChangePercent,
  });

  const UsageInsightsSummary.empty()
      : totalSessions = 0,
        completedSessions = 0,
        completionRatePercent = 0,
        averageSessionSeconds = 0,
        totalFocusedSeconds = 0,
        averageRiskPercent = 0,
        highRiskSessions = 0,
        goalsAdded = 0,
        weeklyFocusChangePercent = 0;

  String get weeklyTrendLabel {
    if (totalSessions == 0) return "No weekly trend yet";
    if (weeklyFocusChangePercent > 0) {
      return "Weekly focus +$weeklyFocusChangePercent%";
    }
    if (weeklyFocusChangePercent < 0) {
      return "Weekly focus $weeklyFocusChangePercent%";
    }
    return "Weekly focus steady";
  }

  String get headline {
    if (totalSessions == 0) {
      return "No usage data yet. Start a focus session to unlock insights.";
    }
    if (averageRiskPercent >= 75) {
      return "High procrastination risk pattern detected. Cut distractions and restart with a 5-minute sprint.";
    }
    if (weeklyFocusChangePercent >= 10) {
      return "Strong momentum: your focused time is improving this week.";
    }
    if (weeklyFocusChangePercent <= -10) {
      return "Focus dropped this week. Use smaller milestones to regain consistency.";
    }
    return "Consistency is building. Keep stacking focused sessions.";
  }
}

class UsageInsightsService {
  static const String _focusSessionsKey = 'dozy_focus_sessions_v1';
  static const String _goalsKey = 'dozy_goals_v1';

  static final ValueNotifier<int> usageVersion = ValueNotifier<int>(0);

  static void notifyUsageChanged() {
    usageVersion.value++;
  }

  // ✅ FINAL SAFE VERSION
  static Future<void> logFocusSession({
    required int durationSeconds,
    required int remainingSeconds,
    required double riskScore,
  }) async {

    final prefs = await SharedPreferences.getInstance();
    final sessions = _readSessions(prefs);

    sessions.add(
      FocusSessionEntry(
        durationSeconds: durationSeconds,
        remainingSeconds: remainingSeconds,
        riskScore: riskScore,
        timestamp: DateTime.now(),
      ),
    );

    await prefs.setString(
      _focusSessionsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );

    notifyUsageChanged();
  }

  static Future<UsageInsightsSummary> getSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = _readSessions(prefs);
    final goalsAdded = _readGoalsCount(prefs);

    if (sessions.isEmpty) {
      return UsageInsightsSummary(
        totalSessions: 0,
        completedSessions: 0,
        completionRatePercent: 0,
        averageSessionSeconds: 0,
        totalFocusedSeconds: 0,
        averageRiskPercent: 0,
        highRiskSessions: 0,
        goalsAdded: goalsAdded,
        weeklyFocusChangePercent: 0,
      );
    }

    final totalSessions = sessions.length;
    final completedSessions =
        sessions.where((session) => session.completed).length;

    final totalFocusedSeconds =
        sessions.fold<int>(0, (sum, session) => sum + session.focusedSeconds);

    final averageSessionSeconds =
        (totalFocusedSeconds / totalSessions).round();

    final completionRatePercent =
        ((completedSessions / totalSessions) * 100).round();
    
    final rawRisk =
    (sessions.fold<double>(0, (sum, session) => sum + session.riskScore) /
            totalSessions *
            100);

    double adjustedRisk =
    (rawRisk * 0.7) + ((100 - completionRatePercent) * 0.3);

    adjustedRisk = adjustedRisk.clamp(5, 100);

    final averageRiskPercent = adjustedRisk;

    final highRiskSessions =
        sessions.where((session) => session.riskScore >= 0.75).length;

    final weeklyFocusChangePercent =
        _weeklyFocusChangePercent(sessions);

    debugPrint("Average Risk Percent: $adjustedRisk");
    debugPrint("Total Sessions: $totalSessions");

    return UsageInsightsSummary(
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      completionRatePercent: completionRatePercent,
      averageSessionSeconds: averageSessionSeconds,
      totalFocusedSeconds: totalFocusedSeconds,
      averageRiskPercent: averageRiskPercent,
      highRiskSessions: highRiskSessions,
      goalsAdded: goalsAdded,
      weeklyFocusChangePercent: weeklyFocusChangePercent,
    );
  }

  static List<FocusSessionEntry> _readSessions(SharedPreferences prefs) {
    final raw = prefs.getString(_focusSessionsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .map((item) => FocusSessionEntry.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static int _readGoalsCount(SharedPreferences prefs) {
    final raw = prefs.getString(_goalsKey);
    if (raw == null || raw.isEmpty) return 0;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.length;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  static int _weeklyFocusChangePercent(List<FocusSessionEntry> sessions) {
    final now = DateTime.now();
    final recentStart = now.subtract(const Duration(days: 7));
    final previousStart = now.subtract(const Duration(days: 14));

    final recentMinutes =
        sessions
            .where((session) => session.timestamp.isAfter(recentStart))
            .fold<int>(0, (sum, session) => sum + session.focusedSeconds) ~/
        60;

    final previousMinutes =
        sessions
            .where((session) =>
                session.timestamp.isAfter(previousStart) &&
                session.timestamp.isBefore(recentStart))
            .fold<int>(0, (sum, session) => sum + session.focusedSeconds) ~/
        60;

    if (previousMinutes == 0) {
      if (recentMinutes == 0) return 0;
      return 100;
    }

    return (((recentMinutes - previousMinutes) / previousMinutes) * 100)
        .round();
  }
}

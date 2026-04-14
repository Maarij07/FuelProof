import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get timeStr {
    final t = time;
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}.'
        '${t.millisecond.toString().padLeft(3, '0')}';
  }

  @override
  String toString() =>
      '[$timeStr][${level.name.toUpperCase()}][$tag] $message';
}

/// Global in-memory logger. Use [AppLogger.log], [AppLogger.warn],
/// [AppLogger.error] anywhere. Also mirrors to dart:developer log.
class AppLogger extends ChangeNotifier {
  static final AppLogger instance = AppLogger._();
  AppLogger._();

  final List<LogEntry> _entries = [];
  static const int _maxEntries = 1000;
  bool _notifyScheduled = false;

  List<LogEntry> get entries => List.unmodifiable(_entries);

  static void debug(String tag, String message) =>
      instance._add(LogLevel.debug, tag, message);

  static void log(String tag, String message) =>
      instance._add(LogLevel.info, tag, message);

  static void warn(String tag, String message) =>
      instance._add(LogLevel.warning, tag, message);

  static void error(String tag, String message) =>
      instance._add(LogLevel.error, tag, message);

  void _add(LogLevel level, String tag, String message) {
    final entry = LogEntry(
      time: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );
    _entries.add(entry);
    if (_entries.length > _maxEntries) _entries.removeAt(0);
    developer.log('[${level.name}][$tag] $message');
    _notifySafely();
  }

  void clear() {
    _entries.clear();
    _notifySafely();
  }

  void _notifySafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final canNotifyNow =
        phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks;

    if (canNotifyNow) {
      notifyListeners();
      return;
    }

    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  String exportText() => _entries.map((e) => e.toString()).join('\n');
}

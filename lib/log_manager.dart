import 'package:flutter/material.dart';

class LogEntry {
  final String message;
  final DateTime timestamp;
  final bool isError;

  LogEntry({required this.message, required this.timestamp, this.isError = false});
}

class LogManager extends ChangeNotifier {
  static final LogManager _instance = LogManager._internal();
  factory LogManager() => _instance;
  LogManager._internal();

  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  void addLog(String message, {bool isError = false}) {
    _logs.insert(0, LogEntry(
      message: message,
      timestamp: DateTime.now(),
      isError: isError,
    ));
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}

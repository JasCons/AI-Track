class DebugLogger {
  DebugLogger._internal();
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;

  final List<String> _entries = [];

  void log(String message) {
    final entry = '${DateTime.now().toIso8601String()} | $message';
    _entries.add(entry);
    // Also print to console for Logcat / terminal
    // ignore: avoid_print
    print(entry);
  }

  List<String> get entries => List.unmodifiable(_entries);

  void clear() => _entries.clear();
}

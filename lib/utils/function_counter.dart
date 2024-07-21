
class FunctionCounter {
  final Map<String, int> _counters = {};

  void increment(String functionName) {
    _counters[functionName] = (_counters[functionName] ?? 0) + 1;
  }

  int getCount(String functionName) {
    return _counters[functionName] ?? 0;
  }

  Map<String, int> getAllCounts() {
    return Map.from(_counters);
  }

  void reset() {
    _counters.clear();
  }
}

class FunctionCall {
  final String functionName;
  final DateTime timestamp;

  FunctionCall(this.functionName) : timestamp = DateTime.now();
}

class DetailedFunctionCounter {
  final List<FunctionCall> _calls = [];

  void recordCall(String functionName) {
    _calls.add(FunctionCall(functionName));
  }

  List<FunctionCall> getCalls() {
    return List.from(_calls);
  }

  void reset() {
    _calls.clear();
  }
}
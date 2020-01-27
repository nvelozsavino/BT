class Log {
  String message;
  var logBuffer = new StringBuffer();
  Log._privateConstructor();

  static final Log _instance = Log._privateConstructor();

  static Log get instance {
    return _instance;
  }

  void writeLog(String message) {
    var time = new DateTime.now().toString().substring(0, 16);
    logBuffer.writeln("$time: $message");
  }

  String getLogs() {
    return logBuffer.toString();
  }
}

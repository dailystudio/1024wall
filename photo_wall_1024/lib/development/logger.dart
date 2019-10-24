enum _LogToken {
  DEBUG,
  WARN,
  INFO,
  ERROR,
}

class Logger {

  static var _debugEnabled = false;


  static void setDebugEnabled(bool enabled) {
    _debugEnabled = enabled;
  }

  static void _output(_LogToken token, Object object) {
    print("[${_tokenToString(token)}] $object");
  }

  static void info(Object object) {
    _output(_LogToken.INFO, object);
  }

  static void error(Object object) {
    _output(_LogToken.ERROR, object);
  }

  static void warn(Object object) {
    _output(_LogToken.WARN, object);
  }

  static void debug(Object object) {
    if (_debugEnabled) {
      _output(_LogToken.DEBUG, object);
    }
  }

  static String _tokenToString(_LogToken token) {
    return token.toString().split('.')[1];
  }

}
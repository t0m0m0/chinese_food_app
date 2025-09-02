/// Log level constants for consistent logging across the application
///
/// These constants define standardized log levels to replace magic numbers
/// and provide consistent logging behavior throughout the DI system.
class LogConstants {
  LogConstants._(); // Private constructor to prevent instantiation

  /// Information level log (default)
  static const int info = 800;

  /// Warning level log - for non-critical issues
  static const int warning = 900;

  /// Error level log - for errors that don't crash the app
  static const int error = 1000;

  /// Critical level log - for severe errors
  static const int critical = 1200;

  /// Get log level name for display
  static String getLevelName(int level) {
    switch (level) {
      case info:
        return 'INFO';
      case warning:
        return 'WARNING';
      case error:
        return 'ERROR';
      case critical:
        return 'CRITICAL';
      default:
        return 'UNKNOWN';
    }
  }

  /// Validate if log level is valid
  static bool isValidLevel(int level) {
    return [info, warning, error, critical].contains(level);
  }
}

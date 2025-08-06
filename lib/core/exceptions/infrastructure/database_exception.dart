import '../base_exception.dart';

/// Exception thrown when database operations fail
class DatabaseException extends BaseException {
  /// The database operation that failed (e.g., 'INSERT', 'UPDATE')
  final String? operation;

  /// The table involved in the operation
  final String? table;

  /// Creates a database exception
  ///
  /// [message] - Description of the database error
  /// [operation] - Database operation (optional)
  /// [table] - Table name (optional)
  DatabaseException(super.message, {this.operation, this.table})
      : super(severity: ExceptionSeverity.critical);

  @override
  String toString() {
    final details = <String>[];
    if (operation != null) details.add('Operation: $operation');
    if (table != null) details.add('Table: $table');

    return details.isNotEmpty
        ? 'DatabaseException: $message (${details.join(', ')})'
        : 'DatabaseException: $message';
  }
}

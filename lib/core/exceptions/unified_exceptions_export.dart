/// Unified Exception System Export
///
/// This file exports all components of the unified exception handling system.
/// Import this file to access the complete unified exception functionality.
library;

// Base exception and severity enum
export 'base_exception.dart';

// Unified exception types
export 'unified_exceptions.dart';
export 'unified_network_exception.dart';
export 'unified_security_exception.dart';

// Unified exception handler
export 'handlers/unified_exception_handler.dart';

// Legacy exception types (for backward compatibility)
export 'domain/validation_exception.dart';
export 'infrastructure/database_exception.dart';
export 'infrastructure/location_exception.dart';

// App exception wrapper
export 'app_exception.dart';

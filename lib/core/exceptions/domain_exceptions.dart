// DEPRECATED: Use 'unified_exceptions_export.dart' for new code
// This file is maintained for backward compatibility only

// Domain exceptions
export 'domain/validation_exception.dart';

// Infrastructure exceptions - LEGACY (use unified versions)
@Deprecated('Use UnifiedNetworkException instead')
export 'infrastructure/network_exception.dart';
export 'infrastructure/database_exception.dart';
@Deprecated('Use UnifiedNetworkException instead')
export 'infrastructure/api_exception.dart';
export 'infrastructure/location_exception.dart';
@Deprecated('Use UnifiedSecurityException instead')
export 'infrastructure/security_exception.dart';

// Base exception and enum
export 'base_exception.dart';

// New unified exception system
export 'unified_exceptions_export.dart';

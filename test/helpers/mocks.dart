// Package imports
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;

// Local imports
import 'package:chinese_food_app/data/datasources/hotpepper_api_datasource.dart';
import 'package:chinese_food_app/data/datasources/store_local_datasource.dart';
import 'package:chinese_food_app/domain/repositories/location_repository.dart';
import 'package:chinese_food_app/domain/repositories/photo_repository.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/repositories/visit_record_repository.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';

/// 統一されたMockito生成用のアノテーション
///
/// このファイルは以下のコマンドでMockクラスを生成する：
/// ```bash
/// flutter packages pub run build_runner build
/// ```
///
/// 使用例：
/// ```dart
/// import 'mocks.mocks.dart';
///
/// void main() {
///   group('ServiceTest', () {
///     late MockLocationService mockLocationService;
///
///     setUp(() {
///       mockLocationService = MockLocationService();
///     });
///
///     test('should return location', () async {
///       // Given
///       when(mockLocationService.getCurrentLocation())
///           .thenAnswer((_) async => Location(...));
///
///       // When & Then
///       final result = await mockLocationService.getCurrentLocation();
///       expect(result, isA<Location>());
///     });
///   });
/// }
/// ```
@GenerateMocks([
  // Services
  LocationService,

  // Repositories
  StoreRepository,
  LocationRepository,
  VisitRecordRepository,
  PhotoRepository,

  // Data Sources
  HotpepperApiDatasource,
  StoreLocalDatasource,

  // External Dependencies
  http.Client,
])

/// Empty main function required for build_runner mock generation
/// This file should not be executed directly - it only serves as
/// annotation source for generating mocks via build_runner
void main() {}

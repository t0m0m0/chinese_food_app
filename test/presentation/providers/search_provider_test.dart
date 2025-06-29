import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../../../lib/domain/entities/store.dart';
import '../../../lib/domain/entities/location.dart';
import '../../../lib/domain/services/location_service.dart';
import '../../../lib/presentation/providers/search_provider.dart';
import '../../../lib/presentation/providers/store_provider.dart';

class MockStoreProvider extends Mock implements StoreProvider {}
class MockLocationService extends Mock implements LocationService {}

void main() {
  group('SearchProvider Tests', () {
    late SearchProvider searchProvider;
    late MockStoreProvider mockStoreProvider;
    late MockLocationService mockLocationService;

    setUp(() {
      mockStoreProvider = MockStoreProvider();
      mockLocationService = MockLocationService();
      // この行は失敗する - SearchProviderがまだ実装されていない
      searchProvider = SearchProvider(
        storeProvider: mockStoreProvider,
        locationService: mockLocationService,
      );
    });

    test('should be created with initial state', () {
      // 初期状態のテスト - これも失敗する
      expect(searchProvider.isLoading, false);
      expect(searchProvider.isGettingLocation, false);
      expect(searchProvider.errorMessage, null);
      expect(searchProvider.searchResults, isEmpty);
      expect(searchProvider.useCurrentLocation, true);
      expect(searchProvider.hasSearched, false);
    });
  });
}
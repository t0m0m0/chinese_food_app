import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/providers/store_state_manager.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

void main() {
  group('StoreStateManager', () {
    late StoreStateManager stateManager;

    setUp(() {
      stateManager = StoreStateManager();
    });

    test('initial state should be correct', () {
      expect(stateManager.isLoading, false);
      expect(stateManager.error, null);
      expect(stateManager.infoMessage, null);
      expect(stateManager.searchResults, []);
      expect(stateManager.swipeStores, []);
    });

    test('should set loading state', () {
      stateManager.setLoading(true);
      expect(stateManager.isLoading, true);

      stateManager.setLoading(false);
      expect(stateManager.isLoading, false);
    });

    test('should set and clear error', () {
      const errorMessage = 'Test error';

      stateManager.setError(errorMessage);
      expect(stateManager.error, errorMessage);

      stateManager.clearError();
      expect(stateManager.error, null);
    });

    test('should set and clear info message', () {
      const infoMessage = 'Test info';

      stateManager.setInfoMessage(infoMessage);
      expect(stateManager.infoMessage, infoMessage);

      stateManager.clearInfoMessage();
      expect(stateManager.infoMessage, null);
    });

    test('should update search results', () {
      final testStores = [
        Store(
          id: '1',
          name: 'Test Store 1',
          address: 'Test Address 1',
          lat: 35.6917,
          lng: 139.7006,
          createdAt: DateTime.now(),
        ),
        Store(
          id: '2',
          name: 'Test Store 2',
          address: 'Test Address 2',
          lat: 35.6918,
          lng: 139.7007,
          createdAt: DateTime.now(),
        ),
      ];

      stateManager.updateSearchResults(testStores);
      expect(stateManager.searchResults, testStores);
      expect(stateManager.searchResults.length, 2);
    });
  });
}

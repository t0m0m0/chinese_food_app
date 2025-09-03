import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/presentation/providers/store_business_logic.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';

import 'store_business_logic_test.mocks.dart';

@GenerateMocks([StoreRepository, LocationService])
void main() {
  group('StoreBusinessLogic', () {
    late StoreBusinessLogic businessLogic;
    late MockStoreRepository mockRepository;
    late MockLocationService mockLocationService;

    setUp(() {
      mockRepository = MockStoreRepository();
      mockLocationService = MockLocationService();
      businessLogic = StoreBusinessLogic(
        repository: mockRepository,
        locationService: mockLocationService,
      );
    });

    test('initial state should be empty', () {
      expect(businessLogic.allStores, isEmpty);
    });

    test('should load stores from repository', () async {
      final testStores = [
        Store(
          id: '1',
          name: 'Test Store',
          address: 'Test Address',
          lat: 35.6917,
          lng: 139.7006,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getAllStores()).thenAnswer((_) async => testStores);

      final result = await businessLogic.loadStores();
      
      expect(result, testStores);
      expect(businessLogic.allStores, testStores);
      verify(mockRepository.getAllStores()).called(1);
    });

    test('should update store status', () async {
      final testStore = Store(
        id: '1',
        name: 'Test Store',
        address: 'Test Address',
        lat: 35.6917,
        lng: 139.7006,
        createdAt: DateTime.now(),
      );
      
      // 最初に店舗をロード
      when(mockRepository.getAllStores()).thenAnswer((_) async => [testStore]);
      await businessLogic.loadStores();
      
      when(mockRepository.updateStore(any)).thenAnswer((_) async => {});

      await businessLogic.updateStoreStatus('1', StoreStatus.wantToGo);
      
      verify(mockRepository.updateStore(any)).called(1);
      
      // ローカル状態も更新されているか確認
      final updatedStores = businessLogic.allStores;
      expect(updatedStores.first.status, StoreStatus.wantToGo);
    });

    test('should add new store', () async {
      final newStore = Store(
        id: '2',
        name: 'New Store',
        address: 'New Address',
        lat: 35.6918,
        lng: 139.7007,
        createdAt: DateTime.now(),
      );

      when(mockRepository.insertStore(any)).thenAnswer((_) async => {});

      await businessLogic.addStore(newStore);
      
      expect(businessLogic.allStores, contains(newStore));
      verify(mockRepository.insertStore(newStore)).called(1);
    });
  });
}
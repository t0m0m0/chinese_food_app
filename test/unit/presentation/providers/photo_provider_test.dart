import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chinese_food_app/presentation/providers/photo_provider.dart';
import 'package:chinese_food_app/domain/repositories/photo_repository.dart';
import 'package:chinese_food_app/domain/entities/photo.dart';
import 'package:chinese_food_app/domain/usecases/pick_image_usecase.dart';

@GenerateMocks([PhotoRepository, PickImageUsecase])
import 'photo_provider_test.mocks.dart';

void main() {
  group('PhotoProvider Tests', () {
    late PhotoProvider provider;
    late MockPhotoRepository mockRepository;
    late MockPickImageUsecase mockPickImageUsecase;

    setUp(() {
      mockRepository = MockPhotoRepository();
      mockPickImageUsecase = MockPickImageUsecase();
      provider = PhotoProvider(
        repository: mockRepository,
        pickImageUsecase: mockPickImageUsecase,
      );
    });

    group('初期化', () {
      test('初期状態が正しく設定される', () {
        expect(provider.photos, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });
    });

    group('写真読み込み', () {
      test('店舗IDで写真を正常に読み込む', () async {
        // Arrange
        const storeId = 'store_1';
        final mockPhotos = [
          Photo(
            id: 'photo_1',
            storeId: storeId,
            filePath: '/path/to/photo1.jpg',
            createdAt: DateTime.now(),
          ),
        ];
        when(mockRepository.getPhotosByStoreId(storeId))
            .thenAnswer((_) async => mockPhotos);

        // Act
        await provider.loadPhotosByStoreId(storeId);

        // Assert
        expect(provider.photos, equals(mockPhotos));
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
        verify(mockRepository.getPhotosByStoreId(storeId)).called(1);
      });

      test('エラーが発生した場合エラー状態を設定する', () async {
        // Arrange
        const storeId = 'store_1';
        const errorMessage = 'Failed to load photos';
        when(mockRepository.getPhotosByStoreId(storeId))
            .thenThrow(Exception(errorMessage));

        // Act
        await provider.loadPhotosByStoreId(storeId);

        // Assert
        expect(provider.photos, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNotNull);
      });
    });

    group('写真追加', () {
      test('新しい写真を正常に追加する', () async {
        // Arrange
        const storeId = 'store_1';
        final savedPhoto = Photo(
          id: 'photo_2',
          storeId: storeId,
          filePath: '/path/to/new_photo.jpg',
          createdAt: DateTime.now(),
        );

        when(mockPickImageUsecase.pickFromCamera(storeId, visitId: null))
            .thenAnswer((_) async => savedPhoto);

        // Act
        await provider.addPhotoFromCamera(storeId);

        // Assert
        expect(provider.photos, contains(savedPhoto));
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
        verify(mockPickImageUsecase.pickFromCamera(storeId, visitId: null))
            .called(1);
      });

      test('写真追加中はローディング状態になる', () async {
        // Arrange
        const storeId = 'store_1';
        final savedPhoto = Photo(
          id: 'photo_2',
          storeId: storeId,
          filePath: '/path/to/new_photo.jpg',
          createdAt: DateTime.now(),
        );

        when(mockPickImageUsecase.pickFromCamera(storeId, visitId: null))
            .thenAnswer((_) async => savedPhoto);

        // Act & Assert
        expect(provider.isLoading, false);

        final future = provider.addPhotoFromCamera(storeId);
        expect(provider.isLoading, true);

        await future;
        expect(provider.isLoading, false);
      });
    });

    group('写真削除', () {
      test('写真を正常に削除する', () async {
        // Arrange
        final photo = Photo(
          id: 'photo_1',
          storeId: 'store_1',
          filePath: '/path/to/photo1.jpg',
          createdAt: DateTime.now(),
        );

        // PhotoProviderの_photosは不変リストなので、リフレクションで追加
        provider.setError('test'); // notifyListenersを呼ぶため
        provider.clearError(); // エラーをクリア

        when(mockRepository.deletePhoto(photo.id)).thenAnswer((_) async {});

        // Act
        await provider.deletePhoto(photo.id);

        // Assert
        expect(provider.error, isNull);
        verify(mockRepository.deletePhoto(photo.id)).called(1);
      });
    });

    group('状態クリア', () {
      test('エラー状態を正常にクリアする', () {
        // Arrange
        provider.setError('Test error');
        expect(provider.error, isNotNull);

        // Act
        provider.clearError();

        // Assert
        expect(provider.error, isNull);
      });
    });
  });
}

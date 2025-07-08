import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/data/repositories/photo_repository_impl.dart';
import 'package:chinese_food_app/domain/entities/photo.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  late PhotoRepositoryImpl repository;
  late MockPhotoLocalDatasource mockLocalDatasource;

  setUp(() {
    mockLocalDatasource = MockPhotoLocalDatasource();
    repository = PhotoRepositoryImpl(mockLocalDatasource);
  });

  group('PhotoRepositoryImpl', () {
    final testPhoto = Photo(
      id: 'test-id',
      storeId: 'store-id',
      visitId: 'visit-id',
      filePath: '/path/to/test.jpg',
      createdAt: DateTime.now(),
    );

    group('getAllPhotos', () {
      test('should return list of photos from local datasource', () async {
        // Arrange
        when(mockLocalDatasource.getAllPhotos())
            .thenAnswer((_) async => [testPhoto]);

        // Act
        final result = await repository.getAllPhotos();

        // Assert
        expect(result, [testPhoto]);
        verify(mockLocalDatasource.getAllPhotos()).called(1);
      });

      test('should throw exception when local datasource fails', () async {
        // Arrange
        when(mockLocalDatasource.getAllPhotos())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getAllPhotos(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getPhotosByStoreId', () {
      test('should return photos for specific store', () async {
        // Arrange
        const storeId = 'store-123';
        when(mockLocalDatasource.getPhotosByStoreId(storeId))
            .thenAnswer((_) async => [testPhoto]);

        // Act
        final result = await repository.getPhotosByStoreId(storeId);

        // Assert
        expect(result, [testPhoto]);
        verify(mockLocalDatasource.getPhotosByStoreId(storeId)).called(1);
      });
    });

    group('insertPhoto', () {
      test('should insert photo via local datasource', () async {
        // Arrange
        when(mockLocalDatasource.insertPhoto(testPhoto))
            .thenAnswer((_) async => {});

        // Act
        await repository.insertPhoto(testPhoto);

        // Assert
        verify(mockLocalDatasource.insertPhoto(testPhoto)).called(1);
      });
    });

    group('deletePhoto', () {
      test('should delete photo via local datasource', () async {
        // Arrange
        const photoId = 'photo-123';
        when(mockLocalDatasource.deletePhoto(photoId))
            .thenAnswer((_) async => {});

        // Act
        await repository.deletePhoto(photoId);

        // Assert
        verify(mockLocalDatasource.deletePhoto(photoId)).called(1);
      });
    });
  });
}

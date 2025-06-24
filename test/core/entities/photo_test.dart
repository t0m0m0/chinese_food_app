import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/entities/photo.dart';

void main() {
  group('Photo Entity Tests', () {
    test('should create Photo entity with valid data', () {
      // Red: This test should fail initially - Photo entity doesn't exist yet
      final photo = Photo(
        id: 'test-photo-id',
        storeId: 'test-store-id',
        visitId: 'test-visit-id',
        filePath: '/storage/photos/test-photo.jpg',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(photo.id, 'test-photo-id');
      expect(photo.storeId, 'test-store-id');
      expect(photo.visitId, 'test-visit-id');
      expect(photo.filePath, '/storage/photos/test-photo.jpg');
      expect(photo.createdAt, DateTime(2025, 6, 23, 16, 0, 0));
    });

    test('should create Photo entity without visit ID', () {
      final photo = Photo(
        id: 'test-photo-id',
        storeId: 'test-store-id',
        filePath: '/storage/photos/test-photo.jpg',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(photo.visitId, isNull);
    });

    test('should validate required fields', () {
      expect(
          () => Photo(
                id: '',
                storeId: 'test-store-id',
                filePath: '/storage/photos/test-photo.jpg',
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));

      expect(
          () => Photo(
                id: 'test-photo-id',
                storeId: '',
                filePath: '/storage/photos/test-photo.jpg',
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));

      expect(
          () => Photo(
                id: 'test-photo-id',
                storeId: 'test-store-id',
                filePath: '',
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));
    });

    test('should validate file path format', () {
      expect(
          () => Photo(
                id: 'test-photo-id',
                storeId: 'test-store-id',
                filePath: 'invalid-path',
                createdAt: DateTime(2025, 6, 23, 16, 0, 0),
              ),
          throwsA(isA<ArgumentError>()));
    });

    test('should convert to and from JSON', () {
      final originalPhoto = Photo(
        id: 'test-photo-id',
        storeId: 'test-store-id',
        visitId: 'test-visit-id',
        filePath: '/storage/photos/test-photo.jpg',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      final json = originalPhoto.toJson();
      final reconstructedPhoto = Photo.fromJson(json);

      expect(reconstructedPhoto.id, originalPhoto.id);
      expect(reconstructedPhoto.storeId, originalPhoto.storeId);
      expect(reconstructedPhoto.visitId, originalPhoto.visitId);
      expect(reconstructedPhoto.filePath, originalPhoto.filePath);
      expect(reconstructedPhoto.createdAt, originalPhoto.createdAt);
    });

    test('should handle null visit ID in JSON', () {
      final photo = Photo(
        id: 'test-photo-id',
        storeId: 'test-store-id',
        filePath: '/storage/photos/test-photo.jpg',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      final json = photo.toJson();
      final reconstructedPhoto = Photo.fromJson(json);

      expect(reconstructedPhoto.visitId, isNull);
    });

    test('should support equality comparison', () {
      final photo1 = Photo(
        id: 'test-photo-id',
        storeId: 'test-store-id',
        visitId: 'test-visit-id',
        filePath: '/storage/photos/test-photo.jpg',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      final photo2 = Photo(
        id: 'test-photo-id',
        storeId: 'test-store-id',
        visitId: 'test-visit-id',
        filePath: '/storage/photos/test-photo.jpg',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      final photo3 = Photo(
        id: 'different-photo-id',
        storeId: 'test-store-id',
        visitId: 'test-visit-id',
        filePath: '/storage/photos/test-photo.jpg',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(photo1, equals(photo2));
      expect(photo1.hashCode, equals(photo2.hashCode));
      expect(photo1, isNot(equals(photo3)));
    });

    test('should provide file extension getter', () {
      final photo = Photo(
        id: 'test-photo-id',
        storeId: 'test-store-id',
        filePath: '/storage/photos/test-photo.jpg',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(photo.fileExtension, 'jpg');
    });

    test('should provide file name getter', () {
      final photo = Photo(
        id: 'test-photo-id',
        storeId: 'test-store-id',
        filePath: '/storage/photos/test-photo.jpg',
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      );

      expect(photo.fileName, 'test-photo.jpg');
    });
  });
}

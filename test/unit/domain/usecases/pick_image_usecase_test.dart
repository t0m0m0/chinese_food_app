import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/domain/usecases/pick_image_usecase.dart';
import 'package:chinese_food_app/domain/entities/photo.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  late PickImageUsecase usecase;
  late MockPhotoRepository mockPhotoRepository;
  late MockPhotoService mockPhotoService;

  setUp(() {
    mockPhotoRepository = MockPhotoRepository();
    mockPhotoService = MockPhotoService();
    usecase = PickImageUsecase(mockPhotoRepository, mockPhotoService);
  });

  group('PickImageUsecase', () {
    const storeId = 'store-123';
    const visitId = 'visit-456';

    test('should pick image from camera and save it successfully', () async {
      // Arrange
      final testFile = File('/path/to/test/image.jpg');

      when(mockPhotoService.takePhotoFromCamera())
          .thenAnswer((_) async => testFile);

      when(mockPhotoRepository.insertPhoto(any)).thenAnswer((_) async => {});

      // Act
      final result = await usecase.pickFromCamera(storeId, visitId: visitId);

      // Assert
      expect(result, isA<Photo>());
      expect(result.storeId, storeId);
      expect(result.visitId, visitId);
      expect(result.filePath, testFile.path);

      verify(mockPhotoService.takePhotoFromCamera()).called(1);
      verify(mockPhotoRepository.insertPhoto(any)).called(1);
    });

    test('should pick image from gallery and save it successfully', () async {
      // Arrange
      final testFile = File('/path/to/test/gallery.jpg');

      when(mockPhotoService.pickPhotoFromGallery())
          .thenAnswer((_) async => testFile);

      when(mockPhotoRepository.insertPhoto(any)).thenAnswer((_) async => {});

      // Act
      final result = await usecase.pickFromGallery(storeId, visitId: visitId);

      // Assert
      expect(result, isA<Photo>());
      expect(result.storeId, storeId);
      expect(result.visitId, visitId);
      expect(result.filePath, testFile.path);

      verify(mockPhotoService.pickPhotoFromGallery()).called(1);
      verify(mockPhotoRepository.insertPhoto(any)).called(1);
    });

    test('should throw exception when camera picking fails', () async {
      // Arrange
      when(mockPhotoService.takePhotoFromCamera())
          .thenThrow(Exception('Camera permission denied'));

      // Act & Assert
      expect(
        () => usecase.pickFromCamera(storeId),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when gallery picking fails', () async {
      // Arrange
      when(mockPhotoService.pickPhotoFromGallery())
          .thenThrow(Exception('Gallery access denied'));

      // Act & Assert
      expect(
        () => usecase.pickFromGallery(storeId),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle null result from image picker', () async {
      // Arrange
      when(mockPhotoService.takePhotoFromCamera())
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => usecase.pickFromCamera(storeId),
        throwsA(isA<Exception>()),
      );
    });
  });
}

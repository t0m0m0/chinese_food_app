import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:chinese_food_app/presentation/pages/photo_list_view.dart';
import 'package:chinese_food_app/presentation/providers/photo_provider.dart';
import 'package:chinese_food_app/domain/entities/photo.dart';

@GenerateMocks([PhotoProvider])
import 'photo_list_view_test.mocks.dart';

void main() {
  group('PhotoListView Widget Tests', () {
    late MockPhotoProvider mockPhotoProvider;

    setUp(() {
      mockPhotoProvider = MockPhotoProvider();
    });

    Widget createTestWidget({String? storeId, String? visitId}) {
      return MaterialApp(
        home: ChangeNotifierProvider<PhotoProvider>.value(
          value: mockPhotoProvider,
          child: PhotoListView(
            storeId: storeId,
            visitId: visitId,
          ),
        ),
      );
    }

    testWidgets('写真がない場合は空状態メッセージが表示される', (WidgetTester tester) async {
      // Arrange
      when(mockPhotoProvider.photos).thenReturn([]);
      when(mockPhotoProvider.isLoading).thenReturn(false);
      when(mockPhotoProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget(storeId: 'store_1'));

      // Assert
      expect(find.text('写真がありません'), findsOneWidget);
      expect(find.byIcon(Icons.photo), findsOneWidget);
    });

    testWidgets('ローディング中はCircularProgressIndicatorが表示される',
        (WidgetTester tester) async {
      // Arrange
      when(mockPhotoProvider.photos).thenReturn([]);
      when(mockPhotoProvider.isLoading).thenReturn(true);
      when(mockPhotoProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget(storeId: 'store_1'));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('エラーが発生した場合はエラーメッセージが表示される', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Failed to load photos';
      when(mockPhotoProvider.photos).thenReturn([]);
      when(mockPhotoProvider.isLoading).thenReturn(false);
      when(mockPhotoProvider.error).thenReturn(errorMessage);

      // Act
      await tester.pumpWidget(createTestWidget(storeId: 'store_1'));

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('写真リストがグリッド表示される', (WidgetTester tester) async {
      // Arrange
      final mockPhotos = [
        Photo(
          id: 'photo_1',
          storeId: 'store_1',
          filePath: '/path/to/photo1.jpg',
          createdAt: DateTime.now(),
        ),
        Photo(
          id: 'photo_2',
          storeId: 'store_1',
          filePath: '/path/to/photo2.jpg',
          createdAt: DateTime.now(),
        ),
      ];

      when(mockPhotoProvider.photos).thenReturn(mockPhotos);
      when(mockPhotoProvider.isLoading).thenReturn(false);
      when(mockPhotoProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget(storeId: 'store_1'));

      // Assert
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('FABで写真追加ダイアログが表示される', (WidgetTester tester) async {
      // Arrange
      when(mockPhotoProvider.photos).thenReturn([]);
      when(mockPhotoProvider.isLoading).thenReturn(false);
      when(mockPhotoProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget(storeId: 'store_1'));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('写真を追加'), findsOneWidget);
      expect(find.text('カメラで撮影'), findsOneWidget);
      expect(find.text('ギャラリーから選択'), findsOneWidget);
    });

    testWidgets('店舗IDが指定された場合に適切にloadPhotosByStoreIdが呼ばれる',
        (WidgetTester tester) async {
      // Arrange
      const storeId = 'store_1';
      when(mockPhotoProvider.photos).thenReturn([]);
      when(mockPhotoProvider.isLoading).thenReturn(false);
      when(mockPhotoProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget(storeId: storeId));

      // Assert
      verify(mockPhotoProvider.loadPhotosByStoreId(storeId)).called(1);
    });

    testWidgets('訪問記録IDが指定された場合に適切にloadPhotosByVisitIdが呼ばれる',
        (WidgetTester tester) async {
      // Arrange
      const visitId = 'visit_1';
      when(mockPhotoProvider.photos).thenReturn([]);
      when(mockPhotoProvider.isLoading).thenReturn(false);
      when(mockPhotoProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget(visitId: visitId));

      // Assert
      verify(mockPhotoProvider.loadPhotosByVisitId(visitId)).called(1);
    });

    testWidgets('AppBarにタイトルが正しく表示される', (WidgetTester tester) async {
      // Arrange
      when(mockPhotoProvider.photos).thenReturn([]);
      when(mockPhotoProvider.isLoading).thenReturn(false);
      when(mockPhotoProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget(storeId: 'store_1'));

      // Assert
      expect(find.text('写真一覧'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}

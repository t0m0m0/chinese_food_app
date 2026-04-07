import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/presentation/providers/area_search_provider.dart';
import 'package:chinese_food_app/domain/entities/area.dart';
import '../../../helpers/fakes.dart';

/// エリア検索の連動選択テスト
///
/// 都道府県→市区町村の階層選択が正しく連動するかを検証
void main() {
  late FakeStoreRepository storeRepository;
  late StoreProvider storeProvider;
  late AreaSearchProvider provider;

  setUp(() {
    storeRepository = FakeStoreRepository();
    storeProvider = StoreProvider(repository: storeRepository);
    provider = AreaSearchProvider(storeProvider: storeProvider);
  });

  group('都道府県→市区町村の連動選択', () {
    test('都道府県選択で市区町村がクリアされる', () {
      const tokyo = Prefecture(code: '13', name: '東京都');
      const chiyoda = City(
        prefectureCode: '13',
        code: '13101',
        name: '千代田区',
      );

      // 東京都→千代田区を選択
      provider.selectPrefecture(tokyo);
      provider.selectCity(chiyoda);
      expect(provider.selectedCity, chiyoda);

      // 別の都道府県を選択
      const osaka = Prefecture(code: '27', name: '大阪府');
      provider.selectPrefecture(osaka);

      // 市区町村がクリアされる
      expect(provider.selectedPrefecture, osaka);
      expect(provider.selectedCity, isNull);
    });

    test('都道府県選択でcanSearchがtrueになる', () {
      expect(provider.canSearch, false);

      const tokyo = Prefecture(code: '13', name: '東京都');
      provider.selectPrefecture(tokyo);

      expect(provider.canSearch, true);
    });

    test('市区町村クリアで都道府県レベルに戻る', () {
      const tokyo = Prefecture(code: '13', name: '東京都');
      const chiyoda = City(
        prefectureCode: '13',
        code: '13101',
        name: '千代田区',
      );

      provider.selectPrefecture(tokyo);
      provider.selectCity(chiyoda);
      expect(provider.selectedCity, isNotNull);

      provider.clearCity();

      expect(provider.selectedPrefecture, tokyo);
      expect(provider.selectedCity, isNull);
    });

    test('currentSelectionが正しいAreaSelectionを返す', () {
      expect(provider.currentSelection, isNull);

      const tokyo = Prefecture(code: '13', name: '東京都');
      provider.selectPrefecture(tokyo);

      expect(provider.currentSelection, isNotNull);
      expect(provider.currentSelection!.prefecture, tokyo);
      expect(provider.currentSelection!.hasCity, false);
      expect(provider.currentSelection!.toSearchAddress(), '東京都');

      const shibuya = City(
        prefectureCode: '13',
        code: '13113',
        name: '渋谷区',
      );
      provider.selectCity(shibuya);

      expect(provider.currentSelection!.hasCity, true);
      expect(provider.currentSelection!.toSearchAddress(), '東京都渋谷区');
    });

    test('都道府県選択時に自動検索が実行される', () async {
      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      const tokyo = Prefecture(code: '13', name: '東京都');
      provider.selectPrefecture(tokyo);

      // リスナーが通知される
      expect(notified, true);
      // hasSearchedがtrueになる（自動検索が実行される）
      await Future.delayed(Duration.zero);
      expect(provider.hasSearched, true);
    });

    test('市区町村選択時に自動検索が実行される', () async {
      const tokyo = Prefecture(code: '13', name: '東京都');
      provider.selectPrefecture(tokyo);
      await Future.delayed(Duration.zero);

      const chiyoda = City(
        prefectureCode: '13',
        code: '13101',
        name: '千代田区',
      );
      provider.selectCity(chiyoda);
      await Future.delayed(Duration.zero);

      expect(provider.hasSearched, true);
    });

    test('都道府県変更でページネーションがリセットされる', () async {
      const tokyo = Prefecture(code: '13', name: '東京都');
      provider.selectPrefecture(tokyo);
      await Future.delayed(Duration.zero);

      // 検索結果とページネーション状態を確認
      expect(provider.searchResults, isEmpty);

      // 別の都道府県に変更
      const osaka = Prefecture(code: '27', name: '大阪府');
      provider.selectPrefecture(osaka);
      await Future.delayed(Duration.zero);

      expect(provider.searchResults, isEmpty);
      expect(provider.hasMoreResults, false);
    });

    test('prefecturesリストが空でない', () {
      expect(provider.prefectures, isNotEmpty);
    });

    test('prefecturesByRegionが空でない', () {
      expect(provider.prefecturesByRegion, isNotEmpty);
    });

    test('searchRange設定が正しく動作する', () {
      provider.setSearchRange(5);
      expect(provider.searchRange, 5);

      // 無効な値は無視される
      provider.setSearchRange(0);
      expect(provider.searchRange, 5); // 変更なし

      provider.setSearchRange(6);
      expect(provider.searchRange, 5); // 変更なし
    });
  });
}

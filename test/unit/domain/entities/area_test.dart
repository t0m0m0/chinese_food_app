import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/area.dart';

void main() {
  group('Prefecture', () {
    test('should create a Prefecture with name and code', () {
      const prefecture = Prefecture(
        code: '13',
        name: '東京都',
      );

      expect(prefecture.code, '13');
      expect(prefecture.name, '東京都');
    });

    test('should have correct equality based on code', () {
      const tokyo1 = Prefecture(code: '13', name: '東京都');
      const tokyo2 = Prefecture(code: '13', name: '東京都');
      const osaka = Prefecture(code: '27', name: '大阪府');

      expect(tokyo1, equals(tokyo2));
      expect(tokyo1, isNot(equals(osaka)));
    });

    test('should have hashCode based on code and name', () {
      const tokyo1 = Prefecture(code: '13', name: '東京都');
      const tokyo2 = Prefecture(code: '13', name: '東京都');

      expect(tokyo1.hashCode, equals(tokyo2.hashCode));
    });
  });

  group('City', () {
    test('should create a City with prefectureCode, code, and name', () {
      const city = City(
        prefectureCode: '13',
        code: '13101',
        name: '千代田区',
      );

      expect(city.prefectureCode, '13');
      expect(city.code, '13101');
      expect(city.name, '千代田区');
    });

    test('should have correct equality', () {
      const chiyoda1 = City(
        prefectureCode: '13',
        code: '13101',
        name: '千代田区',
      );
      const chiyoda2 = City(
        prefectureCode: '13',
        code: '13101',
        name: '千代田区',
      );
      const shinjuku = City(
        prefectureCode: '13',
        code: '13104',
        name: '新宿区',
      );

      expect(chiyoda1, equals(chiyoda2));
      expect(chiyoda1, isNot(equals(shinjuku)));
    });
  });

  group('AreaSelection', () {
    test('should create with only prefecture', () {
      const prefecture = Prefecture(code: '13', name: '東京都');
      const selection = AreaSelection(prefecture: prefecture);

      expect(selection.prefecture, prefecture);
      expect(selection.city, isNull);
      expect(selection.hasCity, isFalse);
    });

    test('should create with prefecture and city', () {
      const prefecture = Prefecture(code: '13', name: '東京都');
      const city = City(
        prefectureCode: '13',
        code: '13104',
        name: '新宿区',
      );
      const selection = AreaSelection(prefecture: prefecture, city: city);

      expect(selection.prefecture, prefecture);
      expect(selection.city, city);
      expect(selection.hasCity, isTrue);
    });

    test('toSearchAddress should return prefecture name when no city', () {
      const prefecture = Prefecture(code: '13', name: '東京都');
      const selection = AreaSelection(prefecture: prefecture);

      expect(selection.toSearchAddress(), '東京都');
    });

    test('toSearchAddress should return combined address when city exists', () {
      const prefecture = Prefecture(code: '13', name: '東京都');
      const city = City(
        prefectureCode: '13',
        code: '13104',
        name: '新宿区',
      );
      const selection = AreaSelection(prefecture: prefecture, city: city);

      expect(selection.toSearchAddress(), '東京都新宿区');
    });

    test('displayName should show appropriate label', () {
      const prefecture = Prefecture(code: '13', name: '東京都');
      const selectionPrefOnly = AreaSelection(prefecture: prefecture);

      const city = City(
        prefectureCode: '13',
        code: '13104',
        name: '新宿区',
      );
      const selectionWithCity =
          AreaSelection(prefecture: prefecture, city: city);

      expect(selectionPrefOnly.displayName, '東京都');
      expect(selectionWithCity.displayName, '東京都 新宿区');
    });
  });
}

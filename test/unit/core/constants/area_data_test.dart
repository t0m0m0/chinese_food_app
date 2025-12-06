import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/constants/area_data.dart';

void main() {
  group('AreaData', () {
    group('prefectures', () {
      test('should have 47 prefectures', () {
        expect(AreaData.prefectures.length, 47);
      });

      test('should have Tokyo at code 13', () {
        final tokyo = AreaData.prefectures.firstWhere((p) => p.code == '13');
        expect(tokyo.name, '東京都');
      });

      test('should have Osaka at code 27', () {
        final osaka = AreaData.prefectures.firstWhere((p) => p.code == '27');
        expect(osaka.name, '大阪府');
      });

      test('should have Hokkaido at code 01', () {
        final hokkaido = AreaData.prefectures.firstWhere((p) => p.code == '01');
        expect(hokkaido.name, '北海道');
      });

      test('should have Okinawa at code 47', () {
        final okinawa = AreaData.prefectures.firstWhere((p) => p.code == '47');
        expect(okinawa.name, '沖縄県');
      });
    });

    group('getCitiesForPrefecture', () {
      test('should return cities for Tokyo (13)', () {
        final tokyoCities = AreaData.getCitiesForPrefecture('13');

        expect(tokyoCities, isNotEmpty);
        expect(
            tokyoCities.every((city) => city.prefectureCode == '13'), isTrue);
      });

      test('should return empty list for invalid prefecture code', () {
        final cities = AreaData.getCitiesForPrefecture('99');
        expect(cities, isEmpty);
      });

      test('should include major cities for Tokyo', () {
        final tokyoCities = AreaData.getCitiesForPrefecture('13');
        final cityNames = tokyoCities.map((c) => c.name).toList();

        expect(cityNames, contains('新宿区'));
        expect(cityNames, contains('渋谷区'));
      });

      test('should include major cities for Osaka', () {
        final osakaCities = AreaData.getCitiesForPrefecture('27');
        final cityNames = osakaCities.map((c) => c.name).toList();

        expect(cityNames, contains('大阪市'));
      });
    });

    group('getPrefectureByCode', () {
      test('should return correct prefecture for valid code', () {
        final prefecture = AreaData.getPrefectureByCode('13');
        expect(prefecture, isNotNull);
        expect(prefecture!.name, '東京都');
      });

      test('should return null for invalid code', () {
        final prefecture = AreaData.getPrefectureByCode('99');
        expect(prefecture, isNull);
      });
    });

    group('prefecturesByRegion', () {
      test('should group prefectures by region', () {
        final regions = AreaData.prefecturesByRegion;

        expect(regions.containsKey('関東'), isTrue);
        expect(regions.containsKey('関西'), isTrue);
        expect(regions.containsKey('北海道・東北'), isTrue);
      });

      test('Kanto region should include Tokyo and surrounding prefectures', () {
        final kanto = AreaData.prefecturesByRegion['関東']!;
        final names = kanto.map((p) => p.name).toList();

        expect(names, contains('東京都'));
        expect(names, contains('神奈川県'));
        expect(names, contains('埼玉県'));
        expect(names, contains('千葉県'));
      });
    });
  });
}

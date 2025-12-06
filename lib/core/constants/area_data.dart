import '../../domain/entities/area.dart';

/// 日本の都道府県・市区町村データ
class AreaData {
  AreaData._();

  /// 全47都道府県
  static const List<Prefecture> prefectures = [
    // 北海道・東北
    Prefecture(code: '01', name: '北海道'),
    Prefecture(code: '02', name: '青森県'),
    Prefecture(code: '03', name: '岩手県'),
    Prefecture(code: '04', name: '宮城県'),
    Prefecture(code: '05', name: '秋田県'),
    Prefecture(code: '06', name: '山形県'),
    Prefecture(code: '07', name: '福島県'),
    // 関東
    Prefecture(code: '08', name: '茨城県'),
    Prefecture(code: '09', name: '栃木県'),
    Prefecture(code: '10', name: '群馬県'),
    Prefecture(code: '11', name: '埼玉県'),
    Prefecture(code: '12', name: '千葉県'),
    Prefecture(code: '13', name: '東京都'),
    Prefecture(code: '14', name: '神奈川県'),
    // 中部
    Prefecture(code: '15', name: '新潟県'),
    Prefecture(code: '16', name: '富山県'),
    Prefecture(code: '17', name: '石川県'),
    Prefecture(code: '18', name: '福井県'),
    Prefecture(code: '19', name: '山梨県'),
    Prefecture(code: '20', name: '長野県'),
    Prefecture(code: '21', name: '岐阜県'),
    Prefecture(code: '22', name: '静岡県'),
    Prefecture(code: '23', name: '愛知県'),
    // 近畿
    Prefecture(code: '24', name: '三重県'),
    Prefecture(code: '25', name: '滋賀県'),
    Prefecture(code: '26', name: '京都府'),
    Prefecture(code: '27', name: '大阪府'),
    Prefecture(code: '28', name: '兵庫県'),
    Prefecture(code: '29', name: '奈良県'),
    Prefecture(code: '30', name: '和歌山県'),
    // 中国
    Prefecture(code: '31', name: '鳥取県'),
    Prefecture(code: '32', name: '島根県'),
    Prefecture(code: '33', name: '岡山県'),
    Prefecture(code: '34', name: '広島県'),
    Prefecture(code: '35', name: '山口県'),
    // 四国
    Prefecture(code: '36', name: '徳島県'),
    Prefecture(code: '37', name: '香川県'),
    Prefecture(code: '38', name: '愛媛県'),
    Prefecture(code: '39', name: '高知県'),
    // 九州・沖縄
    Prefecture(code: '40', name: '福岡県'),
    Prefecture(code: '41', name: '佐賀県'),
    Prefecture(code: '42', name: '長崎県'),
    Prefecture(code: '43', name: '熊本県'),
    Prefecture(code: '44', name: '大分県'),
    Prefecture(code: '45', name: '宮崎県'),
    Prefecture(code: '46', name: '鹿児島県'),
    Prefecture(code: '47', name: '沖縄県'),
  ];

  /// 地域別都道府県マップ
  static final Map<String, List<Prefecture>> prefecturesByRegion = {
    '北海道・東北': prefectures.where((p) => int.parse(p.code) <= 7).toList(),
    '関東': prefectures.where((p) {
      final code = int.parse(p.code);
      return code >= 8 && code <= 14;
    }).toList(),
    '中部': prefectures.where((p) {
      final code = int.parse(p.code);
      return code >= 15 && code <= 23;
    }).toList(),
    '関西': prefectures.where((p) {
      final code = int.parse(p.code);
      return code >= 24 && code <= 30;
    }).toList(),
    '中国': prefectures.where((p) {
      final code = int.parse(p.code);
      return code >= 31 && code <= 35;
    }).toList(),
    '四国': prefectures.where((p) {
      final code = int.parse(p.code);
      return code >= 36 && code <= 39;
    }).toList(),
    '九州・沖縄': prefectures.where((p) {
      final code = int.parse(p.code);
      return code >= 40 && code <= 47;
    }).toList(),
  };

  /// 都道府県コードから都道府県を取得
  static Prefecture? getPrefectureByCode(String code) {
    try {
      return prefectures.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  /// 都道府県コードから市区町村リストを取得
  static List<City> getCitiesForPrefecture(String prefectureCode) {
    return _cityData[prefectureCode] ?? [];
  }

  /// 主要都市データ（都道府県コード -> 市区町村リスト）
  static final Map<String, List<City>> _cityData = {
    // 北海道
    '01': const [
      City(prefectureCode: '01', code: '01100', name: '札幌市'),
      City(prefectureCode: '01', code: '01202', name: '函館市'),
      City(prefectureCode: '01', code: '01203', name: '小樽市'),
      City(prefectureCode: '01', code: '01204', name: '旭川市'),
      City(prefectureCode: '01', code: '01205', name: '室蘭市'),
      City(prefectureCode: '01', code: '01206', name: '釧路市'),
    ],
    // 宮城県
    '04': const [
      City(prefectureCode: '04', code: '04100', name: '仙台市'),
      City(prefectureCode: '04', code: '04202', name: '石巻市'),
    ],
    // 埼玉県
    '11': const [
      City(prefectureCode: '11', code: '11100', name: 'さいたま市'),
      City(prefectureCode: '11', code: '11201', name: '川越市'),
      City(prefectureCode: '11', code: '11203', name: '川口市'),
      City(prefectureCode: '11', code: '11207', name: '所沢市'),
      City(prefectureCode: '11', code: '11221', name: '越谷市'),
      City(prefectureCode: '11', code: '11227', name: '草加市'),
    ],
    // 千葉県
    '12': const [
      City(prefectureCode: '12', code: '12100', name: '千葉市'),
      City(prefectureCode: '12', code: '12202', name: '銚子市'),
      City(prefectureCode: '12', code: '12203', name: '市川市'),
      City(prefectureCode: '12', code: '12204', name: '船橋市'),
      City(prefectureCode: '12', code: '12207', name: '松戸市'),
      City(prefectureCode: '12', code: '12210', name: '柏市'),
    ],
    // 東京都
    '13': const [
      City(prefectureCode: '13', code: '13101', name: '千代田区'),
      City(prefectureCode: '13', code: '13102', name: '中央区'),
      City(prefectureCode: '13', code: '13103', name: '港区'),
      City(prefectureCode: '13', code: '13104', name: '新宿区'),
      City(prefectureCode: '13', code: '13105', name: '文京区'),
      City(prefectureCode: '13', code: '13106', name: '台東区'),
      City(prefectureCode: '13', code: '13107', name: '墨田区'),
      City(prefectureCode: '13', code: '13108', name: '江東区'),
      City(prefectureCode: '13', code: '13109', name: '品川区'),
      City(prefectureCode: '13', code: '13110', name: '目黒区'),
      City(prefectureCode: '13', code: '13111', name: '大田区'),
      City(prefectureCode: '13', code: '13112', name: '世田谷区'),
      City(prefectureCode: '13', code: '13113', name: '渋谷区'),
      City(prefectureCode: '13', code: '13114', name: '中野区'),
      City(prefectureCode: '13', code: '13115', name: '杉並区'),
      City(prefectureCode: '13', code: '13116', name: '豊島区'),
      City(prefectureCode: '13', code: '13117', name: '北区'),
      City(prefectureCode: '13', code: '13118', name: '荒川区'),
      City(prefectureCode: '13', code: '13119', name: '板橋区'),
      City(prefectureCode: '13', code: '13120', name: '練馬区'),
      City(prefectureCode: '13', code: '13121', name: '足立区'),
      City(prefectureCode: '13', code: '13122', name: '葛飾区'),
      City(prefectureCode: '13', code: '13123', name: '江戸川区'),
      City(prefectureCode: '13', code: '13201', name: '八王子市'),
      City(prefectureCode: '13', code: '13202', name: '立川市'),
      City(prefectureCode: '13', code: '13203', name: '武蔵野市'),
      City(prefectureCode: '13', code: '13204', name: '三鷹市'),
      City(prefectureCode: '13', code: '13210', name: '町田市'),
    ],
    // 神奈川県
    '14': const [
      City(prefectureCode: '14', code: '14100', name: '横浜市'),
      City(prefectureCode: '14', code: '14130', name: '川崎市'),
      City(prefectureCode: '14', code: '14150', name: '相模原市'),
      City(prefectureCode: '14', code: '14201', name: '横須賀市'),
      City(prefectureCode: '14', code: '14204', name: '鎌倉市'),
      City(prefectureCode: '14', code: '14205', name: '藤沢市'),
    ],
    // 愛知県
    '23': const [
      City(prefectureCode: '23', code: '23100', name: '名古屋市'),
      City(prefectureCode: '23', code: '23201', name: '豊橋市'),
      City(prefectureCode: '23', code: '23202', name: '岡崎市'),
      City(prefectureCode: '23', code: '23211', name: '豊田市'),
    ],
    // 京都府
    '26': const [
      City(prefectureCode: '26', code: '26100', name: '京都市'),
      City(prefectureCode: '26', code: '26201', name: '福知山市'),
      City(prefectureCode: '26', code: '26204', name: '宇治市'),
    ],
    // 大阪府
    '27': const [
      City(prefectureCode: '27', code: '27100', name: '大阪市'),
      City(prefectureCode: '27', code: '27140', name: '堺市'),
      City(prefectureCode: '27', code: '27203', name: '豊中市'),
      City(prefectureCode: '27', code: '27204', name: '池田市'),
      City(prefectureCode: '27', code: '27205', name: '吹田市'),
      City(prefectureCode: '27', code: '27207', name: '高槻市'),
      City(prefectureCode: '27', code: '27212', name: '枚方市'),
    ],
    // 兵庫県
    '28': const [
      City(prefectureCode: '28', code: '28100', name: '神戸市'),
      City(prefectureCode: '28', code: '28201', name: '姫路市'),
      City(prefectureCode: '28', code: '28202', name: '尼崎市'),
      City(prefectureCode: '28', code: '28204', name: '西宮市'),
    ],
    // 広島県
    '34': const [
      City(prefectureCode: '34', code: '34100', name: '広島市'),
      City(prefectureCode: '34', code: '34202', name: '呉市'),
      City(prefectureCode: '34', code: '34207', name: '福山市'),
    ],
    // 福岡県
    '40': const [
      City(prefectureCode: '40', code: '40100', name: '北九州市'),
      City(prefectureCode: '40', code: '40130', name: '福岡市'),
      City(prefectureCode: '40', code: '40202', name: '大牟田市'),
      City(prefectureCode: '40', code: '40203', name: '久留米市'),
    ],
  };
}

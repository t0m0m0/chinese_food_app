import '../entities/store.dart';
import '../repositories/store_repository.dart';

/// サンプル店舗データの初期化を行うUsecase
///
/// アプリ初回起動時やデバッグ時に、
/// サンプルの中華料理店データをローカルデータベースに挿入する
class InitializeSampleStoresUsecase {
  final StoreRepository repository;

  InitializeSampleStoresUsecase(this.repository);

  /// サンプル店舗データをデータベースに初期化
  ///
  /// 既存の店舗データがない場合のみサンプルデータを追加する
  /// 戻り値: 追加されたサンプル店舗の数
  Future<int> execute() async {
    try {
      // 既存の店舗データを確認
      final existingStores = await repository.getAllStores();
      if (existingStores.isNotEmpty) {
        // 既にデータがある場合は何もしない
        return 0;
      }

      // サンプル店舗データを作成
      final sampleStores = _createSampleStores();

      // データベースに挿入
      for (final store in sampleStores) {
        await repository.insertStore(store);
      }

      return sampleStores.length;
    } catch (e) {
      throw Exception('サンプル店舗データの初期化に失敗しました: ${e.toString()}');
    }
  }

  /// サンプル店舗データを生成
  List<Store> _createSampleStores() {
    final now = DateTime.now();

    return [
      Store(
        id: 'sample_001',
        name: '中華料理 龍華楼',
        address: '東京都新宿区西新宿1-1-1',
        lat: 35.6917,
        lng: 139.7006,
        createdAt: now,
      ),
      Store(
        id: 'sample_002',
        name: '餃子の王将 渋谷店',
        address: '東京都渋谷区道玄坂2-2-2',
        lat: 35.6580,
        lng: 139.6982,
        createdAt: now,
      ),
      Store(
        id: 'sample_003',
        name: '町中華 味楽',
        address: '東京都世田谷区三軒茶屋3-3-3',
        lat: 35.6462,
        lng: 139.6703,
        createdAt: now,
      ),
      Store(
        id: 'sample_004',
        name: '中華料理 福来軒',
        address: '東京都台東区浅草4-4-4',
        lat: 35.7148,
        lng: 139.7967,
        createdAt: now,
      ),
      Store(
        id: 'sample_005',
        name: '麻婆豆腐専門店 四川',
        address: '東京都中央区銀座5-5-5',
        lat: 35.6722,
        lng: 139.7648,
        createdAt: now,
      ),
      Store(
        id: 'sample_006',
        name: '老舗中華 大陸',
        address: '東京都港区赤坂6-6-6',
        lat: 35.6743,
        lng: 139.7369,
        createdAt: now,
      ),
    ];
  }
}

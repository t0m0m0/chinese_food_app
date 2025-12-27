import 'package:flutter/material.dart';
import '../../core/config/search_config.dart';

/// 距離選択ウィジェット
///
/// Issue #117: スワイプ画面に距離設定UI追加機能
/// Issue #246: 検索範囲を50kmまで拡張
/// Material Design 3準拠の距離選択UI
class DistanceSelectorWidget extends StatefulWidget {
  final int selectedRange;
  final ValueChanged<int> onChanged;

  /// メートル単位で距離が変更された時のコールバック（広域検索対応）
  final ValueChanged<int>? onMetersChanged;

  const DistanceSelectorWidget({
    super.key,
    required this.selectedRange,
    required this.onChanged,
    this.onMetersChanged,
  });

  @override
  State<DistanceSelectorWidget> createState() => _DistanceSelectorWidgetState();
}

class _DistanceSelectorWidgetState extends State<DistanceSelectorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sliderAnimation;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _confirmController;
  late Animation<double> _confirmAnimation;

  /// スライダーの値（対数スケールのインデックス: 0-8）
  double _currentSliderValue = 2.0; // デフォルト1000m
  int _displayMeters = 1000;
  bool _isExpanded = false;

  /// 選択可能な距離値（対数スケール的に配置）
  static const List<int> _distanceSteps = [
    300, // index 0
    500, // index 1
    1000, // index 2
    2000, // index 3
    3000, // index 4
    5000, // index 5
    10000, // index 6
    20000, // index 7
    50000, // index 8
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sliderAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _confirmController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _confirmAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _confirmController,
      curve: Curves.elasticOut,
    ));

    // API rangeから表示用メートルを逆算
    _displayMeters = _rangeToDisplayMeters(widget.selectedRange);
    _currentSliderValue = _metersToSliderValue(_displayMeters);
    _animationController.forward();
  }

  @override
  void didUpdateWidget(DistanceSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRange != oldWidget.selectedRange) {
      final newMeters = _rangeToDisplayMeters(widget.selectedRange);
      if (newMeters != _displayMeters) {
        setState(() {
          _displayMeters = newMeters;
          _currentSliderValue = _metersToSliderValue(newMeters);
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _expandController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _sliderAnimation,
      builder: (context, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2.0 * _sliderAnimation.value,
          child: InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '検索範囲',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _confirmAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _formatDistance(_displayMeters),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.expand_more,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10.0,
                              pressedElevation: 8.0,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 20.0),
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor:
                                colorScheme.primary.withValues(alpha: 0.3),
                            thumbColor: colorScheme.primary,
                            overlayColor:
                                colorScheme.primary.withValues(alpha: 0.2),
                            valueIndicatorColor: colorScheme.inverseSurface,
                            valueIndicatorTextStyle: TextStyle(
                              color: colorScheme.onInverseSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Slider(
                            value: _currentSliderValue,
                            min: 0.0,
                            max: (_distanceSteps.length - 1).toDouble(),
                            divisions: _distanceSteps.length - 1,
                            label: _formatDistance(_displayMeters),
                            onChanged: (value) {
                              final index = value.round();
                              final meters = _distanceSteps[index];
                              setState(() {
                                _currentSliderValue = value;
                                _displayMeters = meters;
                              });
                            },
                            onChangeEnd: (value) {
                              final index = value.round();
                              final meters = _distanceSteps[index];
                              final range = _metersToApiRange(meters);
                              setState(() {
                                _currentSliderValue = index.toDouble();
                                _displayMeters = meters;
                              });
                              widget.onChanged(range);
                              // 広域検索用にメートル値も通知
                              widget.onMetersChanged?.call(meters);
                              // 距離変更確認のアニメーション再生
                              _confirmController.forward().then((_) {
                                _confirmController.reverse();
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '300m',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '50km',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        // 広域検索の注意書き
                        if (_displayMeters > SearchConfig.maxApiRadiusMeters)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: colorScheme.tertiary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '広域検索: 複数回のAPI検索を行います',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.tertiary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// メートル値をスライダー値（インデックス）に変換
  double _metersToSliderValue(int meters) {
    for (int i = 0; i < _distanceSteps.length; i++) {
      if (_distanceSteps[i] == meters) {
        return i.toDouble();
      }
    }
    // 見つからない場合は最も近い値を探す
    int closestIndex = 0;
    int closestDiff = (meters - _distanceSteps[0]).abs();
    for (int i = 1; i < _distanceSteps.length; i++) {
      final diff = (meters - _distanceSteps[i]).abs();
      if (diff < closestDiff) {
        closestDiff = diff;
        closestIndex = i;
      }
    }
    return closestIndex.toDouble();
  }

  /// 距離をフォーマットして表示
  String _formatDistance(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      // 整数の場合は小数点なし
      if (km == km.roundToDouble()) {
        return '${km.round()}km';
      }
      return '${km.toStringAsFixed(1)}km';
    }
    return '${meters}m';
  }

  /// ユーザー選択メートルをHotPepper API範囲にマッピング
  /// 3km超の場合は最大値5を返す（広域検索はUsecaseで処理）
  int _metersToApiRange(int meters) {
    if (meters <= 300) return 1;
    if (meters <= 500) return 2;
    if (meters <= 1000) return 3;
    if (meters <= 2000) return 4;
    return 5; // 3000m以上は全て5（広域検索はUsecaseで対応）
  }

  /// API範囲から表示用メートルを逆算（初期化・外部更新時用）
  int _rangeToDisplayMeters(int apiRange) {
    switch (apiRange) {
      case 1:
        return 300;
      case 2:
        return 500;
      case 3:
        return 1000;
      case 4:
        return 2000;
      case 5:
        return 3000;
      case 6:
        return 5000;
      case 7:
        return 10000;
      case 8:
        return 20000;
      case 9:
        return 50000;
      default:
        return 1000;
    }
  }
}

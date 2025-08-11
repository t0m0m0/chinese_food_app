import 'package:flutter/material.dart';

/// 距離選択ウィジェット
///
/// Issue #117: スワイプ画面に距離設定UI追加機能
/// Material Design 3準拠の距離選択UI
class DistanceSelectorWidget extends StatefulWidget {
  final int selectedRange;
  final ValueChanged<int> onChanged;

  const DistanceSelectorWidget({
    super.key,
    required this.selectedRange,
    required this.onChanged,
  });

  @override
  State<DistanceSelectorWidget> createState() => _DistanceSelectorWidgetState();
}

class _DistanceSelectorWidgetState extends State<DistanceSelectorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sliderAnimation;

  double _currentSliderValue = 1000.0;
  int _displayMeters = 1000;

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

    // API rangeから表示用メートルを逆算
    _displayMeters = _rangeToDisplayMeters(widget.selectedRange);
    _currentSliderValue = _displayMeters.toDouble();
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
          _currentSliderValue = newMeters.toDouble();
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_displayMeters}m',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10.0,
                      pressedElevation: 8.0,
                    ),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 20.0),
                    activeTrackColor: colorScheme.primary,
                    inactiveTrackColor:
                        colorScheme.primary.withValues(alpha: 0.3),
                    thumbColor: colorScheme.primary,
                    overlayColor: colorScheme.primary.withValues(alpha: 0.2),
                    valueIndicatorColor: colorScheme.inverseSurface,
                    valueIndicatorTextStyle: TextStyle(
                      color: colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Slider(
                    value: _currentSliderValue,
                    min: 300.0,
                    max: 3000.0,
                    divisions: 27, // 100m刻みで滑らかな操作 (3000-300)/100 = 27
                    label: '${_displayMeters}m',
                    onChanged: (value) {
                      final roundedValue =
                          (value / 100).round() * 100; // 100m単位に丸める
                      setState(() {
                        _currentSliderValue = roundedValue.toDouble();
                        _displayMeters = roundedValue;
                      });
                    },
                    onChangeEnd: (value) {
                      final finalMeters = (value / 100).round() * 100;
                      final range = _metersToApiRange(finalMeters);
                      setState(() {
                        _currentSliderValue = finalMeters.toDouble();
                        _displayMeters = finalMeters;
                      });
                      widget.onChanged(range);
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
                      '3000m',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // API範囲の説明表示
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '実際の検索: ${_getApiRangeDescription(_metersToApiRange(_displayMeters))}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ユーザー選択メートルをHotPepper API範囲にマッピング
  int _metersToApiRange(int meters) {
    if (meters <= 399) return 1; // 300-399m → 300m API
    if (meters <= 749) return 2; // 400-749m → 500m API
    if (meters <= 1499) return 3; // 750-1499m → 1000m API
    if (meters <= 2499) return 4; // 1500-2499m → 2000m API
    return 5; // 2500-3000m → 3000m API
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
      default:
        return 1000;
    }
  }

  /// 検索範囲の説明を取得
  String _getApiRangeDescription(int apiRange) {
    switch (apiRange) {
      case 1:
        return '300m以内';
      case 2:
        return '500m以内';
      case 3:
        return '1000m以内';
      case 4:
        return '2000m以内';
      case 5:
        return '3000m以内';
      default:
        return '1000m以内';
    }
  }
}

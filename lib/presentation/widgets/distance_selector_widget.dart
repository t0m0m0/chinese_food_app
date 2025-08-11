import 'package:flutter/material.dart';
import '../../core/config/search_config.dart';

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

    _currentSliderValue =
        (SearchConfig.rangeToMeter(widget.selectedRange) ?? 1000).toDouble();
    _displayMeters = _currentSliderValue.round();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(DistanceSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRange != oldWidget.selectedRange) {
      final newValue =
          (SearchConfig.rangeToMeter(widget.selectedRange) ?? 1000).toDouble();
      if (newValue != _currentSliderValue) {
        setState(() {
          _currentSliderValue = newValue;
          _displayMeters = newValue.round();
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
                    inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.3),
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
                    divisions: 27, // より細かい分割で滑らか操作
                    label: '${_displayMeters}m',
                    onChanged: (value) {
                      setState(() {
                        _currentSliderValue = value;
                        _displayMeters = _snapToValidValue(value);
                      });
                    },
                    onChangeEnd: (value) {
                      final snappedMeters = _snapToValidValue(value);
                      final range = _metersToRange(snappedMeters);
                      setState(() {
                        _currentSliderValue = snappedMeters.toDouble();
                        _displayMeters = snappedMeters;
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
              ],
            ),
          ),
        );
      },
    );
  }

  int _snapToValidValue(double value) {
    final ranges = [300, 500, 1000, 2000, 3000];
    int closest = ranges.first;
    double minDistance = (value - ranges.first).abs();

    for (final range in ranges) {
      final distance = (value - range).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closest = range;
      }
    }

    return closest;
  }

  int _metersToRange(int meters) {
    switch (meters) {
      case 300:
        return 1;
      case 500:
        return 2;
      case 1000:
        return 3;
      case 2000:
        return 4;
      case 3000:
        return 5;
      default:
        return 3;
    }
  }
}

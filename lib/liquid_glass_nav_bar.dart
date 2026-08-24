import 'package:flutter/material.dart';
import 'package:liquid_glass_bar/liquid_glass_bar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A liquid-glass bottom navigation bar.
///
/// This mirrors `liquid_glass_bar`'s [LiquidGlassBar] (same drag/selection
/// behavior and the same [LiquidGlassBarItem]/[LiquidGlassBarStyle] data
/// types), but forks its rendering: the upstream widget hardcodes a white
/// rim border and highlight gradient regardless of theme, which reads as a
/// bright light pill even over a dark glass fill. [isDark] swaps those for a
/// dark-appropriate rim and glow instead.
class LiquidGlassNavBar extends StatefulWidget {
  const LiquidGlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    this.style,
  });

  final List<LiquidGlassBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final LiquidGlassBarStyle? style;

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> {
  double? _dragAlignment;
  bool _isDragging = false;
  int? _highlightedIndex;

  LiquidGlassBarStyle get _style => widget.style ?? const LiquidGlassBarStyle();
  int get _lastIndex => widget.items.length - 1;

  double _getAlignment(int index) {
    if (_lastIndex == 0) return 0.0;
    return -1.0 + (index * 2 / _lastIndex);
  }

  void _updateHighlightedIndex() {
    if (!_isDragging || _dragAlignment == null) {
      _highlightedIndex = null;
      return;
    }
    final normalized = (_dragAlignment! + 1) / 2;
    final index = (normalized * _lastIndex).round();
    _highlightedIndex = index.clamp(0, _lastIndex);
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final itemCount = widget.items.length;
    final rimColor = widget.isDark
        ? Colors.black.withValues(alpha: 0.5)
        : const Color(0xE6FFFFFF);
    final indicatorGradient = widget.isDark
        ? [
            style.activeColor.withValues(alpha: 0.28),
            style.activeColor.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.35),
          ]
        : [
            style.activeColor.withValues(alpha: 0.15),
            const Color(0x4DFFFFFF),
            const Color(0x1AFFFFFF),
          ];
    final indicatorBorder = widget.isDark
        ? style.activeColor.withValues(alpha: 0.45)
        : const Color(0x99FFFFFF);
    final indicatorInnerShadow = widget.isDark
        ? Colors.black.withValues(alpha: 0.4)
        : const Color(0xCCFFFFFF);

    return Container(
      padding: style.padding,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(style.borderRadius),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                    spreadRadius: -5,
                  ),
                ],
              ),
            ),
          ),
          LiquidGlass.withOwnLayer(
            shape: LiquidRoundedRectangle(borderRadius: style.borderRadius),
            settings: style.liquidGlassSettings ??
                const LiquidGlassSettings(
                  thickness: 20.0,
                  blur: 16.0,
                  glassColor: Color(0xCCFFFFFF),
                  lightIntensity: 0.6,
                  refractiveIndex: 1.5,
                ),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / itemCount;
                  final totalDragWidth = constraints.maxWidth - itemWidth;

                  return GestureDetector(
                    onHorizontalDragStart: (details) {
                      setState(() {
                        _isDragging = true;
                        _dragAlignment = _getAlignment(widget.currentIndex);
                        _updateHighlightedIndex();
                      });
                    },
                    onHorizontalDragUpdate: (details) {
                      if (!_isDragging) return;
                      setState(() {
                        final deltaAlignment =
                            (details.primaryDelta! / totalDragWidth) * 2.0;
                        _dragAlignment =
                            (_dragAlignment! + deltaAlignment).clamp(-1.0, 1.0);
                        _updateHighlightedIndex();
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      setState(() {
                        _isDragging = false;
                        _highlightedIndex = null;
                        final normalized = (_dragAlignment! + 1) / 2;
                        final nearestIndex = (normalized * _lastIndex).round();
                        widget.onTap(nearestIndex);
                      });
                    },
                    onHorizontalDragCancel: () {
                      setState(() {
                        _isDragging = false;
                        _highlightedIndex = null;
                      });
                    },
                    child: SizedBox(
                      height: style.height,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedAlign(
                            duration: _isDragging
                                ? Duration.zero
                                : style.animationDuration,
                            curve: style.animationCurve,
                            alignment: Alignment(
                              _isDragging
                                  ? _dragAlignment!
                                  : _getAlignment(widget.currentIndex),
                              0,
                            ),
                            child: Container(
                              width: itemWidth,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: indicatorGradient,
                                  stops: const [0.0, 0.4, 1.0],
                                ),
                                border: Border.all(
                                  color: indicatorBorder,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: style.activeColor
                                        .withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: indicatorInnerShadow,
                                    blurRadius: 8,
                                    offset: const Offset(-2, -2),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (int i = 0; i < itemCount; i++)
                                _NavBarItem(
                                  item: widget.items[i],
                                  isSelected: widget.currentIndex == i,
                                  isHighlighted: _highlightedIndex == i,
                                  onTap: () => widget.onTap(i),
                                  style: style,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(style.borderRadius),
                  border: Border.all(color: rimColor, width: 2.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.isHighlighted,
    required this.onTap,
    required this.style,
  });

  final LiquidGlassBarItem item;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback onTap;
  final LiquidGlassBarStyle style;

  @override
  Widget build(BuildContext context) {
    final isActive = isSelected || isHighlighted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? style.selectedIconScale : 1.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                child: _buildIcon(isActive),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: SizedBox(
                  height: isSelected ? 0 : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: isSelected ? 0.0 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: AnimatedDefaultTextStyle(
                        duration: style.animationDuration,
                        curve: style.animationCurve,
                        style: style.labelStyle ??
                            TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              height: 16 / 10,
                              color:
                                  isActive ? style.activeColor : style.inactiveColor,
                            ),
                        child: Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isActive) {
    return TweenAnimationBuilder<Color?>(
      duration: style.animationDuration,
      curve: style.animationCurve,
      tween: ColorTween(
        begin: style.inactiveColor,
        end: isActive ? style.activeColor : style.inactiveColor,
      ),
      builder: (context, color, child) {
        return Icon(item.iconData, size: style.iconSize, color: color);
      },
    );
  }
}

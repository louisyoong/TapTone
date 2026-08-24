import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

/// A 10-question color vision screening test inspired by Ishihara plates.
///
/// Every plate is generated on-device as a mosaic of colored dots (no
/// bundled image assets): a digit is rasterized to a mask, then dots are
/// scattered inside a circle and colored from a "figure" or "background"
/// palette depending on whether they fall inside the digit's shape.
class ColorTestScreen extends StatefulWidget {
  const ColorTestScreen({super.key});

  @override
  State<ColorTestScreen> createState() => _ColorTestScreenState();
}

enum _TestPhase { intro, quiz, result }

class _PalettePair {
  const _PalettePair(this.figure, this.background);
  final List<Color> figure;
  final List<Color> background;
}

class _PlateSpec {
  const _PlateSpec(this.digits, this.answer, this.palette);
  final String digits;
  final int answer;
  final _PalettePair palette;
}

class _Dot {
  const _Dot(this.center, this.radius, this.color);
  final Offset center;
  final double radius;
  final Color color;
}

const double _plateSize = 300;

// Orange figure on olive-green background: a classic red-green confusion
// pair, matched in lightness so only hue separates figure from ground.
const _redOnGreen = _PalettePair(
  [Color(0xFFE06B3E), Color(0xFFD9622F), Color(0xFFEB8156), Color(0xFFC85A2C)],
  [Color(0xFF8FA84C), Color(0xFF7C9A3E), Color(0xFFA3B860), Color(0xFF6F8C35)],
);

const _greenOnRed = _PalettePair(
  [Color(0xFF8FA84C), Color(0xFF7C9A3E), Color(0xFFA3B860), Color(0xFF6F8C35)],
  [Color(0xFFE06B3E), Color(0xFFD9622F), Color(0xFFEB8156), Color(0xFFC85A2C)],
);

// High lightness contrast so everyone (including color-blind viewers) can
// read it -- used as the warm-up "demonstration" plate.
const _control = _PalettePair(
  [Color(0xFF6D4C2E), Color(0xFF5B3E24), Color(0xFF7E5735)],
  [Color(0xFFE7C89A), Color(0xFFDFBB84), Color(0xFFEFD3A8)],
);

final List<_PlateSpec> _plates = [
  const _PlateSpec('12', 12, _control),
  const _PlateSpec('8', 8, _redOnGreen),
  const _PlateSpec('29', 29, _greenOnRed),
  const _PlateSpec('5', 5, _redOnGreen),
  const _PlateSpec('3', 3, _greenOnRed),
  const _PlateSpec('15', 15, _redOnGreen),
  const _PlateSpec('74', 74, _greenOnRed),
  const _PlateSpec('6', 6, _redOnGreen),
  const _PlateSpec('45', 45, _greenOnRed),
  const _PlateSpec('97', 97, _redOnGreen),
];

Future<List<_Dot>> _generatePlateDots(_PlateSpec spec, int seed) async {
  const size = _plateSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
  final fontSize = spec.digits.length > 1 ? size * 0.5 : size * 0.62;
  final textPainter = TextPainter(
    text: TextSpan(
      text: spec.digits,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: const Color(0xFFFFFFFF),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final mask = byteData!.buffer.asUint8List();

  bool isInsideDigit(int x, int y) {
    if (x < 0 || y < 0 || x >= size || y >= size) return false;
    return mask[(y * size.toInt() + x) * 4 + 3] > 120;
  }

  final random = math.Random(seed);
  const center = Offset(size / 2, size / 2);
  const radius = size / 2 - 6;
  const cellSize = 12.0;

  final dots = <_Dot>[];
  final grid = <String, List<Offset>>{};

  bool overlapsExisting(Offset point, double dotRadius) {
    final cellX = (point.dx / cellSize).floor();
    final cellY = (point.dy / cellSize).floor();
    for (var gx = cellX - 1; gx <= cellX + 1; gx++) {
      for (var gy = cellY - 1; gy <= cellY + 1; gy++) {
        final neighbors = grid['$gx,$gy'];
        if (neighbors == null) continue;
        for (final existing in neighbors) {
          if ((existing - point).distance < dotRadius + 4.2) return true;
        }
      }
    }
    return false;
  }

  var attempts = 0;
  while (dots.length < 1300 && attempts < 18000) {
    attempts++;
    final angle = random.nextDouble() * 2 * math.pi;
    final distance = radius * math.sqrt(random.nextDouble());
    final point = Offset(
      center.dx + distance * math.cos(angle),
      center.dy + distance * math.sin(angle),
    );
    final dotRadius = 2.6 + random.nextDouble() * 3.4;
    if ((point - center).distance + dotRadius > radius) continue;
    if (overlapsExisting(point, dotRadius)) continue;

    final palette = isInsideDigit(point.dx.round(), point.dy.round())
        ? spec.palette.figure
        : spec.palette.background;
    final base = palette[random.nextInt(palette.length)];
    final jitter = (random.nextDouble() - 0.5) * 0.08;
    final color = HSLColor.fromColor(base)
        .withLightness((HSLColor.fromColor(base).lightness + jitter).clamp(0.2, 0.85))
        .toColor();

    dots.add(_Dot(point, dotRadius, color));
    final cellX = (point.dx / cellSize).floor();
    final cellY = (point.dy / cellSize).floor();
    grid.putIfAbsent('$cellX,$cellY', () => []).add(point);
  }

  return dots;
}

class _IshiharaPainter extends CustomPainter {
  const _IshiharaPainter(this.dots);
  final List<_Dot> dots;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final dot in dots) {
      paint.color = dot.color;
      canvas.drawCircle(dot.center, dot.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _IshiharaPainter oldDelegate) =>
      oldDelegate.dots != dots;
}

class _ColorTestScreenState extends State<ColorTestScreen> {
  _TestPhase _phase = _TestPhase.intro;
  int _index = 0;
  final List<int?> _answers = List<int?>.filled(_plates.length, null);
  final TextEditingController _controller = TextEditingController();
  final Map<int, List<_Dot>> _dotCache = {};
  bool _cantSee = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<_Dot>> _dotsFor(int index) {
    final cached = _dotCache[index];
    if (cached != null) return Future.value(cached);
    return _generatePlateDots(_plates[index], index * 7919 + 13).then((dots) {
      _dotCache[index] = dots;
      return dots;
    });
  }

  void _start() => setState(() => _phase = _TestPhase.quiz);

  void _setCantSee(bool value) {
    setState(() {
      _cantSee = value;
      if (value) _controller.clear();
    });
  }

  void _submit() {
    final value = _cantSee ? null : int.tryParse(_controller.text.trim());
    _answers[_index] = value;
    _controller.clear();
    final isLast = _index == _plates.length - 1;
    setState(() {
      _cantSee = false;
      if (isLast) {
        _phase = _TestPhase.result;
      } else {
        _index++;
      }
    });
  }

  void _retake() {
    setState(() {
      _phase = _TestPhase.intro;
      _index = 0;
      _answers.fillRange(0, _answers.length, null);
      _controller.clear();
      _cantSee = false;
      _dotCache.clear();
    });
  }

  int get _correctCount {
    var count = 0;
    for (var i = 0; i < _plates.length; i++) {
      if (_answers[i] == _plates[i].answer) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _TestPhase.intro => _IntroView(onStart: _start),
      _TestPhase.quiz => _QuizView(
          index: _index,
          total: _plates.length,
          dotsFuture: _dotsFor(_index),
          controller: _controller,
          cantSee: _cantSee,
          onCantSeeChanged: _setCantSee,
          onSubmit: _submit,
        ),
      _TestPhase.result => _ResultView(
          correct: _correctCount,
          total: _plates.length,
          onRetake: _retake,
        ),
    };
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = ThemeSettingsScope.of(context).strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Icon(
                    Icons.quiz_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.t('colorTest.intro.title'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.t('colorTest.intro.text'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.t('colorTest.intro.disclaimer'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(strings.t('colorTest.start')),
          ),
        ],
      ),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView({
    required this.index,
    required this.total,
    required this.dotsFuture,
    required this.controller,
    required this.cantSee,
    required this.onCantSeeChanged,
    required this.onSubmit,
  });

  final int index;
  final int total;
  final Future<List<_Dot>> dotsFuture;
  final TextEditingController controller;
  final bool cantSee;
  final ValueChanged<bool> onCantSeeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = ThemeSettingsScope.of(context).strings;
    final canSubmit = cantSee || controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: index / total, minHeight: 8),
                ),
              ),
              const SizedBox(width: 10),
              Text('${index + 1}/$total', style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: FutureBuilder<List<_Dot>>(
                future: dotsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: CustomPaint(
                        size: const Size(_plateSize, _plateSize),
                        painter: _IshiharaPainter(snapshot.data!),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(strings.t('colorTest.prompt'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            enabled: !cantSee,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              hintText: strings.t('colorTest.inputHint'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => onCantSeeChanged(!cantSee),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: cantSee,
                      onChanged: (value) => onCantSeeChanged(value ?? false),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(strings.t('colorTest.cantSee'), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              child: Text(
                index == total - 1
                    ? strings.t('colorTest.finish')
                    : strings.t('colorTest.next'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.correct,
    required this.total,
    required this.onRetake,
  });

  final int correct;
  final int total;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = ThemeSettingsScope.of(context).strings;
    final percentage = ((correct / total) * 100).round();
    final messageKey = percentage >= 90
        ? 'colorTest.result.good'
        : percentage >= 70
            ? 'colorTest.result.moderate'
            : 'colorTest.result.poor';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    strings.t('colorTest.resultTitle'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: correct / total,
                            strokeWidth: 12,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings
                        .t('colorTest.scoreCorrect')
                        .replaceFirst('{n}', '$correct')
                        .replaceFirst('{total}', '$total'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        strings.t(messageKey),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.t('colorTest.intro.disclaimer'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetake,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.t('colorTest.retake')),
          ),
        ],
      ),
    );
  }
}

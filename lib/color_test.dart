import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

/// Color vision screening, inspired by Ishihara plates.
///
/// Two tests are offered from a mode-selection screen: a 10-question number
/// test for teens/adults, and a 10-question animal test for kids. Every
/// plate is generated on-device as a mosaic of colored dots (no bundled
/// image assets): a digit or animal emoji is rasterized to a mask, then dots
/// are scattered inside a circle and colored from a "figure" or "background"
/// palette depending on whether they fall inside the glyph's shape.
class ColorTestScreen extends StatefulWidget {
  const ColorTestScreen({super.key});

  @override
  State<ColorTestScreen> createState() => _ColorTestScreenState();
}

enum _RootMode { select, adult, kid }

class _ColorTestScreenState extends State<ColorTestScreen> {
  _RootMode _mode = _RootMode.select;

  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      _RootMode.select => _ModeSelectionView(
          onSelectAdult: () => setState(() => _mode = _RootMode.adult),
          onSelectKid: () => setState(() => _mode = _RootMode.kid),
        ),
      _RootMode.adult => _AdultColorTest(
          onBack: () => setState(() => _mode = _RootMode.select),
        ),
      _RootMode.kid => _KidColorTest(
          onBack: () => setState(() => _mode = _RootMode.select),
        ),
    };
  }
}

class _ModeSelectionView extends StatelessWidget {
  const _ModeSelectionView({
    required this.onSelectAdult,
    required this.onSelectKid,
  });

  final VoidCallback onSelectAdult;
  final VoidCallback onSelectKid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = ThemeSettingsScope.of(context).strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.t('colorTest.mode.title'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _ModeCard(
                    badge: _testGlyphBadge(digit: true),
                    title: strings.t('colorTest.mode.adultTitle'),
                    description: strings.t('colorTest.mode.adultDesc'),
                    onTap: onSelectAdult,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _ModeCard(
                    badge: _testGlyphBadge(digit: false),
                    title: strings.t('colorTest.mode.kidTitle'),
                    description: strings.t('colorTest.mode.kidDesc'),
                    onTap: onSelectKid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// The mode/intro badges are tiny real dot-mosaic plates (same generator as
// the actual quiz), so the icon *is* a miniature version of the test rather
// than a generic symbol. Generated once and cached for the app session.
Future<List<_Dot>>? _adultBadgeDotsFuture;
Future<List<_Dot>> get _adultBadgeDots => _adultBadgeDotsFuture ??=
    _generateDotsForGlyph('8', _plateSize * 0.62, _control, 4242);

Future<List<_Dot>>? _kidBadgeDotsFuture;
Future<List<_Dot>> get _kidBadgeDots => _kidBadgeDotsFuture ??=
    _generateDotsForGlyph('🐟', _plateSize * 0.72, _control, 8484);

Widget _testGlyphBadge({required bool digit, double size = 56}) {
  return _TestBadgePlate(
    dotsFuture: digit ? _adultBadgeDots : _kidBadgeDots,
    size: size,
  );
}

class _TestBadgePlate extends StatelessWidget {
  const _TestBadgePlate({required this.dotsFuture, this.size = 56});

  final Future<List<_Dot>> dotsFuture;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<List<_Dot>>(
        future: dotsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            );
          }
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FittedBox(
              child: SizedBox(
                width: _plateSize,
                height: _plateSize,
                child: CustomPaint(painter: _IshiharaPainter(snapshot.data!)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.badge,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final Widget badge;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              badge,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
        ),
      ),
    );
  }
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

class _KidAnimal {
  const _KidAnimal(this.id, this.emoji);
  final String id;
  final String emoji;
}

class _KidPlateSpec {
  const _KidPlateSpec(this.animalIndex, this.palette);
  final int animalIndex;
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

// Order matches the option icons kids will tap, so distractors always
// come from this same well-known set of ten silhouettes.
const List<_KidAnimal> _kidAnimals = [
  _KidAnimal('butterfly', '🦋'),
  _KidAnimal('dolphin', '🐬'),
  _KidAnimal('cow', '🐄'),
  _KidAnimal('giraffe', '🦒'),
  _KidAnimal('duck', '🦆'),
  _KidAnimal('snail', '🐌'),
  _KidAnimal('elephant', '🐘'),
  _KidAnimal('fish', '🐟'),
  _KidAnimal('kangaroo', '🦘'),
  _KidAnimal('rabbit', '🐰'),
];

final List<_KidPlateSpec> _kidPlates = [
  const _KidPlateSpec(7, _control),
  const _KidPlateSpec(0, _redOnGreen),
  const _KidPlateSpec(1, _greenOnRed),
  const _KidPlateSpec(2, _redOnGreen),
  const _KidPlateSpec(3, _greenOnRed),
  const _KidPlateSpec(4, _redOnGreen),
  const _KidPlateSpec(5, _greenOnRed),
  const _KidPlateSpec(6, _redOnGreen),
  const _KidPlateSpec(8, _greenOnRed),
  const _KidPlateSpec(9, _redOnGreen),
];

Future<List<_Dot>> _generateDotsForGlyph(
  String glyph,
  double fontSize,
  _PalettePair palette,
  int seed,
) async {
  const size = _plateSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
  final textPainter = TextPainter(
    text: TextSpan(
      text: glyph,
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

  bool isInsideGlyph(int x, int y) {
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

    final swatch = isInsideGlyph(point.dx.round(), point.dy.round())
        ? palette.figure
        : palette.background;
    final base = swatch[random.nextInt(swatch.length)];
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

Future<List<_Dot>> _generatePlateDots(_PlateSpec spec, int seed) {
  final fontSize = spec.digits.length > 1 ? _plateSize * 0.5 : _plateSize * 0.62;
  return _generateDotsForGlyph(spec.digits, fontSize, spec.palette, seed);
}

Future<List<_Dot>> _generateAnimalPlateDots(_KidPlateSpec spec, int seed) {
  final emoji = _kidAnimals[spec.animalIndex].emoji;
  return _generateDotsForGlyph(emoji, _plateSize * 0.72, spec.palette, seed);
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

class _PlateCard extends StatelessWidget {
  const _PlateCard({required this.dotsFuture, required this.size});

  final Future<List<_Dot>> dotsFuture;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<List<_Dot>>(
        future: dotsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: FittedBox(
                child: SizedBox(
                  width: _plateSize,
                  height: _plateSize,
                  child: CustomPaint(
                    painter: _IshiharaPainter(snapshot.data!),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdultColorTest extends StatefulWidget {
  const _AdultColorTest({required this.onBack});
  final VoidCallback onBack;

  @override
  State<_AdultColorTest> createState() => _AdultColorTestState();
}

class _AdultColorTestState extends State<_AdultColorTest> {
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
    final strings = ThemeSettingsScope.of(context).strings;
    return Column(
      children: [
        _BackBar(onBack: widget.onBack),
        Expanded(
          child: switch (_phase) {
            _TestPhase.intro => _IntroView(
                onStart: _start,
                icon: _testGlyphBadge(digit: true, size: 100),
                title: strings.t('colorTest.intro.title'),
                text: strings.t('colorTest.intro.text'),
                disclaimer: strings.t('colorTest.intro.disclaimer'),
                startLabel: strings.t('colorTest.start'),
              ),
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
          },
        ),
      ],
    );
  }
}

class _KidColorTest extends StatefulWidget {
  const _KidColorTest({required this.onBack});
  final VoidCallback onBack;

  @override
  State<_KidColorTest> createState() => _KidColorTestState();
}

class _KidColorTestState extends State<_KidColorTest> {
  _TestPhase _phase = _TestPhase.intro;
  int _index = 0;
  final List<bool> _correctAnswers = List<bool>.filled(_kidPlates.length, false);
  final Map<int, List<_Dot>> _dotCache = {};
  final Map<int, List<int>> _optionsCache = {};

  Future<List<_Dot>> _dotsFor(int index) {
    final cached = _dotCache[index];
    if (cached != null) return Future.value(cached);
    return _generateAnimalPlateDots(_kidPlates[index], index * 6151 + 17).then((dots) {
      _dotCache[index] = dots;
      return dots;
    });
  }

  List<int> _optionsFor(int index) {
    return _optionsCache.putIfAbsent(index, () {
      final spec = _kidPlates[index];
      final random = math.Random(index * 97 + 3);
      final others = List<int>.generate(_kidAnimals.length, (i) => i)
        ..remove(spec.animalIndex);
      others.shuffle(random);
      final options = [spec.animalIndex, ...others.take(3)];
      options.shuffle(random);
      return options;
    });
  }

  void _start() => setState(() => _phase = _TestPhase.quiz);

  void _select(int animalIndex) {
    final spec = _kidPlates[_index];
    _correctAnswers[_index] = animalIndex == spec.animalIndex;
    final isLast = _index == _kidPlates.length - 1;
    setState(() {
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
      _correctAnswers.fillRange(0, _correctAnswers.length, false);
      _dotCache.clear();
      _optionsCache.clear();
    });
  }

  int get _correctCount => _correctAnswers.where((c) => c).length;

  @override
  Widget build(BuildContext context) {
    final strings = ThemeSettingsScope.of(context).strings;
    return Column(
      children: [
        _BackBar(onBack: widget.onBack),
        Expanded(
          child: switch (_phase) {
            _TestPhase.intro => _IntroView(
                onStart: _start,
                icon: _testGlyphBadge(digit: false, size: 100),
                title: strings.t('colorTest.kid.intro.title'),
                text: strings.t('colorTest.kid.intro.text'),
                disclaimer: strings.t('colorTest.intro.disclaimer'),
                startLabel: strings.t('colorTest.start'),
              ),
            _TestPhase.quiz => _KidQuizView(
                index: _index,
                total: _kidPlates.length,
                dotsFuture: _dotsFor(_index),
                options: _optionsFor(_index),
                onSelect: _select,
              ),
            _TestPhase.result => _ResultView(
                correct: _correctCount,
                total: _kidPlates.length,
                onRetake: _retake,
              ),
          },
        ),
      ],
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({
    required this.onStart,
    required this.icon,
    required this.title,
    required this.text,
    required this.disclaimer,
    required this.startLabel,
  });

  final VoidCallback onStart;
  final Widget icon;
  final String title;
  final String text;
  final String disclaimer;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  icon,
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
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
                              disclaimer,
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
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                startLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
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
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final plateSize = math.min(
              constraints.maxWidth - 20,
              keyboardVisible ? 160.0 : 300.0,
            );
            return SingleChildScrollView(
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
                  SizedBox(height: keyboardVisible ? 10 : 18),
                  Center(child: _PlateCard(dotsFuture: dotsFuture, size: plateSize)),
                  SizedBox(height: keyboardVisible ? 10 : 16),
                  Text(strings.t('colorTest.prompt'), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    enabled: !cantSee,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      hintText: strings.t('colorTest.inputHint'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      suffixIcon: keyboardVisible
                          ? IconButton(
                              icon: const Icon(Icons.keyboard_hide_rounded),
                              tooltip: strings.t('colorTest.hideKeyboard'),
                              onPressed: () => FocusScope.of(context).unfocus(),
                            )
                          : null,
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
                    height: 52,
                    child: FilledButton(
                      onPressed: canSubmit ? onSubmit : null,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        index == total - 1
                            ? strings.t('colorTest.finish')
                            : strings.t('colorTest.next'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KidQuizView extends StatelessWidget {
  const _KidQuizView({
    required this.index,
    required this.total,
    required this.dotsFuture,
    required this.options,
    required this.onSelect,
  });

  final int index;
  final int total;
  final Future<List<_Dot>> dotsFuture;
  final List<int> options;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = ThemeSettingsScope.of(context).strings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plateSize = math.min(constraints.maxWidth - 20, 260.0);
          return SingleChildScrollView(
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
                Center(child: _PlateCard(dotsFuture: dotsFuture, size: plateSize)),
                const SizedBox(height: 16),
                Text(strings.t('colorTest.kid.prompt'), style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.3,
                  children: [
                    for (final (i, animalIndex) in options.indexed)
                      _AnimalOptionButton(
                        animal: _kidAnimals[animalIndex],
                        color: _kidOptionColors(theme)[i % 4],
                        onTap: () => onSelect(animalIndex),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

List<Color> _kidOptionColors(ThemeData theme) => [
      theme.colorScheme.primaryContainer,
      theme.colorScheme.tertiaryContainer,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.surfaceContainerHigh,
    ];

class _AnimalOptionButton extends StatelessWidget {
  const _AnimalOptionButton({
    required this.animal,
    required this.color,
    required this.onTap,
  });

  final _KidAnimal animal;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = ThemeSettingsScope.of(context).strings;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(animal.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  strings.t('animal.${animal.id}'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
    final (resultColor, resultIcon) = switch (messageKey) {
      'colorTest.result.good' => (const Color(0xFF2E7D32), Icons.check_circle_rounded),
      'colorTest.result.moderate' => (const Color(0xFFF9A825), Icons.info_rounded),
      _ => (theme.colorScheme.error, Icons.error_rounded),
    };

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
                            strokeCap: StrokeCap.round,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(resultColor),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: resultColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(resultIcon, color: resultColor, size: 26),
                        const SizedBox(height: 8),
                        Text(
                          strings.t(messageKey),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onRetake,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                strings.t('colorTest.retake'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

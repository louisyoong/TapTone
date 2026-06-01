import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ColorAssistApp());
}

class ColorAssistApp extends StatelessWidget {
  const ColorAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapTone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF126A63),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(fontSize: 16, height: 1.35),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE2EAE7)),
          ),
        ),
        useMaterial3: true,
      ),
      home: const OnboardingGate(),
    );
  }
}

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  static const completedPreferenceKey = 'onboarding_completed';

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _hasCompletedOnboarding;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hasCompletedOnboarding =
          preferences.getBool(OnboardingGate.completedPreferenceKey) ?? false;
    });
  }

  Future<void> _finishOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(OnboardingGate.completedPreferenceKey, true);
    if (!mounted) return;
    setState(() => _hasCompletedOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_hasCompletedOnboarding) {
      true => const TapToneShell(),
      false => OnboardingScreen(onFinished: _finishOnboarding),
      null => const _StartupScreen(),
    };
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Image(
          image: AssetImage('assets/images/app_logo.png'),
          width: 104,
          height: 104,
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final Future<void> Function() onFinished;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 132,
                          height: 132,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'TapTone',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF123C38),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Helping colorblind users distinguish colors better.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF41524E),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const _OnboardingFeature(
                        icon: Icons.auto_fix_high_rounded,
                        title: 'Enhance color differences',
                        text:
                            'Apply assistive filters to photos when colors are difficult to tell apart.',
                      ),
                      const SizedBox(height: 14),
                      const _OnboardingFeature(
                        icon: Icons.colorize_rounded,
                        title: 'Identify colors around you',
                        text:
                            'Use the camera to check a color name and its hex code in real time.',
                      ),
                      const SizedBox(height: 14),
                      const _OnboardingFeature(
                        icon: Icons.visibility_rounded,
                        title: 'Understand color vision',
                        text:
                            'Preview simulations that show how color vision differences can appear.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onFinished,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingFeature extends StatelessWidget {
  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF52615E),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TapToneShell extends StatefulWidget {
  const TapToneShell({super.key});

  @override
  State<TapToneShell> createState() => _TapToneShellState();
}

class _TapToneShellState extends State<TapToneShell> {
  int _selectedIndex = 0;

  Widget _currentPage() {
    return switch (_selectedIndex) {
      1 => const ColorDetectorScreen(),
      2 => const SimulationScreen(),
      _ => const ColorAssistScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('TapTone'),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(child: _currentPage()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_fix_high_outlined),
            selectedIcon: Icon(Icons.auto_fix_high_rounded),
            label: 'Assist',
          ),
          NavigationDestination(
            icon: Icon(Icons.colorize_outlined),
            selectedIcon: Icon(Icons.colorize_rounded),
            label: 'Detect',
          ),
          NavigationDestination(
            icon: Icon(Icons.visibility_outlined),
            selectedIcon: Icon(Icons.visibility_rounded),
            label: 'Simulate',
          ),
        ],
      ),
    );
  }
}

class ColorAssistScreen extends StatefulWidget {
  const ColorAssistScreen({super.key});

  @override
  State<ColorAssistScreen> createState() => _ColorAssistScreenState();
}

class _ColorAssistScreenState extends State<ColorAssistScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  AssistFilter? _activeFilter;

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 2400,
    );
    if (image == null || !mounted) return;
    setState(() {
      _selectedImage = image;
      _activeFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Text(
            'Helping colorblind users distinguish colors better.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF41524E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: _PhotoPreview(
                image: _selectedImage,
                label: _activeFilter?.title ?? 'Original',
                matrix: _activeFilter?.matrix,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ImageActions(
            onTakePhoto: () => _pickImage(ImageSource.camera),
            onUploadPhoto: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Assist filters', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 136,
            child: _PhotoFilterScroller(
              image: _selectedImage,
              activeTitle: _activeFilter?.title,
              options: AssistFilter.values
                  .map((filter) => _FilterOption(filter.title, filter.matrix))
                  .toList(),
              onSelect: (title) =>
                  setState(() => _activeFilter = AssistFilter.byTitle(title)),
              onReset: () => setState(() => _activeFilter = null),
            ),
          ),
        ],
      ),
    );
  }
}

class ColorDetectorScreen extends StatefulWidget {
  const ColorDetectorScreen({super.key});

  @override
  State<ColorDetectorScreen> createState() => _ColorDetectorScreenState();
}

class _ColorDetectorScreenState extends State<ColorDetectorScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  DetectedColor _detected = DetectedColor.fromColor(const Color(0xFFFFFFFF));
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);
  bool _processingFrame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'No camera found.');
      }
      final controller = CameraController(
        cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.startImageStream(_processFrame);
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _error = error.description ?? 'Camera unavailable.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Camera unavailable. Check camera permission and try again.',
        );
      }
    }
  }

  void _processFrame(CameraImage image) {
    final now = DateTime.now();
    if (_processingFrame || now.difference(_lastSample).inMilliseconds < 250) {
      return;
    }
    _processingFrame = true;
    _lastSample = now;
    try {
      final color = _sampleCenterColor(image);
      if (mounted) setState(() => _detected = DetectedColor.fromColor(color));
    } finally {
      _processingFrame = false;
    }
  }

  Color _sampleCenterColor(CameraImage image) {
    const radius = 12;
    const step = 4;
    final centerX = image.width ~/ 2;
    final centerY = image.height ~/ 2;
    var red = 0;
    var green = 0;
    var blue = 0;
    var samples = 0;

    for (var offsetY = -radius; offsetY <= radius; offsetY += step) {
      for (var offsetX = -radius; offsetX <= radius; offsetX += step) {
        final x = (centerX + offsetX).clamp(0, image.width - 1);
        final y = (centerY + offsetY).clamp(0, image.height - 1);
        final color = image.planes.length == 1
            ? _readBgraPixel(image, x, y)
            : _readYuvPixel(image, x, y);
        if (color == null) continue;
        final argb = color.toARGB32();
        red += (argb >> 16) & 0xFF;
        green += (argb >> 8) & 0xFF;
        blue += argb & 0xFF;
        samples++;
      }
    }

    if (samples == 0) return Colors.white;
    return Color.fromARGB(
      255,
      red ~/ samples,
      green ~/ samples,
      blue ~/ samples,
    );
  }

  Color? _readBgraPixel(CameraImage image, int x, int y) {
    final plane = image.planes.first;
    final index = y * plane.bytesPerRow + x * 4;
    if (index + 2 >= plane.bytes.length) return null;
    return Color.fromARGB(
      255,
      plane.bytes[index + 2],
      plane.bytes[index + 1],
      plane.bytes[index],
    );
  }

  Color? _readYuvPixel(CameraImage image, int x, int y) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uvPixelStride;
    final yIndex = y * yPlane.bytesPerRow + x;
    if (yIndex >= yPlane.bytes.length ||
        uvIndex >= uPlane.bytes.length ||
        uvIndex >= vPlane.bytes.length) {
      return null;
    }
    final luminance = yPlane.bytes[yIndex].toDouble();
    final u = uPlane.bytes[uvIndex].toDouble() - 128;
    final v = vPlane.bytes[uvIndex].toDouble() - 128;
    return Color.fromARGB(
      255,
      (luminance + 1.402 * v).round().clamp(0, 255),
      (luminance - 0.344136 * u - 0.714136 * v).round().clamp(0, 255),
      (luminance + 1.772 * u).round().clamp(0, 255),
    );
  }

  Future<void> _disposeCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    if (controller.value.isStreamingImages) await controller.stopImageStream();
    await controller.dispose();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCamera());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      return _CameraMessage(icon: Icons.no_photography_outlined, text: _error!);
    }
    if (controller == null || !controller.value.isInitialized) {
      return const _CameraMessage(
        icon: Icons.photo_camera_outlined,
        text: 'Starting camera...',
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        const Center(child: _CameraTarget()),
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: _DetectedColorPanel(detected: _detected),
        ),
      ],
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraTarget extends StatelessWidget {
  const _CameraTarget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 8),
              ],
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black45, width: 2),
            ),
          ),
          const Positioned(
            right: 0,
            top: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.colorize_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectedColorPanel extends StatelessWidget {
  const _DetectedColorPanel({required this.detected});
  final DetectedColor detected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: detected.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white70),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detected.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detected.hex,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  SimulationFilter? _activeFilter;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'No camera found.');
      }
      final controller = CameraController(
        cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _error = error.description ?? 'Camera unavailable.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Camera unavailable. Check camera permission and try again.',
        );
      }
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCamera());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      return _CameraMessage(icon: Icons.no_photography_outlined, text: _error!);
    }
    if (controller == null || !controller.value.isInitialized) {
      return const _CameraMessage(
        icon: Icons.photo_camera_outlined,
        text: 'Starting camera...',
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.matrix(
            _activeFilter?.matrix ?? AssistFilter.identityMatrix,
          ),
          child: CameraPreview(controller),
        ),
        Positioned(
          top: 14,
          left: 14,
          child: _PreviewLabel(text: _activeFilter?.title ?? 'Normal vision'),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 14,
          child: _LiveSimulationFilters(
            activeFilter: _activeFilter,
            onReset: () => setState(() => _activeFilter = null),
            onSelect: (filter) => setState(() => _activeFilter = filter),
          ),
        ),
      ],
    );
  }
}

class _LiveSimulationFilters extends StatelessWidget {
  const _LiveSimulationFilters({
    required this.activeFilter,
    required this.onReset,
    required this.onSelect,
  });

  final SimulationFilter? activeFilter;
  final VoidCallback onReset;
  final ValueChanged<SimulationFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _LiveFilterButton(
                title: 'Normal',
                isSelected: activeFilter == null,
                onTap: onReset,
              ),
              ...SimulationFilter.values.map(
                (filter) => _LiveFilterButton(
                  title: filter.title,
                  isSelected: activeFilter == filter,
                  onTap: () => onSelect(filter),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveFilterButton extends StatelessWidget {
  const _LiveFilterButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF123C38) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.image, required this.label, this.matrix});
  final XFile? image;
  final String label;
  final List<double>? matrix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1,
        child: image == null
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF0F6F4)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_search_rounded,
                    size: 54,
                    color: theme.colorScheme.primary.withValues(alpha: 0.56),
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(
                      matrix ?? AssistFilter.identityMatrix,
                    ),
                    child: Image.file(File(image!.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _PreviewLabel(text: label),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ImageActions extends StatelessWidget {
  const _ImageActions({required this.onTakePhoto, required this.onUploadPhoto});
  final VoidCallback onTakePhoto;
  final VoidCallback onUploadPhoto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onTakePhoto,
            icon: const Icon(Icons.photo_camera_rounded),
            label: const Text('Take Photo'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onUploadPhoto,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Upload Photo'),
          ),
        ),
      ],
    );
  }
}

class _PhotoFilterScroller extends StatelessWidget {
  const _PhotoFilterScroller({
    required this.image,
    required this.activeTitle,
    required this.options,
    required this.onSelect,
    required this.onReset,
  });
  final XFile? image;
  final String? activeTitle;
  final List<_FilterOption> options;
  final ValueChanged<String> onSelect;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _FilterTile(
            title: 'Reset',
            image: image,
            matrix: AssistFilter.identityMatrix,
            isSelected: activeTitle == null,
            selectedIcon: Icons.refresh_rounded,
            onTap: onReset,
          ),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _FilterTile(
                title: option.title,
                image: image,
                matrix: option.matrix,
                isSelected: option.title == activeTitle,
                selectedIcon: Icons.check_rounded,
                onTap: () => onSelect(option.title),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.title,
    required this.image,
    required this.matrix,
    required this.isSelected,
    required this.selectedIcon,
    required this.onTap,
  });
  final String title;
  final XFile? image;
  final List<double> matrix;
  final bool isSelected;
  final IconData selectedIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : const Color(0xFFE2EAE7),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.matrix(matrix),
                        child: image == null
                            ? Image.asset(
                                'assets/images/default_filter_preview.png',
                                fit: BoxFit.cover,
                              )
                            : Image.file(File(image!.path), fit: BoxFit.cover),
                      ),
                      if (isSelected)
                        Container(color: Colors.black.withValues(alpha: 0.12)),
                      if (isSelected)
                        Center(
                          child: Icon(
                            selectedIcon,
                            color: Colors.white,
                            size: 48,
                            shadows: const [Shadow(blurRadius: 8)],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption(this.title, this.matrix);
  final String title;
  final List<double> matrix;
}

class DetectedColor {
  const DetectedColor(this.name, this.hex, this.color);
  final String name;
  final String hex;
  final Color color;

  factory DetectedColor.fromColor(Color color) {
    final nearest = _namedColors.reduce(
      (best, current) =>
          _distance(color, current.color) < _distance(color, best.color)
          ? current
          : best,
    );
    final rgb = color.toARGB32() & 0xFFFFFF;
    final hex = '#${rgb.toRadixString(16).padLeft(6, '0')}'.toUpperCase();
    return DetectedColor(nearest.name, hex, color);
  }

  static double _distance(Color a, Color b) =>
      math.pow(a.r - b.r, 2).toDouble() +
      math.pow(a.g - b.g, 2).toDouble() +
      math.pow(a.b - b.b, 2).toDouble();

  static const _namedColors = [
    _NamedColor('Black', Color(0xFF111111)),
    _NamedColor('White', Color(0xFFF5F5F5)),
    _NamedColor('Gray', Color(0xFF808080)),
    _NamedColor('Red', Color(0xFFE53935)),
    _NamedColor('Orange', Color(0xFFFB8C00)),
    _NamedColor('Yellow', Color(0xFFFDD835)),
    _NamedColor('Green', Color(0xFF43A047)),
    _NamedColor('Teal', Color(0xFF00897B)),
    _NamedColor('Blue', Color(0xFF1E88E5)),
    _NamedColor('Purple', Color(0xFF8E24AA)),
    _NamedColor('Pink', Color(0xFFD81B60)),
    _NamedColor('Brown', Color(0xFF795548)),
  ];
}

class _NamedColor {
  const _NamedColor(this.name, this.color);
  final String name;
  final Color color;
}

enum AssistFilter {
  deuteranomaly('Deuteranomaly', <double>[
    0.885,
    0.115,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    -0.490,
    0.190,
    1.300,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]),
  protanopia('Protanopia', <double>[
    1,
    0,
    0,
    0,
    0,
    -0.255,
    1.255,
    0,
    0,
    0,
    0.303,
    -0.545,
    1.242,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]),
  tritanopia('Tritanopia', <double>[
    1.050,
    -0.383,
    0.333,
    0,
    0,
    0,
    1.235,
    -0.235,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  const AssistFilter(this.title, this.matrix);
  final String title;
  final List<double> matrix;

  static AssistFilter byTitle(String title) =>
      values.firstWhere((filter) => filter.title == title);
  static const identityMatrix = <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

enum SimulationFilter {
  deuteranomaly('Deuteranomaly', <double>[
    0.80,
    0.20,
    0,
    0,
    0,
    0.258,
    0.742,
    0,
    0,
    0,
    0,
    0.142,
    0.858,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]),
  protanopia('Protanopia', <double>[
    0.567,
    0.433,
    0,
    0,
    0,
    0.558,
    0.442,
    0,
    0,
    0,
    0,
    0.242,
    0.758,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]),
  tritanopia('Tritanopia', <double>[
    0.95,
    0.05,
    0,
    0,
    0,
    0,
    0.433,
    0.567,
    0,
    0,
    0,
    0.475,
    0.525,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  const SimulationFilter(this.title, this.matrix);
  final String title;
  final List<double> matrix;
  static SimulationFilter byTitle(String title) =>
      values.firstWhere((filter) => filter.title == title);
}

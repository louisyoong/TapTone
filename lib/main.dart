import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
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
      home: const ColorAssistScreen(),
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

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _selectedImage = image;
      _activeFilter = null;
    });
  }

  void _selectFilter(AssistFilter filter) {
    setState(() {
      _activeFilter = filter;
    });
  }

  void _resetFilter() {
    setState(() {
      _activeFilter = null;
    });
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Text(
              'Helping colorblind users distinguish colors better.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF41524E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            _ImagePreview(image: _selectedImage, filter: _activeFilter),
            const SizedBox(height: 16),
            _ImageActions(
              onTakePhoto: () => _pickImage(ImageSource.camera),
              onUploadPhoto: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 22),
            Text('Filters', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _FilterScroller(
              image: _selectedImage,
              activeFilter: _activeFilter,
              onFilterSelected: _selectFilter,
              onReset: _resetFilter,
            ),
            const SizedBox(height: 18),
            _DisclaimerCard(theme: theme),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image, required this.filter});

  final XFile? image;
  final AssistFilter? filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = filter?.title ?? 'Normal Vision Reference';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1,
        child: image == null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF0F6F4)],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFDDE8E5)),
                    ),
                    child: Icon(
                      Icons.image_search_rounded,
                      size: 42,
                      color: theme.colorScheme.primary.withValues(alpha: 0.56),
                    ),
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(
                      filter?.matrix ?? AssistFilter.identityMatrix,
                    ),
                    child: Image.file(File(image!.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 430;
        final buttons = [
          FilledButton.icon(
            onPressed: onTakePhoto,
            icon: const Icon(Icons.photo_camera_rounded),
            label: const Text('Take Photo'),
          ),
          OutlinedButton.icon(
            onPressed: onUploadPhoto,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Upload Photo'),
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: buttons.first),
              const SizedBox(width: 12),
              Expanded(child: buttons.last),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [buttons.first, const SizedBox(height: 10), buttons.last],
        );
      },
    );
  }
}

class _FilterScroller extends StatelessWidget {
  const _FilterScroller({
    required this.image,
    required this.activeFilter,
    required this.onFilterSelected,
    required this.onReset,
  });

  final XFile? image;
  final AssistFilter? activeFilter;
  final ValueChanged<AssistFilter> onFilterSelected;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _FilterTile(
              title: 'Reset',
              image: image,
              matrix: AssistFilter.identityMatrix,
              isSelected: activeFilter == null,
              selectedIcon: Icons.refresh_rounded,
              onTap: onReset,
            ),
          ),
          ...AssistFilter.values.map((filter) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _FilterTile(
                title: filter.title,
                image: image,
                matrix: filter.matrix,
                isSelected: filter == activeFilter,
                selectedIcon: Icons.check_rounded,
                onTap: () => onFilterSelected(filter),
              ),
            );
          }),
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
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : const Color(0xFFE2EAE7);

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
                    color: borderColor,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.16,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
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

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF4E5A7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'This app helps enhance color differences, but cannot restore normal color vision or guarantee exact real-world colors.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5D4A12),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
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

  // Daltonization-style matrices: remap color differences that may be lost
  // into channels that are more likely to remain distinguishable.
  const AssistFilter(this.title, this.matrix);

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

  final String title;
  final List<double> matrix;
}

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/card_enums.dart';
import '../../models/card_template.dart';

/// Off-screen rendering service for Keepsake cards.
/// Renders 1080×1440 3:4 portrait PNGs with template engine, auto-font sizing,
/// overlay elements, and decorative motifs.
class CardRenderService {
  static const int _cardWidth = 1080;
  static const int _cardHeight = 1440;
  static const String _defaultFooter = 'Blinking Notes';
  static const int _minFontSize = 9;
  static const int _maxFontSize = 96;
  static const _uuid = Uuid();

  CardRenderService._();

  /// Builds the card widget tree for preview (mounted in RepaintBoundary).
  static Widget buildPreviewWidget({
    required CardTemplate template,
    required String content,
    String? imagePath,
    String? emotion,
    List<String>? tags,
    DateTime? date,
    bool? showMood,
    bool? showDate,
    bool? showTags,
    bool? showFooter,
    Map<String, dynamic>? styleOverrides,
    Uint8List? backgroundImageBytes,
    ui.Image? decodedBackgroundImage,
  }) {
    final config = _buildConfig(
      template,
      styleOverrides: styleOverrides,
      showMood: showMood,
      showDate: showDate,
      showTags: showTags,
      showFooter: showFooter,
      backgroundImageBytes: backgroundImageBytes,
      decodedBackgroundImage: decodedBackgroundImage,
    );
    return _CardRenderWidget(
      template: template,
      config: config,
      content: content,
      imagePath: imagePath,
      emotion: emotion,
      tags: tags,
      date: date,
    );
  }

  /// Renders a card to a PNG file and returns the file path.
  /// Uses an off-screen RepaintBoundary pipeline.
  static Future<String> renderToFile({
    required CardTemplate template,
    required String content,
    String? imagePath,
    String? emotion,
    List<String>? tags,
    DateTime? date,
    bool? showMood,
    bool? showDate,
    bool? showTags,
    bool? showFooter,
    Map<String, dynamic>? styleOverrides,
    Uint8List? backgroundImageBytes,
    ui.Image? decodedBackgroundImage,
  }) async {
    final widget = buildPreviewWidget(
      template: template,
      content: content,
      imagePath: imagePath,
      emotion: emotion,
      tags: tags,
      date: date,
      showMood: showMood,
      showDate: showDate,
      showTags: showTags,
      showFooter: showFooter,
      styleOverrides: styleOverrides,
      backgroundImageBytes: backgroundImageBytes,
      decodedBackgroundImage: decodedBackgroundImage,
    );

    final image = await _renderOffscreen(widget);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw Exception('Failed to convert image to PNG bytes');

    final dir = await getApplicationDocumentsDirectory();
    final cardDir = Directory('${dir.path}/cards');
    if (!cardDir.existsSync()) cardDir.createSync(recursive: true);
    final path = '${cardDir.path}/${_uuid.v4()}.png';
    await File(path).writeAsBytes(bytes.buffer.asUint8List());
    return path;
  }

  /// Captures a PNG from a RepaintBoundary key (for preview screen).
  static Future<String?> captureFromKey(GlobalKey boundaryKey) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final cardDir = Directory('${dir.path}/cards');
    if (!cardDir.existsSync()) cardDir.createSync(recursive: true);
    final path = '${cardDir.path}/${_uuid.v4()}.png';
    await File(path).writeAsBytes(bytes.buffer.asUint8List());
    return path;
  }

  // ---- Private rendering ----

  static Future<ui.Image> _renderOffscreen(Widget widget) async {
    WidgetsFlutterBinding.ensureInitialized();

    final renderObject = RenderRepaintBoundary();
    final pipelineOwner = PipelineOwner();
    renderObject.attach(pipelineOwner);

    final element = RenderObjectToWidgetAdapter<RenderBox>(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
      container: renderObject,
    ).createElement();
    element.assignOwner(BuildOwner(focusManager: FocusManager()));
    element.mount(null, null);

    renderObject.layout(
      BoxConstraints.tight(Size(_cardWidth.toDouble(), _cardHeight.toDouble())),
    );
    pipelineOwner.flushLayout();
    pipelineOwner.flushPaint();

    final image = await renderObject.toImage(pixelRatio: 1.0);

    try { element.unmount(); } catch (_) {}
    try { renderObject.detach(); } catch (_) {}
    try { pipelineOwner.dispose(); } catch (_) {}

    return image;
  }

  static _CardConfig _buildConfig(
    CardTemplate template, {
    Map<String, dynamic>? styleOverrides,
    bool? showMood,
    bool? showDate,
    bool? showTags,
    bool? showFooter,
    Uint8List? backgroundImageBytes,
    ui.Image? decodedBackgroundImage,
  }) {
    return _CardConfig(
      layout: template.layout,
      bgColor: _parseColor(template.bgColor),
      fontColor: _parseColor(styleOverrides?['font_color'] as String? ?? template.fontColor),
      accentColor: template.accentColor != null
          ? _parseColor(styleOverrides?['accent_color'] as String? ?? template.accentColor!)
          : null,
      textBackdropColor: template.textBackdropColor != null
          ? _tryParseRgba(template.textBackdropColor!)
          : null,
      textAreaOpacity: (styleOverrides?['text_area_opacity'] as num?)?.toDouble() ??
          template.textAreaOpacity,
      footerText: template.footerText ?? _defaultFooter,
      showMood: showMood ?? template.showMood,
      showDate: showDate ?? template.showDate,
      showTags: showTags ?? template.showTags,
      showFooter: showFooter ?? template.showFooter,
      cornerStyle: template.cornerStyle,
      decorationStyle: template.decorationStyle,
      backgroundImagePath: template.backgroundImagePath,
      backgroundImageBytes: backgroundImageBytes,
      decodedBackgroundImage: decodedBackgroundImage,
      textPaddingTop: (styleOverrides?['text_padding_top'] as num?)?.toDouble() ?? template.textPaddingTop,
      textPaddingBottom: (styleOverrides?['text_padding_bottom'] as num?)?.toDouble() ?? template.textPaddingBottom,
      textPaddingLeft: (styleOverrides?['text_padding_left'] as num?)?.toDouble() ?? template.textPaddingLeft,
      textPaddingRight: (styleOverrides?['text_padding_right'] as num?)?.toDouble() ?? template.textPaddingRight,
      baseFontSize: (styleOverrides?['base_font_size'] as num?)?.toDouble() ?? template.baseFontSize,
      fontWeightValue: (styleOverrides?['font_weight_value'] as int?) ?? template.fontWeightValue,
      textAlignMode: template.textAlignMode,
    );
  }

  static Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static Color? _tryParseRgba(String rgba) {
    try {
      final match = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)').firstMatch(rgba);
      if (match != null) {
        return Color.fromARGB(
          (double.parse(match.group(4)!) * 255).round(),
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
    } catch (_) {}
    return null;
  }
}

/// Internal configuration resolved from template + overrides.
class _CardConfig {
  final CardLayout layout;
  final Color bgColor;
  final Color fontColor;
  final Color? accentColor;
  final Color? textBackdropColor;
  final double textAreaOpacity;
  final String footerText;
  final bool showMood;
  final bool showDate;
  final bool showTags;
  final bool showFooter;
  final CardCornerStyle cornerStyle;
    final String? decorationStyle;
    final String? backgroundImagePath;
    final Uint8List? backgroundImageBytes;
    final ui.Image? decodedBackgroundImage;
    final double textPaddingTop;
    final double textPaddingBottom;
    final double textPaddingLeft;
    final double textPaddingRight;
    final double baseFontSize;
    final int fontWeightValue;
    final TextAlignMode textAlignMode;

    _CardConfig({
    required this.layout,
    required this.bgColor,
    required this.fontColor,
    this.accentColor,
    this.textBackdropColor,
    required this.textAreaOpacity,
    required this.footerText,
    required this.showMood,
    required this.showDate,
    required this.showTags,
    required this.showFooter,
    required this.cornerStyle,
    this.decorationStyle,
    this.backgroundImagePath,
    this.backgroundImageBytes,
    this.decodedBackgroundImage,
    this.textPaddingTop = 120,
    this.textPaddingBottom = 140,
    this.textPaddingLeft = 80,
    this.textPaddingRight = 80,
    this.baseFontSize = 72,
    this.fontWeightValue = 500,
    this.textAlignMode = TextAlignMode.center,
  });
}

/// The full card widget tree rendered at 1080×1440.
class _CardRenderWidget extends StatelessWidget {
  final CardTemplate template;
  final _CardConfig config;
  final String content;
  final String? imagePath;
  final String? emotion;
  final List<String>? tags;
  final DateTime? date;

  const _CardRenderWidget({
    required this.template,
    required this.config,
    required this.content,
    this.imagePath,
    this.emotion,
    this.tags,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = _cornerRadius();
    final hasBgImage = config.decodedBackgroundImage != null ||
        config.backgroundImageBytes != null ||
        (config.backgroundImagePath != null && config.backgroundImagePath!.startsWith('assets/'));

    // When a background image is present, use solid bgColor as fallback (not gradient)
    final bgDecoration = hasBgImage
        ? BoxDecoration(color: config.bgColor)
        : _buildBackground();

    Decoration? imageDecoration;
    if (config.backgroundImageBytes == null && config.backgroundImagePath != null &&
        config.backgroundImagePath!.startsWith('assets/')) {
      // AssetImage fallback for contexts where bytes aren't available
      imageDecoration = BoxDecoration(
        image: DecorationImage(
          image: AssetImage(config.backgroundImagePath!),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
        color: config.bgColor,
      );
    }

    Widget child = _buildLayout();

    // Pre-decoded image: use RawImage which paints instantly (no async decode)
    if (config.decodedBackgroundImage != null) {
      child = Stack(
        fit: StackFit.expand,
        children: [
          RawImage(image: config.decodedBackgroundImage, fit: BoxFit.cover),
          child,
        ],
      );
    } else if (config.backgroundImageBytes != null) {
      child = Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(config.backgroundImageBytes!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          child,
        ],
      );
    }

    // File-based background images (Stack approach)
    final fileBgPath = config.backgroundImagePath;
    if (fileBgPath != null && (fileBgPath.startsWith('/') || fileBgPath.startsWith('file://'))) {
      try {
        final filePath = fileBgPath.startsWith('file://') ? fileBgPath.substring(7) : fileBgPath;
        final file = File(filePath);
        if (file.existsSync()) {
          child = Stack(
            fit: StackFit.expand,
            children: [
              Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              child,
            ],
          );
        }
      } catch (_) {}
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: CardRenderService._cardWidth.toDouble(),
        height: CardRenderService._cardHeight.toDouble(),
        child: DecoratedBox(
          decoration: imageDecoration ?? bgDecoration,
          child: child,
        ),
      ),
    );
  }

  BorderRadius _cornerRadius() {
    switch (config.cornerStyle) {
      case CardCornerStyle.sharp:
        return BorderRadius.zero;
      case CardCornerStyle.pill:
        return const BorderRadius.all(Radius.circular(720));
      case CardCornerStyle.rounded:
      default:
        return const BorderRadius.all(Radius.circular(24));
    }
  }

  String? _resolveFontFamily() {
    switch (template.fontFamily) {
      case 'serif':
        return 'MaShanZheng';
      case 'mono':
        return 'monospace';
      case 'default':
      default:
        return null; // system default sans-serif
    }
  }

  Decoration _buildBackground() {
    if (config.decorationStyle != null) {
      return _buildDecoratedBackground(config.decorationStyle!);
    }
    return BoxDecoration(color: config.bgColor);
  }

  Decoration _buildDecoratedBackground(String style) {
    switch (style) {
      case 'ink_wash':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2EFE9),
              Color(0xFFD5CFC3),
            ],
          ),
        );
      case 'bamboo':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEDF5EC),
              Color(0xFFD4E6D0),
            ],
          ),
        );
      case 'crescent':
      case 'moonlight':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B2838),
              Color(0xFF2D4A5A),
            ],
          ),
        );
      case 'tea':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5EDE3),
              Color(0xFFE8D5C0),
            ],
          ),
        );
      case 'landscape':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD6E0E8),
              Color(0xFFB8C8D4),
            ],
          ),
        );
      default:
        return BoxDecoration(color: config.bgColor);
    }
  }

  Widget _buildLayout() {
    switch (config.layout) {
      case CardLayout.centered:
        return _buildCenteredLayout();
      case CardLayout.leftAligned:
        return _buildLeftAlignedLayout();
      case CardLayout.twoColumn:
        return _buildTwoColumnLayout();
      case CardLayout.heroImage:
      default:
        return _buildHeroLayout();
    }
  }

  // --- Hero Image Layout ---

  Widget _buildHeroLayout() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagePath != null) _buildFullBleedImage(),
        _buildDecorativeMotif(config.decorationStyle),
        Padding(
          padding: EdgeInsets.only(
            left: config.textPaddingLeft,
            top: config.textPaddingTop,
            right: config.textPaddingRight,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _buildTextBlock(content),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: _buildOverlayRow(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Centered Layout ---

  Widget _buildCenteredLayout() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagePath != null) _buildFullBleedImage(),
        _buildDecorativeMotif(config.decorationStyle),
        if (config.decorationStyle == 'porcelain') _buildPorcelainBorders(),
        Padding(
          padding: EdgeInsets.only(
            left: config.textPaddingLeft,
            top: config.textPaddingTop,
            right: config.textPaddingRight,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _buildTextBlock(content),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: _buildOverlayRow(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Left-Aligned Layout ---

  Widget _buildLeftAlignedLayout() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Left accent bar
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 4,
            color: config.accentColor ?? config.fontColor.withValues(alpha: 0.3),
          ),
        ),
        // Rice paper texture for 素笺
        if (config.decorationStyle == 'rice_paper') _buildRicePaperTexture(),
        Padding(
          padding: EdgeInsets.only(
            left: config.textPaddingLeft,
            top: config.textPaddingTop,
            right: config.textPaddingRight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTextBlock(content)),
              if (imagePath != null) _buildInlineImage(),
              Padding(
                padding: EdgeInsets.only(top: 16, bottom: config.textPaddingBottom - 60),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildOverlayRow(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Two-Column Layout ---

  Widget _buildTwoColumnLayout() {
    return Column(
      children: [
        if (imagePath != null)
          SizedBox(
            height: CardRenderService._cardHeight * 0.4,
            child: _buildHeroImage(),
          ),
        Expanded(child: _buildContentArea()),
        Padding(
          padding: EdgeInsets.only(
            left: config.textPaddingLeft,
            right: config.textPaddingRight,
            bottom: config.textPaddingBottom - 60,
          ),
          child: _buildOverlayRow(),
        ),
      ],
    );
  }

  Widget _buildContentArea() {
    return Padding(
      padding: EdgeInsets.only(
        left: config.textPaddingLeft,
        top: imagePath != null ? 8 : config.textPaddingTop,
        right: config.textPaddingRight,
      ),
      child: _buildTextBlock(content),
    );
  }

  // --- Image helpers ---

  Widget _buildFullBleedImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          child: Image.file(
            File(imagePath!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.50),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return Image.file(
      File(imagePath!),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _buildInlineImage() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(imagePath!),
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  // --- Text block ---

  Widget _buildTextBlock(String text) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveText = text.trim().isEmpty ? '' : text.trim();
        if (effectiveText.isEmpty) return const SizedBox.shrink();

        final hasBgImage = config.decodedBackgroundImage != null ||
            config.backgroundImageBytes != null ||
            (config.backgroundImagePath != null && config.backgroundImagePath!.startsWith('assets/'));

        // Never render colored text backdrop when background image is present
        final hasBackdrop = !hasBgImage && config.textBackdropColor != null;
        final double innerMaxWidth = hasBackdrop
            ? constraints.maxWidth - 40
            : constraints.maxWidth;
        final double innerMaxHeight = hasBackdrop
            ? constraints.maxHeight - 40
            : constraints.maxHeight;

        final fontSize = _findOptimalFontSize(
          effectiveText,
          innerMaxWidth,
          innerMaxHeight,
          maxFontSize: config.baseFontSize,
        );

        final resolvedFontFamily = _resolveFontFamily();
        final align = config.textAlignMode.toFlutter();
        final fontWeight = FontWeight.values.firstWhere(
          (w) => w.index == config.fontWeightValue ~/ 100 - 1,
          orElse: () => FontWeight.w500,
        );

        Widget textWidget = Text(
          effectiveText,
          textAlign: align,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: resolvedFontFamily,
            color: config.fontColor,
            height: 1.6,
            fontWeight: fontWeight,
            decoration: TextDecoration.none,
          ),
          maxLines: null,
          overflow: TextOverflow.visible,
        );

        if (hasBackdrop) {
          textWidget = Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: config.textBackdropColor!.withValues(
                alpha: config.textAreaOpacity,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: textWidget,
          );
        }

        return Center(child: textWidget);
      },
    );
  }

  double _findOptimalFontSize(String text, double maxWidth, double maxHeight, {double maxFontSize = 96}) {
    double low = CardRenderService._minFontSize.toDouble();
    double high = maxFontSize.clamp(CardRenderService._minFontSize.toDouble(), CardRenderService._maxFontSize.toDouble());
    double best = low;

    while (low <= high) {
      final mid = (low + high) / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: mid, height: 1.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (tp.height <= maxHeight && tp.width <= maxWidth) {
        best = mid;
        low = mid + 0.5;
      } else {
        high = mid - 0.5;
      }
    }
    return best.clamp(CardRenderService._minFontSize.toDouble(), CardRenderService._maxFontSize.toDouble());
  }

  // --- Overlay row ---

  Widget _buildOverlayRow() {
    final items = <Widget>[];

    if (config.showMood && emotion != null && emotion!.isNotEmpty) {
      items.add(Text(emotion!, style: const TextStyle(fontSize: 28, decoration: TextDecoration.none)));
      items.add(const SizedBox(width: 8));
    }
    if (config.showDate && date != null) {
      items.add(Text(
        '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
        style: TextStyle(fontSize: 18, color: config.fontColor.withValues(alpha: 0.4), fontWeight: FontWeight.w300, decoration: TextDecoration.none),
      ));
      items.add(const SizedBox(width: 8));
    }
    if (config.showTags && tags != null && tags!.isNotEmpty) {
      final displayTags = tags!
          .where((t) => t != 'tag_synthesis' && t != 'tag_private')
          .take(5)
          .toList();
      if (displayTags.isNotEmpty) {
        items.add(Text(
          displayTags.map((t) => '#$t').join(' '),
          style: TextStyle(fontSize: 18, color: config.fontColor.withValues(alpha: 0.4), decoration: TextDecoration.none),
        ));
        items.add(const SizedBox(width: 8));
      }
    }
    if (config.showFooter) {
      items.add(Text(
        config.footerText,
        style: TextStyle(fontSize: 15, color: config.fontColor.withValues(alpha: 0.35), decoration: TextDecoration.none),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: items,
    );
  }

  // --- Decorative motifs ---

  Widget _buildDecorativeMotif(String? style) {
    if (style == null) return const SizedBox.shrink();
    switch (style) {
      case 'crescent':
        return _buildCrescentMoon();
      case 'bamboo':
        return _buildBambooLeaf();
      case 'seal':
        return _buildSealStamp();
      case 'tea':
        return _buildTeaSteam();
      case 'landscape':
        return _buildMountainSilhouettes();
      case 'porcelain':
        return const SizedBox.shrink(); // Borders handled separately
      case 'ink_wash':
      case 'rice_paper':
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCrescentMoon() {
    return Positioned(
      right: 60,
      top: 60,
      child: CustomPaint(
        size: const Size(120, 120),
        painter: _CrescentPainter(),
      ),
    );
  }

  Widget _buildBambooLeaf() {
    return Positioned(
      right: 20,
      bottom: 180,
      child: CustomPaint(
        size: const Size(160, 100),
        painter: _BambooPainter(config.accentColor ?? const Color(0xFF7A9A6D)),
      ),
    );
  }

  Widget _buildSealStamp() {
    return Positioned(
      right: 80,
      bottom: 200,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          border: Border.all(color: config.accentColor ?? const Color(0xFFC43A31), width: 3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '印',
            style: TextStyle(
              fontSize: 36,
              color: config.accentColor ?? const Color(0xFFC43A31),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeaSteam() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _SteamPainter(config.accentColor ?? const Color(0xFF8FBFB3)),
      ),
    );
  }

  Widget _buildMountainSilhouettes() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: CardRenderService._cardHeight * 0.30,
      child: CustomPaint(
        painter: _MountainPainter(),
      ),
    );
  }

  Widget _buildPorcelainBorders() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        height: 4,
        color: config.accentColor ?? const Color(0xFF2B5F8A),
      ),
    );
  }

  Widget _buildRicePaperTexture() {
    return Positioned.fill(
      child: CustomPaint(painter: _RicePaperPainter()),
    );
  }
}

// --- Decorative motif painters ---

class _CrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x40FFFFFF)
      ..style = PaintingStyle.fill;
    final outerPath = Path()..addOval(Rect.fromCircle(center: Offset(size.width * 0.6, size.height * 0.5), radius: 45));
    final innerPath = Path()..addOval(Rect.fromCircle(center: Offset(size.width * 0.75, size.height * 0.35), radius: 45));
    final crescent = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(crescent, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BambooPainter extends CustomPainter {
  final Color color;
  _BambooPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    // Draw 3 leaves at different angles
    for (int i = 0; i < 3; i++) {
      final dx = size.width * (0.7 + i * 0.12);
      final path = Path()
        ..moveTo(size.width, size.height * 0.3)
        ..quadraticBezierTo(dx, size.height * 0.1, size.width * 0.6, 0)
        ..quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width * 0.8, size.height * 0.5)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SteamPainter extends CustomPainter {
  final Color color;
  _SteamPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final x = size.width * (0.3 + i * 0.2);
      path.moveTo(x, size.height * 0.5);
      path.quadraticBezierTo(x - 30, size.height * 0.35, x, size.height * 0.2);
      path.relativeQuadraticBezierTo(30, -50, 0, -70);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paints = [
      Paint()..color = const Color(0xFF6B7B8D).withValues(alpha: 0.18),
      Paint()..color = const Color(0xFF8A9BA8).withValues(alpha: 0.15),
      Paint()..color = const Color(0xFFA0B0B8).withValues(alpha: 0.12),
    ];

    final offsets = [0.0, 30.0, 60.0];
    for (int i = 0; i < 3; i++) {
      final path = Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width * 0.1, size.height * 0.6 - offsets[i])
        ..lineTo(size.width * 0.3, size.height * 0.35 - offsets[i])
        ..lineTo(size.width * 0.5, size.height * 0.55 - offsets[i])
        ..lineTo(size.width * 0.7, size.height * 0.25 - offsets[i])
        ..lineTo(size.width * 0.9, size.height * 0.5 - offsets[i])
        ..lineTo(size.width, size.height * 0.65 - offsets[i])
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, paints[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RicePaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x12C43A31)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

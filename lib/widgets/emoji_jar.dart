import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jar_provider.dart';
import '../providers/entry_provider.dart';
import '../l10n/app_localizations.dart';

/// A stylised glass jar widget showing emotions as emoji.
///
/// By default loads today's emotions from [JarProvider] via [date].
/// Pass [emotionsOverride] to supply an explicit list instead.
class EmojiJarWidget extends StatelessWidget {
  final DateTime date;
  final double size;
  final List<String>? emotionsOverride;
  final bool canUseAI;
  final bool isToday;
  final List<Map<String, String>> existingReflections;
  final int maxPerDay;
  final VoidCallback? onReflectionSaved;

  const EmojiJarWidget({
    super.key,
    required this.date,
    this.size = 160,
    this.emotionsOverride,
    this.canUseAI = false,
    this.isToday = false,
    this.existingReflections = const [],
    this.maxPerDay = 3,
    this.onReflectionSaved,
  });

  static const int _maxVisible = 30;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entryCount = context.watch<EntryProvider>().allEntries.length;
    final emotions = emotionsOverride ??
        context.watch<JarProvider>().getDayEmotions(date);

    final int overflowCount =
        emotions.length > _maxVisible ? emotions.length - _maxVisible : 0;
    final List<String> visible = overflowCount > 0
        ? emotions.sublist(0, _maxVisible)
        : emotions;

    final double emojiFontSize = visible.length > 15
        ? size * 0.085
        : size * 0.12;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            SizedBox(
              width: size,
              height: size * 1.1,
              child: CustomPaint(
                painter: _JarPainter(),
                child: ClipPath(
                  clipper: _JarClipper(),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        size * 0.1, size * 0.18, size * 0.1, size * 0.08),
                    child: visible.isEmpty
                        ? Center(
                            child: Text(
                              l.emojiJarEmpty,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: size * 0.18,
                              ),
                            ),
                          )
                        : _EmojiGrid(
                            emojis: visible,
                            fontSize: emojiFontSize,
                            seed: date.millisecondsSinceEpoch,
                          ),
                  ),
                ),
              ),
            ),
            if (overflowCount > 0)
              Positioned(
                top: size * 0.18,
                right: size * 0.06,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+$overflowCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.07,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  final List<String> emojis;
  final double fontSize;
  final int seed;

  const _EmojiGrid({
    required this.emojis,
    required this.fontSize,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(seed);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (emojis.isEmpty || constraints.maxWidth <= 0) {
          return const SizedBox.shrink();
        }
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final emojiSize = fontSize * 1.5;
        final cols = (w / emojiSize).floor().clamp(1, 20);
        final rows = (h / emojiSize).floor().clamp(1, 20);

        final cellW = w / cols;
        final cellH = h / rows;

        return Stack(
          children: List.generate(emojis.length, (i) {
            final col = i % cols;
            final row = i ~/ cols;
            final jitterX = (rng.nextDouble() - 0.5) * cellW * 0.5;
            final jitterY = (rng.nextDouble() - 0.5) * cellH * 0.5;
            final rotation = (rng.nextDouble() - 0.5) * 0.3;

            return Positioned(
              left: col * cellW + cellW * 0.5 - emojiSize * 0.5 + jitterX,
              top: row * cellH + cellH * 0.5 - emojiSize * 0.5 + jitterY,
              child: Transform.rotate(
                angle: rotation,
                child: Text(
                  emojis[i],
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _JarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _jarPath(size);

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFDF8F3), Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final highlightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x66FFFFFF), Color(0x22FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, highlightPaint);

    final rimPaint = Paint()
      ..color = const Color(0xFFE0C9A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, rimPaint);

    final shinePath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.22)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.35,
          size.width * 0.12, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.35,
          size.width * 0.28, size.height * 0.25)
      ..close();
    final shinePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x44FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(
          size.width * 0.1, size.height * 0.2,
          size.width * 0.2, size.height * 0.4))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(shinePath, shinePaint);

    final lidY = size.height * 0.15;
    final lidPaint = Paint()
      ..color = const Color(0xFFD4B896)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(size.width * 0.22, lidY - 2),
      Offset(size.width * 0.78, lidY - 2),
      lidPaint,
    );
    final lidFillPaint = Paint()
      ..color = const Color(0xFFE8D5B7)
      ..style = PaintingStyle.fill;
    final lidPath = Path()
      ..moveTo(size.width * 0.2, lidY - 6)
      ..quadraticBezierTo(size.width * 0.5, lidY - 8,
          size.width * 0.8, lidY - 6)
      ..lineTo(size.width * 0.8, lidY)
      ..lineTo(size.width * 0.2, lidY)
      ..close();
    canvas.drawPath(lidPath, lidFillPaint);
    canvas.drawPath(lidPath, Paint()
      ..color = const Color(0xFFC4A882)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
  }

  Path _jarPath(Size size) {
    final w = size.width;
    final h = size.height;
    final neckW = w * 0.45;
    final neckH = h * 0.15;
    final bodyTop = h * 0.15;
    final bodyH = h * 0.85;
    final bodyW = w;

    return Path()
      ..moveTo(w * 0.5 - neckW * 0.5, neckH)
      ..lineTo(w * 0.5 - neckW * 0.5, bodyTop)
      ..quadraticBezierTo(-w * 0.03, bodyTop + bodyH * 0.5,
          w * 0.5 - w * 0.5, bodyTop + bodyH)
      ..quadraticBezierTo(w * 0.5, bodyTop + bodyH + bodyW * 0.15,
          w * 0.5 + w * 0.5, bodyTop + bodyH)
      ..quadraticBezierTo(w * 1.03, bodyTop + bodyH * 0.5,
          w * 0.5 + neckW * 0.5, bodyTop)
      ..lineTo(w * 0.5 + neckW * 0.5, neckH)
      ..quadraticBezierTo(w * 0.5 + neckW * 0.5 + 4, -neckH * 0.3,
          w * 0.5, -neckH * 0.1)
      ..quadraticBezierTo(w * 0.5 - neckW * 0.5 - 4, -neckH * 0.3,
          w * 0.5 - neckW * 0.5, neckH)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _JarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final neckW = w * 0.45;
    final neckH = h * 0.15;
    final bodyTop = h * 0.15;
    final bodyH = h * 0.85;

    return Path()
      ..moveTo(w * 0.5 - neckW * 0.5, bodyTop + 2)
      ..quadraticBezierTo(-w * 0.03, bodyTop + bodyH * 0.5,
          w * 0.5 - w * 0.5, bodyTop + bodyH)
      ..quadraticBezierTo(w * 0.5, bodyTop + bodyH + w * 0.15,
          w * 0.5 + w * 0.5, bodyTop + bodyH)
      ..quadraticBezierTo(w * 1.03, bodyTop + bodyH * 0.5,
          w * 0.5 + neckW * 0.5, bodyTop + 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/note_card.dart';
import '../../providers/locale_provider.dart';

/// Full-screen preview of a rendered Keepsake card PNG.
/// Share and edit actions available.
class CardPreviewScreen extends StatelessWidget {
  final NoteCard card;

  const CardPreviewScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: Semantics(
            identifier: 'btn_card_preview_back',
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text(isZh ? '纪念预览' : 'Keepsake Preview'),
          actions: [
            Semantics(
              identifier: 'btn_edit_card',
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: isZh ? '编辑' : 'Edit',
                onPressed: () => _handleEdit(context),
              ),
            ),
            Semantics(
              identifier: 'btn_share_card',
              child: IconButton(
                icon: const Icon(Icons.share),
                tooltip: isZh ? '分享' : 'Share',
                onPressed: () => _handleShare(context),
              ),
            ),
          ],
        ),
        body: Center(
          child: _buildImage(context),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final path = card.renderedImagePath;
    if (path == null || !File(path).existsSync()) {
      // Re-render case: path missing (e.g. after restore)
      return _buildReRenderPlaceholder(context);
    }

    return InteractiveViewer(
      panEnabled: false,
      minScale: 0.5,
      maxScale: 3.0,
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildReRenderPlaceholder(context),
      ),
    );
  }

  Widget _buildReRenderPlaceholder(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.white54),
        const SizedBox(height: 16),
        Text(
          isZh ? '图片不可用' : 'Image unavailable',
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _handleEdit(context),
          icon: const Icon(Icons.refresh),
          label: Text(isZh ? '重新渲染' : 'Re-render'),
        ),
      ],
    );
  }

  void _handleShare(BuildContext context) {
    final path = card.renderedImagePath;
    if (path == null || !File(path).existsSync()) {
      return;
    }
    SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
  }

  void _handleEdit(BuildContext context) {
    Navigator.pop(context, 'edit');
  }
}

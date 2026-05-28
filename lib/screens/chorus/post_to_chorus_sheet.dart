import 'package:flutter/material.dart';
import '../../core/services/chorus_service.dart';

// The 22 curated Chorus tags — must match blinkingchorus.com exactly.
const _chorustags = [
  // body
  ('walks', '🚶 #walks'),
  ('rest', '🌙 #rest'),
  ('water', '💧 #water'),
  ('movement', '🏃 #movement'),
  ('sleep', '😴 #sleep'),
  ('food', '🍜 #food'),
  // mind
  ('breath', '🫁 #breath'),
  ('gratitude', '🙏 #gratitude'),
  ('mood', '😌 #mood'),
  ('pause', '⏸ #pause'),
  // connection
  ('calls', '📞 #calls'),
  ('kindness', '💛 #kindness'),
  ('family', '👨‍👩‍👧 #family'),
  ('love', '❤️ #love'),
  ('pets', '🐾 #pets'),
  // noticing
  ('nature', '🌿 #nature'),
  ('sky', '☁️ #sky'),
  ('reading', '📖 #reading'),
  ('music', '🎵 #music'),
  ('quiet', '🤫 #quiet'),
  // making
  ('cooking', '🍳 #cooking'),
  ('creativity', '🎨 #creativity'),
];

const _maxChars = 500;

enum _SheetState { composing, submitting, success, error }

class PostToChorusSheet extends StatefulWidget {
  final String initialText;

  const PostToChorusSheet({super.key, required this.initialText});

  /// Opens the sheet and returns true if the post was successfully submitted.
  static Future<bool> show(BuildContext context, {required String initialText}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostToChorusSheet(initialText: initialText),
    );
    return result ?? false;
  }

  @override
  State<PostToChorusSheet> createState() => _PostToChorusSheetState();
}

class _PostToChorusSheetState extends State<PostToChorusSheet> {
  late final TextEditingController _textController;
  final TextEditingController _cityController = TextEditingController();
  final _service = ChorusService();

  String? _selectedTag;
  _SheetState _state = _SheetState.composing;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Pre-fill with entry content, truncated to max chars.
    final initial = widget.initialText.length > _maxChars
        ? widget.initialText.substring(0, _maxChars)
        : widget.initialText;
    _textController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _textController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _state = _SheetState.submitting);

    final result = await _service.postNote(
      text: text,
      tag: _selectedTag,
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
    );

    if (!mounted) return;

    switch (result) {
      case ChorusPostSuccess():
        setState(() => _state = _SheetState.success);
      case ChorusPostRateLimited():
        setState(() {
          _state = _SheetState.error;
          _errorMessage = "You've reached the posting limit. Try again in an hour.";
        });
      case ChorusPostValidationError(:final message):
        setState(() {
          _state = _SheetState.error;
          _errorMessage = message;
        });
      case ChorusPostNetworkError():
        setState(() {
          _state = _SheetState.error;
          _errorMessage = "Couldn't reach the chorus. Check your connection.";
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8F1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: _state == _SheetState.success
            ? _buildSuccess()
            : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFF6B8E77),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 16),
        const Text(
          "You're in the chorus.",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2A2E2A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your blink is live on the wall. Someone in another timezone will see it within the minute.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF55605A)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6B8E77),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildForm() {
    final charCount = _textController.text.length;
    final isSubmitting = _state == _SheetState.submitting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5DECC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Header
        const Text(
          'Post to the chorus',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2A2E2A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Anonymous · no name, no email · live on blinkingchorus.com',
          style: TextStyle(fontSize: 12, color: Color(0xFF8A918C)),
        ),
        const SizedBox(height: 16),

        // Text field
        TextField(
          controller: _textController,
          enabled: !isSubmitting,
          maxLength: _maxChars,
          maxLines: 5,
          minLines: 3,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2A2E2A),
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: 'What\'s a small thing today?',
            hintStyle: const TextStyle(color: Color(0xFF8A918C), fontStyle: FontStyle.italic),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5DECC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5DECC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6B8E77)),
            ),
            counterText: '$charCount / $_maxChars',
            counterStyle: TextStyle(
              color: charCount > _maxChars * 0.9 ? const Color(0xFFC66B4A) : const Color(0xFF8A918C),
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),

        // Tag picker label
        const Text(
          'Tag (optional)',
          style: TextStyle(fontSize: 13, color: Color(0xFF55605A), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _chorustags.map((t) {
            final isSelected = _selectedTag == t.$1;
            return GestureDetector(
              onTap: isSubmitting ? null : () {
                setState(() => _selectedTag = isSelected ? null : t.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFCFDCCF) : const Color(0xFFEFE9DB),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6B8E77) : Colors.transparent,
                  ),
                ),
                child: Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF4F7360) : const Color(0xFF55605A),
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // City input
        const Text(
          'City (optional)',
          style: TextStyle(fontSize: 13, color: Color(0xFF55605A), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _cityController,
          enabled: !isSubmitting,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 15, color: Color(0xFF2A2E2A)),
          decoration: InputDecoration(
            hintText: 'Leave blank, or type a city',
            hintStyle: const TextStyle(color: Color(0xFF8A918C)),
            filled: true,
            fillColor: const Color(0xFFEFE9DB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6B8E77)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),

        // Error message
        if (_state == _SheetState.error) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFC66B4A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC66B4A).withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFFC66B4A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFC66B4A)),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC66B4A),
              disabledBackgroundColor: const Color(0xFFC66B4A).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: (isSubmitting || _textController.text.trim().isEmpty) ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Let it blink',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8A918C))),
          ),
        ),
      ],
    );
  }
}

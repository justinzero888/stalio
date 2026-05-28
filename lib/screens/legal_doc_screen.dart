import 'package:flutter/material.dart';

/// Generic scrollable legal document viewer (Privacy Policy, Terms of Service).
class LegalDocScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          content,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}

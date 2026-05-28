import 'package:flutter/material.dart';

/// Lightweight notifier that fires whenever the LLM provider config changes
/// (API key saved, provider switched, provider added/removed).
///
/// FloatingRobotWidget listens to this to immediately re-check hasApiKey()
/// without waiting for a full widget rebuild cycle.
class LlmConfigNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

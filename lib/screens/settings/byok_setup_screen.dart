import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../providers/locale_provider.dart';
import '../../providers/llm_config_notifier.dart';
import '../../core/services/entitlement_service.dart';

class ByokSetupScreen extends StatefulWidget {
  const ByokSetupScreen({super.key});

  @override
  State<ByokSetupScreen> createState() => _ByokSetupScreenState();
}

class _ByokSetupScreenState extends State<ByokSetupScreen> {
  final _keyController = TextEditingController();
  String _selectedProvider = 'openai';
  bool _isTesting = false;
  String? _errorText;

  final _providers = const [
    {'id': 'openai', 'name': 'OpenAI', 'prefix': 'sk-', 'url': 'https://api.openai.com/v1/chat/completions', 'keyUrl': 'https://platform.openai.com/api-keys'},
    {'id': 'anthropic', 'name': 'Anthropic', 'prefix': 'sk-ant-', 'url': 'https://api.anthropic.com/v1/messages', 'keyUrl': 'https://console.anthropic.com/settings/keys'},
    {'id': 'openrouter', 'name': 'OpenRouter', 'prefix': 'sk-or-', 'url': 'https://openrouter.ai/api/v1/chat/completions', 'keyUrl': 'https://openrouter.ai/keys'},
    {'id': 'google', 'name': 'Google Gemini', 'prefix': 'AI', 'url': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent', 'keyUrl': 'https://aistudio.google.com/apikey'},
    {'id': 'deepseek', 'name': 'DeepSeek', 'prefix': 'sk-', 'url': 'https://api.deepseek.com/v1/chat/completions', 'keyUrl': 'https://platform.deepseek.com/api_keys'},
    {'id': 'groq', 'name': 'Groq', 'prefix': 'gsk_', 'url': 'https://api.groq.com/openai/v1/chat/completions', 'keyUrl': 'https://console.groq.com/keys'},
  ];

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final entitlement = context.read<EntitlementService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '使用自己的 Key' : 'Use my own key'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPrivacyBanner(isZh),
            const SizedBox(height: 24),
            _buildProviderSelector(isZh),
            const SizedBox(height: 20),
            _buildKeyField(isZh),
            const SizedBox(height: 12),
            _buildWhereToGetKey(isZh),
            const SizedBox(height: 24),
            _buildTestButton(isZh, entitlement),
            const SizedBox(height: 24),
            _buildAdvancedSection(isZh),
            const SizedBox(height: 24),
            _buildDisclaimer(isZh),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyBanner(bool isZh) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.shield_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(isZh ? '你的数据直接发送至模型提供商。Blinking 不会看到它。' : 'Your data goes straight to the model provider. Blinking never sees it.', style: Theme.of(context).textTheme.bodyMedium)),
            ]),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showPrivacySheet(context, isZh),
              child: Text(isZh ? '为什么？' : 'Why?', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelector(bool isZh) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(isZh ? '提供商' : 'Provider', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: _selectedProvider,
        items: _providers.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['name'] as String))).toList(),
        onChanged: (v) => setState(() => _selectedProvider = v!),
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
    ]);
  }

  Widget _buildKeyField(bool isZh) {
    return TextField(
      controller: _keyController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'API Key',
        hintText: _providers.firstWhere((p) => p['id'] == _selectedProvider)['prefix'] as String,
        errorText: _errorText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildWhereToGetKey(bool isZh) {
    final provider = _providers.firstWhere((p) => p['id'] == _selectedProvider);
    return GestureDetector(
      onTap: () async {
        final url = provider['keyUrl'] as String;
        try { await launchUrl(Uri.parse(url)); } catch (_) {}
      },
      child: Text(
        isZh ? '从哪里获取 ${provider['name']} API Key →' : 'Where to get ${provider['name']} API key →',
        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, decoration: TextDecoration.underline),
      ),
    );
  }

  Widget _buildTestButton(bool isZh, EntitlementService entitlement) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: _isTesting ? null : () => _testAndSave(isZh, entitlement),
        child: _isTesting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isZh ? '验证并保存' : 'Test & Save'),
      ),
    );
  }

  Widget _buildAdvancedSection(bool isZh) {
    return ExpansionTile(
      title: Text(isZh ? '高级设置' : 'Advanced'),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(isZh ? '默认自动选择最佳模型。高级用户可以在此覆盖。' : 'Default model is auto-selected. Advanced users can override here.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildDisclaimer(bool isZh) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isZh
                  ? 'AI 功能需要您自行提供 API Key。您需自行承担：\n'
                    '• API Key 的安全保管\n'
                    '• 使用 AI 服务产生的 Token 费用\n'
                    '• 发送给 AI 提供商的数据隐私（受该提供商条款约束）\n'
                    'Blinking 不收集任何您的数据，AI 请求由您的设备直接发送至 AI 提供商。'
                  : 'The AI feature requires your own API key. You are responsible for:\n'
                    '• Keeping your API key secure\n'
                    '• Any token costs charged by your AI provider\n'
                    '• Data privacy with your AI provider (governed by their terms)\n'
                    'Blinking does not collect your data. AI requests are sent directly from your device to the AI provider.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade900,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testAndSave(bool isZh, EntitlementService entitlement) async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _errorText = isZh ? '请输入 API Key' : 'Please enter an API key');
      return;
    }

    final provider = _providers.firstWhere((p) => p['id'] == _selectedProvider);
    final prefix = provider['prefix'] as String;
    if (!key.startsWith(prefix)) {
      setState(
          () => _errorText = isZh ? 'Key 格式不正确' : 'Key format looks wrong');
      return;
    }

    setState(() {
      _isTesting = true;
      _errorText = null;
    });

    try {
      final baseUrl = provider['url'] as String;
      final testResult = await _pingKey(baseUrl, key, _selectedProvider);

      if (testResult == 'ok') {
        await _saveKey(provider['name'] as String, key, baseUrl);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('entitlement_byok_validated', true);
        context.read<LlmConfigNotifier>().notify();
        entitlement.refresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isZh
                  ? '已连接。你的 AI 现在使用自己的 Key。'
                  : 'Connected. Your AI now uses your own key.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorText = _errorMessage(testResult, isZh);
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = isZh ? '无法连接，请检查网络' : "Couldn't connect. Check your network.";
          _isTesting = false;
        });
      }
    }
  }

  Future<String> _pingKey(
      String baseUrl, String key, String providerId) async {
    try {
      final uri = Uri.parse(baseUrl);
      http.Response response;

      if (providerId == 'google') {
        final googleUri = Uri.parse('$baseUrl?key=$key');
        response = await http.post(
          googleUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'parts': [{'text': 'OK'}]}
            ],
            'generationConfig': {'maxOutputTokens': 1},
          }),
        ).timeout(const Duration(seconds: 10));
      } else if (providerId == 'anthropic') {
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': key,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-3-haiku-20240307',
            'max_tokens': 1,
            'messages': [
              {'role': 'user', 'content': 'OK'}
            ],
          }),
        ).timeout(const Duration(seconds: 10));
      } else {
        // OpenAI-compatible: OpenAI, OpenRouter, DeepSeek, Groq
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          body: jsonEncode({
            'model': providerId == 'openrouter'
                ? 'openai/gpt-3.5-turbo'
                : 'gpt-3.5-turbo',
            'max_tokens': 1,
            'messages': [
              {'role': 'user', 'content': 'OK'}
            ],
          }),
        ).timeout(const Duration(seconds: 10));
      }

      if (response.statusCode == 200) return 'ok';
      if (response.statusCode == 401 || response.statusCode == 403) {
        return 'auth_failed';
      }
      if (response.statusCode == 429) return 'rate_limited';
      if (response.statusCode == 402) return 'no_credits';
      return 'unknown_${response.statusCode}';
    } catch (_) {
      return 'network_error';
    }
  }

  String _errorMessage(String code, bool isZh) {
    switch (code) {
      case 'auth_failed':
        return isZh
            ? 'Key 未被接受。请检查是否正确且未被撤销。'
            : "That key wasn't accepted. Double-check it's correct and hasn't been revoked.";
      case 'rate_limited':
        return isZh
            ? '你的账户被限速。请稍后再试。'
            : 'Your provider account is rate-limited. Try again in a minute.';
      case 'no_credits':
        return isZh
            ? '你的账户没有余额。请在提供商面板添加账单。'
            : "Your provider account doesn't have credits. Add billing on the provider dashboard.";
      case 'network_error':
        return isZh ? '无法连接到提供商。请检查网络。' : "Couldn't reach the provider. Check your connection.";
      default:
        return isZh ? '出错了。代码：$code' : 'Something went wrong. Code: $code';
    }
  }

  Future<void> _saveKey(
      String providerName, String key, String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('llm_providers');
    List<dynamic> providers = jsonStr != null ? jsonDecode(jsonStr) : [];

    final existingIdx = providers.indexWhere(
        (p) => p is Map && (p['name'] == providerName));

    final entry = {
      'name': providerName,
      'model': 'auto',
      'apiKey': key,
      'baseUrl': baseUrl,
    };

    if (existingIdx >= 0) {
      providers[existingIdx] = entry;
    } else {
      providers.add(entry);
    }

    await prefs.setString('llm_providers', jsonEncode(providers));
    await prefs.setInt('llm_selected_index', providers.length - 1);
  }

  void _showPrivacySheet(BuildContext context, bool isZh) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isZh ? '你的 AI 请求去向' : 'Where your AI requests go',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                isZh
                    ? '使用自己的 Key 时，每个 AI 请求直接从你的手机发送至提供商，响应也直接返回至你的手机。Blinking 不会看到请求、响应或你的 Key。\n\n'
                        '使用内置 AI 时，请求经过 Blinking 服务器（以便管理你的配额），然后转发至提供商。我们不会存储内容，仅统计调用次数。\n\n'
                        '无论哪种方式，提供商按照自己的隐私政策处理内容。'
                    : 'When you use your own key, every AI request goes from your phone directly to the provider and the response comes back to your phone. Blinking never sees the request, the response, or your key.\n\n'
                        'When you use the included AI, requests go through Blinking\'s server (so we can manage your quota) before being forwarded to the provider. We don\'t store the content; we count the call.\n\n'
                        'Either way, the provider processes the content under their own privacy policy.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isZh ? '关闭' : 'Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

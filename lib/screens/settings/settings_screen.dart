import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/voice_notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final storage = context.read<StorageService>();
    final voiceEnabled = storage.getVoiceEnabled();

    return Scaffold(
      appBar: AppBar(title: Text(isZh ? '设置' : 'Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(isZh ? '语音提醒' : 'Voice Reminders'),
            subtitle: Text(isZh ? '在设定的时间朗读习惯名称' : 'Speak habit names at scheduled times'),
            value: voiceEnabled,
            onChanged: (value) {
              storage.setVoiceEnabled(value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

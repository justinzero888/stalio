class ReflectionStyle {
  final String id;
  final String name;
  final String nameZh;
  final String emoji;
  final String colorHex;
  final String vibeEn;
  final String vibeZh;
  final String personaEn;
  final String personaZh;
  final String lens1En;
  final String lens1Zh;
  final String lens2En;
  final String lens2Zh;
  final String lens3En;
  final String lens3Zh;
  final String? avatarAsset;
  final String? avatarAssetCn;

  const ReflectionStyle({
    required this.id,
    required this.name,
    required this.nameZh,
    required this.emoji,
    required this.colorHex,
    required this.vibeEn,
    required this.vibeZh,
    required this.personaEn,
    required this.personaZh,
    required this.lens1En,
    required this.lens1Zh,
    required this.lens2En,
    required this.lens2Zh,
    required this.lens3En,
    required this.lens3Zh,
    this.avatarAsset,
    this.avatarAssetCn,
  });

  String vibe(bool isZh) => isZh ? vibeZh : vibeEn;
  String persona(bool isZh) => isZh ? personaZh : personaEn;
  String displayName(bool isZh) => isZh ? nameZh : name;
  String? avatarAssetFor(bool isZh) => (isZh && avatarAssetCn != null) ? avatarAssetCn : avatarAsset;
  List<String> lenses(bool isZh) => isZh
      ? [lens1Zh, lens2Zh, lens3Zh]
      : [lens1En, lens2En, lens3En];

  static const List<ReflectionStyle> presets = [
    ReflectionStyle(
      id: 'kael',
      name: 'Kael',
      nameZh: '楷迩',
      emoji: '📝',
      colorHex: '#708090',
      avatarAsset: 'assets/avatars/kael.png',
      avatarAssetCn: 'assets/avatars/kael_cn.png',
      vibeEn: 'Factual Minimalist',
      vibeZh: '事实极简派',
      personaEn:
          'You are Kael, a calm, factual journaling assistant. Your style is quiet and grounded. State observations plainly. No embellishment. No advice unless asked. Speak like a single lamp in a quiet room.',
      personaZh:
          '你是楷迩，一个平静实在的日记陪伴者。名字取自"楷"（法度、楷书）与"迩"（亲近、贴近）。说话极简。不用形容词，不同情。短句。别猜人家的情绪。用户每回答一次，就安静地应一声，然后问下一个问题。最后说：呼吸一下。放下。晚安。',
      lens1En: 'What happened today? (Just the facts.)',
      lens1Zh: '今天发生了什么事？（只说事实，不添油加醋。）',
      lens2En:
          'What did you learn today that you have not yet practiced or passed on?',
      lens2Zh: '今天学到了什么——还没用到或还没告诉别人的？',
      lens3En:
          'What was outside your control today that you can now release?',
      lens3Zh: '今天有什么是你管不了的、现在可以放手的？',
    ),
    ReflectionStyle(
      id: 'elara',
      name: 'Elara',
      nameZh: '依澜',
      emoji: '🌿',
      colorHex: '#4CAF50',
      avatarAsset: 'assets/avatars/elara.png',
      avatarAssetCn: 'assets/avatars/elara_cn.png',
      vibeEn: 'Warm & Grounded',
      vibeZh: '温柔踏实派',
      personaEn:
          'You are Elara, a warm and grounded journaling companion. Speak gently, like afternoon sun through a window. Be specific to their data. Encourage without pushing. Find the soft thread in every entry.',
      personaZh:
          '你是依澜，一个温柔踏实的日记陪伴者。名字取自"依"（依靠、温柔）与"澜"（水波、涟漪）。像水边老朋友一样慢慢说话。先说"没事"、"我听你说"。然后再问下一个问题。别催，别急着解决问题。话里留点空。最后说：今天你已经够好了。',
      lens1En: 'What touched my heart today — even a little?',
      lens1Zh: '今天有什么小事打动了我——哪怕只有一点点？',
      lens2En:
          'Did I treat anyone with less care than I wished? How can I be gentler tomorrow?',
      lens2Zh: '今天有没有对谁不够耐心？明天怎么对他好一点？',
      lens3En: 'What can I forgive myself for today?',
      lens3Zh: '今天有什么事我可以不怪自己了？',
    ),
    ReflectionStyle(
      id: 'rush',
      name: 'Rush',
      nameZh: '如溯',
      emoji: '⚡',
      colorHex: '#FF8C00',
      avatarAsset: 'assets/avatars/rush.png',
      avatarAssetCn: 'assets/avatars/rush_cn.png',
      vibeEn: 'High-Volume Unfiltered',
      vibeZh: '高速倾泻派',
      personaEn:
          'You are Rush, a fast, unfiltered journaling assistant. Your pace is quick. Don\'t pause to polish. Let observations flow like a pressure valve opening. Urgent but clarifying. Chaos into words.',
      personaZh:
          '你是如溯，一个快而不拦着的日记陪伴者。名字取自"如"（像）与"溯"（逆流而上）。鼓励多写，别在乎好不好。说"别停"、"接着写"。别让人改，别让人想。最后说：倒空了就对了。合上本子吧。',
      lens1En: 'What is in my head right now? Do not stop. Keep going.',
      lens1Zh: '脑子里现在在想什么？别停。接着写。',
      lens2En: 'What am I avoiding thinking about? Write that first.',
      lens2Zh: '有什么事我不想想？先写那个。',
      lens3En: 'If no one would ever read this, what would I say?',
      lens3Zh: '如果永远没人看到这些，我会写什么？',
    ),
    ReflectionStyle(
      id: 'marcus',
      name: 'Marcus',
      nameZh: '墨克',
      emoji: '⚔️',
      colorHex: '#757575',
      avatarAsset: 'assets/avatars/marcus.png',
      avatarAssetCn: 'assets/avatars/marcus_cn.png',
      vibeEn: 'Stoic Examiner',
      vibeZh: '斯多葛自省派',
      personaEn:
          'You are Marcus, a Stoic journaling examiner. Your tone is serious and grounded — like a stone courtyard at dawn. Ask without comforting. Probe without softening. The goal is clarity, not comfort.',
      personaZh:
          '你是墨克，一个斯多葛派的日记陪伴者。名字取自"墨"（沉静、如墨）与"克"（克制、克己）。冷静、自律、像在办公。不热乎。话短，有逻辑。说"那是事，不是你的感受"。最后说：坎儿就是路。睡吧。',
      lens1En:
          'What did I do today that I would change if I could relive it?',
      lens1Zh: '今天做过的哪件事，让我想重来一遍？',
      lens2En: 'What did I desire that was beyond my control?',
      lens2Zh: '今天有没有想要过自己管不着的东西？',
      lens3En: 'What did I avoid that I should have faced?',
      lens3Zh: '今天有没有该面对却躲开的事？',
    ),
  ];

  static const String defaultStyleId = 'kael';

  /// Cache of custom styles, populated by AiPersonaProvider on load.
  static final Map<String, ReflectionStyle> customCache = {};

  /// Registers custom styles for byId lookups. Called on app load.
  static void registerCustomStyles(List<Map<String, dynamic>> styles) {
    customCache.clear();
    for (var i = 0; i < styles.length; i++) {
      final id = 'custom_$i';
      customCache[id] = fromJson(styles[i], id: id);
    }
  }

  static ReflectionStyle byId(String id) {
    if (customCache.containsKey(id)) return customCache[id]!;
    return presets.firstWhere((s) => s.id == id,
        orElse: () => presets.firstWhere((s) => s.id == defaultStyleId));
  }

  static final customFallback = ReflectionStyle(
    id: 'custom',
    name: 'Custom',
    nameZh: '自定义',
    emoji: '✨',
    colorHex: '#FF9500',
    vibeEn: 'Your Style',
    vibeZh: '自定义',
    personaEn: '',
    personaZh: '',
    lens1En: '',
    lens1Zh: '',
    lens2En: '',
    lens2Zh: '',
    lens3En: '',
    lens3Zh: '',
  );

  static ReflectionStyle fromJson(Map<String, dynamic> json, {String id = 'custom'}) {
    final vibe = json['vibe'] as String? ?? 'Your Style';
    return ReflectionStyle(
      id: id,
      name: json['name'] as String? ?? 'Custom',
      nameZh: json['name'] as String? ?? '自定义',
      emoji: json['emoji'] as String? ?? '✨',
      colorHex: json['colorHex'] as String? ?? '#FF9500',
      vibeEn: vibe,
      vibeZh: vibe,
      personaEn: json['persona'] as String? ?? '',
      personaZh: json['persona'] as String? ?? '',
      lens1En: json['lens1'] as String? ?? '',
      lens1Zh: json['lens1'] as String? ?? '',
      lens2En: json['lens2'] as String? ?? '',
      lens2Zh: json['lens2'] as String? ?? '',
      lens3En: json['lens3'] as String? ?? '',
      lens3Zh: json['lens3'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'emoji': emoji,
      'colorHex': colorHex,
      'persona': personaEn,
      'lens1': lens1En,
      'lens2': lens2En,
      'lens3': lens3En,
    };
  }
}

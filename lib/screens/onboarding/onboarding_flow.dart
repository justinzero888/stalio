import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../providers/locale_provider.dart';

/// 3-screen onboarding flow: Welcome → How It Works → Select Habits → Dashboard
class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentPage = 0;
  late Set<String> _selectedHabitIds;
  List<Routine> _habitList = const [];

  @override
  void initState() {
    super.initState();
    _selectedHabitIds = _defaultBundleIds.toSet();
    _habitList = context.read<RoutineProvider>().routines;
  }

  static const _defaultBundleIds = {
    'seed_H001', 'seed_H003', 'seed_H004', 'seed_H009',
    'seed_H010', 'seed_H023', 'seed_H033', 'seed_H038', 'seed_H051',
  };

  void _goToPage(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _completeOnboarding() async {
    final provider = context.read<RoutineProvider>();
    for (final r in provider.routines) {
      if (!r.id.startsWith('seed_H')) continue;
      if (_selectedHabitIds.contains(r.id)) {
        if (!r.isActive) await provider.activateRoutine(r.id);
      } else {
        if (r.isActive) await provider.deactivateRoutine(r.id);
      }
    }
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (_habitList.isEmpty) {
      _habitList = context.read<RoutineProvider>().routines;
    }

    final screens = [
      _WelcomeScreen(onGetStarted: () => _goToPage(1)),
      _HowItWorksScreen(onSelectHabits: () => _goToPage(2)),
      _SelectHabitsScreen(
        routines: _habitList,
        selectedIds: _selectedHabitIds,
        onToggle: (id) => setState(() {
          if (_selectedHabitIds.contains(id)) {
            _selectedHabitIds.remove(id);
          } else {
            _selectedHabitIds.add(id);
          }
        }),
        onAddMore: _openHabitLibrary,
        onStartTracking: () => _completeOnboarding(),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: screens[_currentPage],
      ),
    );
  }

  Future<void> _openHabitLibrary() async {
    if (!mounted) return;
    final routines = context.read<RoutineProvider>().routines;
    final result = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => _HabitLibraryScreen(
          routines: routines,
          selectedIds: _selectedHabitIds.toSet(),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedHabitIds = result);
    }
  }
}

// ─── Screen 1: Welcome & Philosophy ───────────────────────────────────────────

class _WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  const _WelcomeScreen({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '||//',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: theme.colorScheme.primary,
                    letterSpacing: -2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isZh ? '不积跬步，无以至千里' : 'Do. Tally. Grow.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isZh ? '行 · 计 · 长' : 'Do. Tally. Grow.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary.withAlpha(180),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isZh
                  ? '追踪微习惯与日记的最简方式'
                  : 'The simplest way to track\nyour micro-habits and journal.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onGetStarted,
                child: Text(
                  isZh ? '开始' : 'Get Started',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen 2: How It Works ────────────────────────────────────────────────────

class _HowItWorksScreen extends StatelessWidget {
  final VoidCallback onSelectHabits;
  const _HowItWorksScreen({required this.onSelectHabits});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '如何使用' : 'How It Works',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isZh ? '三种追踪方式：' : 'Three ways to track your day:',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: 24),
          _InteractionCard(
            emoji: '👆',
            title: isZh ? '一键打卡' : 'ONE TAP',
            examples: [
              _InteractionExample(icon: '💧', name: isZh ? '喝水' : 'Drink water', hint: '0/8'),
              _InteractionExample(icon: '🪥', name: isZh ? '用牙线' : 'Floss', hint: ''),
              _InteractionExample(icon: '🌿', name: isZh ? '出门走走' : 'Step outside', hint: ''),
            ],
            tip: isZh ? '点击即可。就这样。' : 'Tap to check. That\'s it.',
          ),
          const SizedBox(height: 16),
          _InteractionCard(
            emoji: '🔢',
            title: isZh ? '输入数字' : 'ONE NUMBER',
            examples: [
              _InteractionExample(
                icon: '🚶',
                name: isZh ? '走 5000 步' : 'Walk 5000 steps',
                hint: '0/5000',
              ),
            ],
            tip: isZh ? '输入数字。保存。' : 'Enter your number. Tap save.',
          ),
          const SizedBox(height: 16),
          _InteractionCard(
            emoji: '✏️',
            title: isZh ? '写笔记' : 'ONE NOTE',
            examples: [
              _InteractionExample(
                icon: '✏️',
                name: isZh ? '写一则笔记' : 'Write a note',
                hint: '',
              ),
            ],
            tip: isZh ? '写下内容。保存。' : 'Write something. Tap save.',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.help_outline, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isZh ? '需要帮助？点击任何习惯上的 (?)' : 'Need help? Tap the (?) on any habit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withAlpha(200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onSelectHabits,
              child: Text(
                isZh ? '选择你的习惯' : 'Select Your Habits',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final List<_InteractionExample> examples;
  final String tip;

  const _InteractionCard({
    required this.emoji,
    required this.title,
    required this.examples,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...examples.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(e.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(
                        e.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      if (e.hint.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(e.hint, style: theme.textTheme.bodySmall),
                        ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Text(tip, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary.withAlpha(200),
              fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }
}

class _InteractionExample {
  final String icon;
  final String name;
  final String hint;
  const _InteractionExample({required this.icon, required this.name, this.hint = ''});
}

// ─── Screen 3: Select Habits ───────────────────────────────────────────────────

class _SelectHabitsScreen extends StatelessWidget {
  final List<Routine> routines;
  final Set<String> selectedIds;
  final Function(String id) onToggle;
  final VoidCallback onAddMore;
  final VoidCallback onStartTracking;

  const _SelectHabitsScreen({
    required this.routines,
    required this.selectedIds,
    required this.onToggle,
    required this.onAddMore,
    required this.onStartTracking,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);
    final displayHabits = routines
        .where((r) => r.id.startsWith('seed_H') &&
            (r.isDefaultBundle || selectedIds.contains(r.id)))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isZh ? '你的习惯' : 'Your Habits',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                isZh ? '点击选择。所有习惯日后均可更改。' : 'Tap to toggle. All habits can be changed later.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isZh ? '已选：${selectedIds.length} 个习惯' : 'Selected: ${selectedIds.length} habits',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayHabits.length,
            itemBuilder: (ctx, i) {
              final routine = displayHabits[i];
              final isSelected = selectedIds.contains(routine.id);
              return _HabitToggleTile(
                routine: routine,
                isSelected: isSelected,
                onToggle: () => onToggle(routine.id),
                isZh: isZh,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddMore,
              icon: const Icon(Icons.add, size: 20),
              label: Text(isZh ? '从库中添加更多' : 'Add more from library'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onStartTracking,
              child: Text(
                isZh ? '开始追踪 →' : 'Start Tracking →',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Habit Toggle Tile (shared by Select Habits + Library) ──────────────────────

class _HabitToggleTile extends StatelessWidget {
  final Routine routine;
  final bool isSelected;
  final VoidCallback onToggle;
  final bool isZh;

  const _HabitToggleTile({
    required this.routine,
    required this.isSelected,
    required this.onToggle,
    required this.isZh,
  });

  String get _trackingLabel {
    return switch (routine.trackingUiType) {
      TrackingUiType.boolean => '✓/✗',
      TrackingUiType.booleanOptionalText => '✓/+',
      TrackingUiType.duration => routine.trackingUnit == 'minutes' ? '⏱ ${routine.trackingTarget?.toInt() ?? 0}min' : '⏱',
      TrackingUiType.durationOptionalText => '⏱ ${routine.trackingTarget?.toInt() ?? 0}min',
      TrackingUiType.number => '📊 ${routine.trackingTarget?.toInt() ?? 0}',
      TrackingUiType.time => '⏰',
      TrackingUiType.scale => '😊 1-5',
      TrackingUiType.scaleOptionalText => '😊 1-5',
      TrackingUiType.textRequired => '📝',
      TrackingUiType.multiTextRequired => '📝×3',
      TrackingUiType.streak => '🔥',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary.withAlpha(80)
              : theme.colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected
                      ? null
                      : Border.all(color: theme.colorScheme.outline.withAlpha(80)),
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                routine.icon ?? routine.effectiveIcon,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  routine.displayName(isZh),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _trackingLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(160),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Full Habit Library ─────────────────────────────────────────────────────────

class _HabitLibraryScreen extends StatefulWidget {
  final Set<String> selectedIds;
  final List<Routine> routines;

  const _HabitLibraryScreen({
    required this.selectedIds,
    required this.routines,
  });

  @override
  State<_HabitLibraryScreen> createState() => _HabitLibraryScreenState();
}

class _HabitLibraryScreenState extends State<_HabitLibraryScreen> {
  late Set<String> _selectedIds;
  String _searchQuery = '';
  String? _categoryFilter;

  static const _categoryGroups = [
    ('Health & Body', '身'),
    ('Social & Relationship', '缘'),
    ('Productivity & Growth', '长'),
    ('Financial', '财'),
    ('Home & Environment', '居'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedIds.toSet();
  }

  List<Routine> _filteredRoutines() {
    var list = widget.routines
        .where((r) => r.id.startsWith('seed_H'))
        .toList();

    if (_categoryFilter != null) {
      list = list.where((r) => r.categoryGroup == _categoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) =>
          r.name.toLowerCase().contains(q) ||
          r.nameEn.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);
    final filtered = _filteredRoutines();

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '所有习惯' : 'All Habits'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedIds),
            child: Text(
              isZh ? '保存' : 'Save',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: isZh ? '搜索习惯...' : 'Search habits...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(80)),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(isZh ? '全部' : 'All'),
                    selected: _categoryFilter == null,
                    onSelected: (_) => setState(() => _categoryFilter = null),
                  ),
                ),
                for (final (en, cn) in _categoryGroups)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(isZh ? '$cn $en' : en),
                      selected: _categoryFilter == en,
                      onSelected: (_) => setState(() => _categoryFilter = en),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  isZh ? '已选：${_selectedIds.length}' : 'Selected: ${_selectedIds.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final routine = filtered[i];
                final isSelected = _selectedIds.contains(routine.id);
                return _HabitToggleTile(
                  routine: routine,
                  isSelected: isSelected,
                  isZh: isZh,
                  onToggle: () => setState(() {
                    if (isSelected) {
                      _selectedIds.remove(routine.id);
                    } else {
                      _selectedIds.add(routine.id);
                    }
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

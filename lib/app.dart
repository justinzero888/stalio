import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/entitlement_service.dart';
import 'core/services/purchases_service.dart';
import 'repositories/repositories.dart';
import 'providers/routine_provider.dart';
import 'providers/entry_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/jar_provider.dart';
import 'providers/summary_provider.dart';
import 'providers/card_provider.dart';
import 'providers/ai_persona_provider.dart';
import 'providers/llm_config_notifier.dart';
import 'screens/home/home_screen.dart';
import 'screens/moment/moment_screen.dart';
import 'screens/routine/routine_screen.dart';
import 'screens/cherished/cherished_memory_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/onboarding/transition_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/add_entry_screen.dart';
import 'screens/purchase/paywall_screen.dart';
import 'widgets/floating_robot.dart';
import 'l10n/app_localizations.dart';
import 'models/entry.dart';

import 'core/services/export_service.dart';

class BlinkingApp extends StatelessWidget {
  final StorageService storageService;
  final PurchasesService purchasesService;

  const BlinkingApp({super.key, required this.storageService, required this.purchasesService});

  @override
  Widget build(BuildContext context) {
    // Create repositories
    final entryRepository = EntryRepository(storageService);
    final routineRepository = RoutineRepository(storageService);
    final tagRepository = TagRepository(storageService);

    return MultiProvider(
      providers: [
        // Services
        Provider<StorageService>.value(value: storageService),
        Provider<ExportService>(
          create: (context) => ExportService(storageService),
        ),

        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),

        // Locale provider
        ChangeNotifierProvider(create: (_) {
          final provider = LocaleProvider();
          provider.loadLocale();
          return provider;
        }),

        // Repository providers
        Provider<EntryRepository>.value(value: entryRepository),
        Provider<RoutineRepository>.value(value: routineRepository),
        Provider<TagRepository>.value(value: tagRepository),

        // Main data providers
        ChangeNotifierProvider(
          create: (_) => EntryProvider(entryRepository)..loadEntries(),
        ),
        ChangeNotifierProvider(
          create: (_) => RoutineProvider(routineRepository)
            ..loadRoutines(),
        ),
        ChangeNotifierProvider(
          create: (_) => TagProvider(tagRepository)..loadTags(),
        ),

        // CardProvider — templates, folders, note cards
        ChangeNotifierProvider(
          create: (_) => CardProvider(storageService)..load(),
        ),

        // JarProvider — depends on EntryProvider
        ChangeNotifierProxyProvider<EntryProvider, JarProvider>(
          create: (context) => JarProvider(context.read<EntryProvider>()),
          update: (context, entryProvider, jar) =>
              jar!..update(entryProvider),
        ),

        // AiPersonaProvider — avatar, name, personality
        ChangeNotifierProvider(create: (_) => AiPersonaProvider()),

        // LlmConfigNotifier — signals when API key / provider changes
        ChangeNotifierProvider(create: (_) => LlmConfigNotifier()),

        // EntitlementService — preview / restricted / paid state machine
        ChangeNotifierProvider(create: (_) {
          final service = EntitlementService();
          SharedPreferences.getInstance().then((prefs) {
            service.init(prefs);
          });
          return service;
        }),

        // PurchasesService — RevenueCat IAP
        ChangeNotifierProvider<PurchasesService>.value(value: purchasesService),

        // SummaryProvider — depends on EntryProvider + RoutineProvider
        ChangeNotifierProxyProvider2<EntryProvider, RoutineProvider,
            SummaryProvider>(
          create: (context) => SummaryProvider(
            context.read<EntryProvider>(),
            context.read<RoutineProvider>(),
          ),
          update: (context, ep, rp, summary) => summary!..update(ep, rp),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Blinking',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _routineKey = GlobalKey<RoutineScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const MomentScreen(),
      RoutineScreen(key: _routineKey),
      const InsightsScreen(),
      const SettingsScreen(),
    ];
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final completed = await OnboardingScreen.hasCompleted();
    if (!completed && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      await _seedWelcomeEntry();
    }
    _checkTransitionScreen();
  }

  Future<void> _seedWelcomeEntry() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('welcome_entry_seeded') == true) return;

    if (!mounted) return;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final entryProvider = context.read<EntryProvider>();

    await entryProvider.addEntry(
      type: EntryType.freeform,
      content: isZh
          ? '欢迎使用 Blinking 记忆闪烁 ✨\n\n'
            '这是一个帮助你记录日常、追踪习惯、反思成长的空间。\n\n'
            '📝 记录：点击 + 按钮写日记，可以添加情绪和标签。\n'
            '📋 习惯：在"执行"页面管理日常习惯，打卡追踪。\n'
            '💡 洞察：查看你的情绪变化、习惯完成率和年度回顾。\n'
            '🤖 AI 助手：点击浮动机器人，与 AI 对话并保存反思。\n\n'
            '开始你的记忆之旅吧！'
          : 'Welcome to Blinking Notes ✨\n\n'
            'A space to record daily moments, track habits, and reflect on your growth.\n\n'
            '📝 Jot: Tap the + button to write entries with emotions and tags.\n'
            '📋 Habits: Manage daily habits on the Do tab and track your streaks.\n'
            '💡 Insights: Explore mood trends, habit completion, and annual reflections.\n'
            '🤖 AI Companion: Tap the floating robot to chat and save reflections.\n\n'
            'Start your memory journey!',
      tagIds: ['tag_welcome'],
      emotion: '😊',
    );

    await prefs.setBool('welcome_entry_seeded', true);
  }

  Future<void> _checkTransitionScreen() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final entitlement = context.read<EntitlementService>();
    final shown = await TransitionScreen.hasBeenShown();

    if (!shown &&
        entitlement.isRestricted &&
        entitlement.wasPreview) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransitionScreen()),
      );
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          FloatingRobotWidget(currentTabIndex: _currentIndex),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Semantics(identifier: 'nav_my_day', child: const Icon(Icons.calendar_today)),
            label: l10n.calendar,
          ),
          BottomNavigationBarItem(
            icon: Semantics(identifier: 'nav_moments', child: const Icon(Icons.access_time)),
            label: l10n.moment,
          ),
          BottomNavigationBarItem(
            icon: Semantics(identifier: 'nav_routine', child: const Icon(Icons.check_circle_outline)),
            label: l10n.routine,
          ),
          BottomNavigationBarItem(
            icon: Semantics(identifier: 'nav_insights', child: const Icon(Icons.insights)),
            label: l10n.insights,
          ),
          BottomNavigationBarItem(
            icon: Semantics(identifier: 'nav_settings', child: const Icon(Icons.settings)),
            label: l10n.settings,
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (_currentIndex >= 3) return null;

    if (_currentIndex == 2) {
      return FloatingActionButton(
        heroTag: 'main_add_routine_fab',
        onPressed: () {
          final entitlement = context.read<EntitlementService>();
          if (!entitlement.canAddHabit) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            );
            return;
          }
          _routineKey.currentState?.showAddRoutineDialog(context);
        },
        child: Semantics(
          identifier: 'main_add_routine_fab',
          child: const Icon(Icons.playlist_add),
        ),
      );
    }

    return FloatingActionButton(
      heroTag: 'main_add_entry_fab',
      tooltip: 'Add memory',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEntryScreen()),
        );
      },
      child: Semantics(
        identifier: 'btn_fab_add_entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/theme.dart';
import 'core/services/storage_service.dart';
import 'repositories/repositories.dart';
import 'providers/routine_provider.dart';
import 'providers/entry_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/tag_category_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/jar_provider.dart';
import 'providers/summary_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/moment/moment_screen.dart';
import 'screens/cherished/cherished_memory_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'l10n/app_localizations.dart';
import 'models/entry.dart';
import 'core/services/export_service.dart';

class StalioApp extends StatelessWidget {
  final StorageService storageService;

  const StalioApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    final entryRepository = EntryRepository(storageService);
    final routineRepository = RoutineRepository(storageService);
    final tagRepository = TagRepository(storageService);
    final tagCategoryRepository = TagCategoryRepository(storageService);

    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<ExportService>(
          create: (context) => ExportService(storageService),
        ),
        ChangeNotifierProvider(create: (_) {
          final provider = ThemeProvider(storageService);
          provider.loadSettings();
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final provider = LocaleProvider();
          provider.loadLocale();
          return provider;
        }),
        Provider<EntryRepository>.value(value: entryRepository),
        Provider<RoutineRepository>.value(value: routineRepository),
        Provider<TagRepository>.value(value: tagRepository),
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
        ChangeNotifierProvider(
          create: (_) => TagCategoryProvider(tagCategoryRepository)..loadCategories(),
        ),
        ChangeNotifierProxyProvider<EntryProvider, JarProvider>(
          create: (context) => JarProvider(context.read<EntryProvider>()),
          update: (context, entryProvider, jar) =>
              jar!..update(entryProvider),
        ),
        ChangeNotifierProxyProvider2<EntryProvider, RoutineProvider,
            SummaryProvider>(
          create: (context) => SummaryProvider(
            context.read<EntryProvider>(),
            context.read<RoutineProvider>(),
          ),
          update: (context, ep, rp, summary) => summary!..update(ep, rp),
        ),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, _) {
          return MaterialApp(
            title: 'Stalio',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: _OnboardingGate(storageService: storageService),
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
  int _navIndex = 0;
  late final List<Widget> _screens;

  static const _prewarmChannel = MethodChannel('stalio/prewarm');

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const InsightsScreen(),
      const SettingsScreen(),
    ];
    // Warm UIPasteboard privacy cache after first frame so all subsequent
    // TextField focus events are instant. The ~500ms block happens during
    // initial load, invisible to the user, rather than during a tap gesture.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prewarmChannel.invokeMethod<void>('prewarm').catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) => setState(() => _navIndex = index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.calendar_today), label: isZh ? '日常' : 'Daily'),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: 'Tallies'),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: isZh ? '设置' : 'Settings'),
        ],
      ),
    );
  }
}

class _OnboardingGate extends StatefulWidget {
  final StorageService storageService;
  const _OnboardingGate({required this.storageService});

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  @override
  void initState() {
    super.initState();
    if (!widget.storageService.isOnboardingComplete()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OnboardingFlow(onComplete: () {
              widget.storageService.setOnboardingComplete(true);
              Navigator.of(context).pop();
            }),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}

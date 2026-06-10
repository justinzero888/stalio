import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  // ── Core navigation & UI ──

  String get appName;
  String get home;
  String get calendar;
  String get myDay;
  String get moment;
  String get timeline;
  String get add;
  String get routine;
  String get insights;
  String get settings;
  String get today;
  String get yesterday;
  String get thisWeek;
  String get thisMonth;
  String get all;
  String get search;
  String get tags;
  String get tagManagement;
  String get addTag;
  String get editTag;
  String get deleteTag;
  String get addEntry;
  String get editEntry;
  String get deleteEntry;
  String get content;
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get complete;

  // ── Routines ──

  String get active;
  String get inactive;
  String get addRoutine;
  String get editRoutine;
  String get deleteRoutine;
  String get routineName;
  String get frequency;
  String get daily;
  String get weekly;
  String get monthly;
  String get reminderTime;
  String get target;
  String get completed;
  String get notCompleted;

  // ── Settings ──

  String get language;
  String get chinese;
  String get english;
  String get theme;
  String get lightMode;
  String get darkMode;
  String get systemTheme;
  String get export;
  String get import;
  String get exportData;
  String get importData;

  // ── Empty states ──

  String get noEntries;
  String get noRoutines;
  String get noTags;

  // ── Format types ──

  String get text;
  String get noteFormat;
  String get listFormat;

  // ── Tags ──

  String get selectTags;
  String get createdAt;
  String get updatedAt;

  // ── Insights / Summary ──

  String get summaryNoteCount;
  String get summaryHabitCompletion;
  String get summaryMoodTrend;
  String get summaryTopTags;
  String get summaryScopeDay;
  String get summaryScopeWeek;
  String get summaryScopeMonth;
  String get summaryNoNotes;
  String get summaryNoHabits;
  String get summaryNoMood;
  String get summaryNoTags;

  // ── Mood labels ──

  String get moodHappy;
  String get moodSad;
  String get moodAngry;
  String get moodAnxious;
  String get moodTired;
  String get moodExcited;
  String get moodCalm;
  String get moodFrustrated;
  String get moodLoving;
  String get moodNeutral;

  // ── Checklist ──

  String get listTitleHint;
  String get listItemHint;
  String itemsDone(Object done, Object total);
  String carriedOverBanner(num count);
  String get listsSectionHeader;
  String get notesSectionHeader;
  String get listSaveDisabledHint;
  String get carryForwardDialogTitle;
  String carryForwardDialogMessage(num count);
  String get carryForwardYes;
  String get carryForwardNo;
  String get fromYesterdayLabel;
  String get listAlreadyExistsHint;
  String get listEditHint;
  String listDetailSubtitle(Object done, Object total);

  // ── Insights detail ──

  String get insightsWritingStats;
  String get insightsAvgWords;
  String get insightsMostActiveDay;
  String get insightsTagImpact;
  String get insightsTagImpactFootnote;
  String get insightsChecklistSection;
  String get insightsListsCreated;
  String get insightsAvgCompletion;
  String get insightsItemsCarried;
  String get insightsTopItem;

  // ── New keys (Phase 3 L10n audit) ──

  String get appTitleTagline;
  String get noEntriesEmptyToday;
  String get noEntriesEmptyPast;
  String get noEntriesEmptyAction;
  String get welcomeBannerText;
  String get emojiJarTitle;
  String get emojiJarEmpty;
  String get habitCheckIn;
  String get editHabits;
  String get searchEntries;
  String get noTagsWarning;
  String get deleteEntryConfirm;
  String get viewMemory;
  String get editMemory;
  String get addMemory;
  String get memoryUpdated;
  String get memorySaved;
  String get addContentPrompt;
  String get addContentRequired;
  String get media;
  String get mood;
  String get manageTags;
  String get paused;
  String get resume;
  String dayStreak(num streak);
  String get streakMatrixTitle;
  String get habitsSectionTitle;
  String get notesSectionTitle;
  String get moodsSectionTitle;
  String get noEntriesYet;
  String get privateTag;
  String get lockedSystemTag;
  String get emptyStateHabits;
  String get emptyStateRoutines;
  String get allHabitsDone;
  String get streakLegendMissed;
  String get streakLegendDone;
  String get totalHabits;
  String get bestStreak;
  String get activeHabits;
  String get activeSection;
  String get pausedSection;
  String get generalSettings;
  String get tagsSettings;
  String get habitBuildSettings;
  String get voiceReminder;
  String get testVoice;
  String get backupData;
  String get restoreData;
  String get fullBackup;
  String get restoreTitle;
  String get restoreConfirmMessage;
  String get restoreConfirm;
  String restoreSuccess(num entries, num tags, num routines);
  String get restoreErrorCorrupted;
  String get restoreErrorEmpty;
  String get restoreErrorVersion;
  String get backupSuccess;
  String get legalTerms;
  String get legalPrivacy;
  String get versionInfo;
  String get copyToClipboard;
  String get copiedToClipboard;
  String get purchaseRemoveAds;
  String get purchaseRestore;
  String get purchaseAdsActive;
  String get purchaseAdsRemoved;
  String get close;
  String get expand;
  String get collapse;
  String get sun;
  String get mon;
  String get tue;
  String get wed;
  String get thu;
  String get fri;
  String get sat;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

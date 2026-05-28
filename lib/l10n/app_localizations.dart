import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Blinking'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'My Day'**
  String get calendar;

  /// No description provided for @myDay.
  ///
  /// In en, this message translates to:
  /// **'My Day'**
  String get myDay;

  /// No description provided for @moment.
  ///
  /// In en, this message translates to:
  /// **'Moments'**
  String get moment;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @routine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get routine;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagManagement.
  ///
  /// In en, this message translates to:
  /// **'Tag Management'**
  String get tagManagement;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTag;

  /// No description provided for @editTag.
  ///
  /// In en, this message translates to:
  /// **'Edit Tag'**
  String get editTag;

  /// No description provided for @deleteTag.
  ///
  /// In en, this message translates to:
  /// **'Delete Tag'**
  String get deleteTag;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntry;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @addRoutine.
  ///
  /// In en, this message translates to:
  /// **'Add Routine'**
  String get addRoutine;

  /// No description provided for @editRoutine.
  ///
  /// In en, this message translates to:
  /// **'Edit Routine'**
  String get editRoutine;

  /// No description provided for @deleteRoutine.
  ///
  /// In en, this message translates to:
  /// **'Delete Routine'**
  String get deleteRoutine;

  /// No description provided for @routineName.
  ///
  /// In en, this message translates to:
  /// **'Routine Name'**
  String get routineName;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not Completed'**
  String get notCompleted;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntries;

  /// No description provided for @noRoutines.
  ///
  /// In en, this message translates to:
  /// **'No routines yet'**
  String get noRoutines;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get noTags;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @reflection.
  ///
  /// In en, this message translates to:
  /// **'Reflection'**
  String get reflection;

  /// No description provided for @dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dailySummary;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @monthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get monthlySummary;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get goodEvening;

  /// No description provided for @howAreYou.
  ///
  /// In en, this message translates to:
  /// **'How are you today?'**
  String get howAreYou;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @selectTags.
  ///
  /// In en, this message translates to:
  /// **'Select Tags'**
  String get selectTags;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedAt;

  /// No description provided for @summaryNoteCount.
  ///
  /// In en, this message translates to:
  /// **'📝 Notes'**
  String get summaryNoteCount;

  /// No description provided for @summaryHabitCompletion.
  ///
  /// In en, this message translates to:
  /// **'✅ Habit Completion'**
  String get summaryHabitCompletion;

  /// No description provided for @summaryMoodTrend.
  ///
  /// In en, this message translates to:
  /// **'😊 Mood Trend'**
  String get summaryMoodTrend;

  /// No description provided for @summaryTopTags.
  ///
  /// In en, this message translates to:
  /// **'🏷️ Top Tags'**
  String get summaryTopTags;

  /// No description provided for @summaryScopeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get summaryScopeDay;

  /// No description provided for @summaryScopeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get summaryScopeWeek;

  /// No description provided for @summaryScopeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get summaryScopeMonth;

  /// No description provided for @summaryNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No note data yet'**
  String get summaryNoNotes;

  /// No description provided for @summaryNoHabits.
  ///
  /// In en, this message translates to:
  /// **'No habit data yet'**
  String get summaryNoHabits;

  /// No description provided for @summaryNoMood.
  ///
  /// In en, this message translates to:
  /// **'No mood data yet (add emotions to entries)'**
  String get summaryNoMood;

  /// No description provided for @summaryNoTags.
  ///
  /// In en, this message translates to:
  /// **'No tag data yet'**
  String get summaryNoTags;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Joyful'**
  String get moodHappy;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodSad;

  /// No description provided for @moodAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get moodAngry;

  /// No description provided for @moodAnxious.
  ///
  /// In en, this message translates to:
  /// **'Anxious'**
  String get moodAnxious;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get moodTired;

  /// No description provided for @moodExcited.
  ///
  /// In en, this message translates to:
  /// **'Excited'**
  String get moodExcited;

  /// No description provided for @moodCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get moodCalm;

  /// No description provided for @moodFrustrated.
  ///
  /// In en, this message translates to:
  /// **'Frustrated'**
  String get moodFrustrated;

  /// No description provided for @moodLoving.
  ///
  /// In en, this message translates to:
  /// **'Loving'**
  String get moodLoving;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @aiSecretsTagName.
  ///
  /// In en, this message translates to:
  /// **'Secrets'**
  String get aiSecretsTagName;

  /// No description provided for @trialBannerStartTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Trial Available'**
  String get trialBannerStartTitle;

  /// No description provided for @trialBannerStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full access during your trial period.'**
  String get trialBannerStartSubtitle;

  /// No description provided for @trialBannerStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Trial →'**
  String get trialBannerStartButton;

  /// No description provided for @trialBannerActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Trial Active'**
  String get trialBannerActiveTitle;

  /// No description provided for @trialBannerActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI features are available during your trial.'**
  String get trialBannerActiveSubtitle;

  /// No description provided for @trialBannerExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Trial Complete'**
  String get trialBannerExpiredTitle;

  /// No description provided for @trialBannerExpiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to continue using AI features.'**
  String get trialBannerExpiredSubtitle;

  /// No description provided for @trialBannerExpiredButton.
  ///
  /// In en, this message translates to:
  /// **'Get Pro →'**
  String get trialBannerExpiredButton;

  /// No description provided for @trialProviderName.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trialProviderName;

  /// No description provided for @trialProviderSubtitleDays.
  ///
  /// In en, this message translates to:
  /// **'Trial active'**
  String get trialProviderSubtitleDays;

  /// No description provided for @trialProviderSubtitleDay.
  ///
  /// In en, this message translates to:
  /// **'Trial active'**
  String get trialProviderSubtitleDay;

  /// No description provided for @trialProviderChip.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trialProviderChip;

  /// No description provided for @trialProviderExpiredChip.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get trialProviderExpiredChip;

  /// No description provided for @trialStartError.
  ///
  /// In en, this message translates to:
  /// **'Failed to start trial. Please try again.'**
  String get trialStartError;

  /// No description provided for @trialAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Your trial has been used on this device.'**
  String get trialAlreadyUsed;

  /// No description provided for @trialInfoDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Trial Details'**
  String get trialInfoDialogTitle;

  /// No description provided for @trialInfoModel.
  ///
  /// In en, this message translates to:
  /// **'Model: qwen/qwen3.5-flash'**
  String get trialInfoModel;

  /// No description provided for @trialInfoUrl.
  ///
  /// In en, this message translates to:
  /// **'Blinking AI service'**
  String get trialInfoUrl;

  /// No description provided for @trialInfoCannotEdit.
  ///
  /// In en, this message translates to:
  /// **'Trial settings cannot be edited.'**
  String get trialInfoCannotEdit;

  /// No description provided for @noteFormat.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteFormat;

  /// No description provided for @listFormat.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listFormat;

  /// No description provided for @listTitleHint.
  ///
  /// In en, this message translates to:
  /// **'List title'**
  String get listTitleHint;

  /// No description provided for @listItemHint.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get listItemHint;

  /// No description provided for @itemsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} done'**
  String itemsDone(Object done, Object total);

  /// No description provided for @carriedOverBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} item carried over from yesterday} other{{count} items carried over from yesterday}}'**
  String carriedOverBanner(num count);

  /// No description provided for @listsSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get listsSectionHeader;

  /// No description provided for @notesSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesSectionHeader;

  /// No description provided for @listSaveDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get listSaveDisabledHint;

  /// No description provided for @carryForwardDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfinished from yesterday'**
  String get carryForwardDialogTitle;

  /// No description provided for @carryForwardDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have 1 unchecked item from yesterday. Add to today\'s list?} other{You have {count} unchecked items from yesterday. Add to today\'s list?}}'**
  String carryForwardDialogMessage(num count);

  /// No description provided for @carryForwardYes.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get carryForwardYes;

  /// No description provided for @carryForwardNo.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get carryForwardNo;

  /// No description provided for @fromYesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get fromYesterdayLabel;

  /// No description provided for @listAlreadyExistsHint.
  ///
  /// In en, this message translates to:
  /// **'Today\'s list already exists — opening it'**
  String get listAlreadyExistsHint;

  /// No description provided for @listEditHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to check · Drag to reorder · × to remove'**
  String get listEditHint;

  /// No description provided for @listDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist · {done}/{total} done'**
  String listDetailSubtitle(Object done, Object total);

  /// No description provided for @insightsWritingStats.
  ///
  /// In en, this message translates to:
  /// **'Writing Stats'**
  String get insightsWritingStats;

  /// No description provided for @insightsAvgWords.
  ///
  /// In en, this message translates to:
  /// **'avg words'**
  String get insightsAvgWords;

  /// No description provided for @insightsMostActiveDay.
  ///
  /// In en, this message translates to:
  /// **'most active'**
  String get insightsMostActiveDay;

  /// No description provided for @insightsTagImpact.
  ///
  /// In en, this message translates to:
  /// **'Tag Impact on Mood'**
  String get insightsTagImpact;

  /// No description provided for @insightsTagImpactFootnote.
  ///
  /// In en, this message translates to:
  /// **'Tags with ≥3 entries shown'**
  String get insightsTagImpactFootnote;

  /// No description provided for @insightsChecklistSection.
  ///
  /// In en, this message translates to:
  /// **'Checklist Insights'**
  String get insightsChecklistSection;

  /// No description provided for @insightsListsCreated.
  ///
  /// In en, this message translates to:
  /// **'lists created'**
  String get insightsListsCreated;

  /// No description provided for @insightsAvgCompletion.
  ///
  /// In en, this message translates to:
  /// **'avg completion'**
  String get insightsAvgCompletion;

  /// No description provided for @insightsItemsCarried.
  ///
  /// In en, this message translates to:
  /// **'carried forward'**
  String get insightsItemsCarried;

  /// No description provided for @insightsTopItem.
  ///
  /// In en, this message translates to:
  /// **'top item'**
  String get insightsTopItem;
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
  // Lookup logic when only language code is specified.
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

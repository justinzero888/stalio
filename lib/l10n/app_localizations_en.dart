// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  // ── Core navigation & UI ──

  @override String get appName => 'Stalio';
  @override String get home => 'Home';
  @override String get calendar => 'My Day';
  @override String get myDay => 'My Day';
  @override String get moment => 'Moments';
  @override String get timeline => 'Timeline';
  @override String get add => 'Add';
  @override String get routine => 'Routine';
  @override String get insights => 'Insights';
  @override String get settings => 'Settings';
  @override String get today => 'Today';
  @override String get yesterday => 'Yesterday';
  @override String get thisWeek => 'This Week';
  @override String get thisMonth => 'This Month';
  @override String get all => 'All';
  @override String get search => 'Search';
  @override String get tags => 'Tags';
  @override String get tagManagement => 'Tag Management';
  @override String get addTag => 'Add Tag';
  @override String get editTag => 'Edit Tag';
  @override String get deleteTag => 'Delete Tag';
  @override String get addEntry => 'Add Entry';
  @override String get editEntry => 'Edit Entry';
  @override String get deleteEntry => 'Delete Entry';
  @override String get content => 'Content';
  @override String get save => 'Save';
  @override String get cancel => 'Cancel';
  @override String get delete => 'Delete';
  @override String get edit => 'Edit';
  @override String get complete => 'Complete';

  // ── Routines ──

  @override String get active => 'Active';
  @override String get inactive => 'Inactive';
  @override String get addRoutine => 'Add Routine';
  @override String get editRoutine => 'Edit Routine';
  @override String get deleteRoutine => 'Delete Routine';
  @override String get routineName => 'Routine Name';
  @override String get frequency => 'Frequency';
  @override String get daily => 'Daily';
  @override String get weekly => 'Weekly';
  @override String get monthly => 'Monthly';
  @override String get reminderTime => 'Reminder Time';
  @override String get target => 'Target';
  @override String get completed => 'Completed';
  @override String get notCompleted => 'Not Completed';

  // ── Settings ──

  @override String get language => 'Language';
  @override String get chinese => 'Chinese';
  @override String get english => 'English';
  @override String get theme => 'Theme';
  @override String get lightMode => 'Light Mode';
  @override String get darkMode => 'Dark Mode';
  @override String get systemTheme => 'System';
  @override String get export => 'Export';
  @override String get import => 'Import';
  @override String get exportData => 'Export Data';
  @override String get importData => 'Import Data';

  // ── Empty states ──

  @override String get noEntries => 'No entries yet';
  @override String get noRoutines => 'No routines yet';
  @override String get noTags => 'No tags yet';

  // ── Format types ──

  @override String get text => 'Text';
  @override String get noteFormat => 'Note';
  @override String get listFormat => 'List';

  // ── Tags ──

  @override String get selectTags => 'Select Tags';
  @override String get createdAt => 'Created';
  @override String get updatedAt => 'Updated';

  // ── Insights / Summary ──

  @override String get summaryNoteCount => '📝 Notes';
  @override String get summaryHabitCompletion => '✅ Habit Completion';
  @override String get summaryMoodTrend => '😊 Mood Trend';
  @override String get summaryTopTags => '🏷️ Top Tags';
  @override String get summaryScopeDay => 'Day';
  @override String get summaryScopeWeek => 'Week';
  @override String get summaryScopeMonth => 'Month';
  @override String get summaryNoNotes => 'No note data yet';
  @override String get summaryNoHabits => 'No habit data yet';
  @override String get summaryNoMood => 'No mood data yet (add emotions to entries)';
  @override String get summaryNoTags => 'No tag data yet';

  // ── Mood labels ──

  @override String get moodHappy => 'Joyful';
  @override String get moodSad => 'Sad';
  @override String get moodAngry => 'Angry';
  @override String get moodAnxious => 'Anxious';
  @override String get moodTired => 'Tired';
  @override String get moodExcited => 'Excited';
  @override String get moodCalm => 'Calm';
  @override String get moodFrustrated => 'Frustrated';
  @override String get moodLoving => 'Loving';
  @override String get moodNeutral => 'Neutral';

  // ── Checklist ──

  @override String get listTitleHint => 'List title';
  @override String get listItemHint => 'Add item';
  @override String itemsDone(Object done, Object total) => '$done / $total done';
  @override String carriedOverBanner(num count) {
    return intl.Intl.pluralLogic(count, locale: localeName,
      other: '$count items carried over from yesterday',
      one: '$count item carried over from yesterday',
    );
  }
  @override String get listsSectionHeader => '📋 Lists';
  @override String get notesSectionHeader => '📝 Notes';
  @override String get listSaveDisabledHint => 'Add at least one item to save';
  @override String get carryForwardDialogTitle => 'Unfinished from yesterday';
  @override String carryForwardDialogMessage(num count) {
    return intl.Intl.pluralLogic(count, locale: localeName,
      other: 'You have $count unchecked items from yesterday. Add to today\'s list?',
      one: 'You have 1 unchecked item from yesterday. Add to today\'s list?',
    );
  }
  @override String get carryForwardYes => 'Add';
  @override String get carryForwardNo => 'Skip';
  @override String get fromYesterdayLabel => 'Yesterday';
  @override String get listAlreadyExistsHint => 'Today\'s list already exists \u2014 opening it';
  @override String get listEditHint => 'Tap to check \u00b7 Drag to reorder \u00b7 \u00d7 to remove';
  @override String listDetailSubtitle(Object done, Object total) => 'Checklist \u00b7 $done/$total done';

  // ── Insights detail ──

  @override String get insightsWritingStats => 'Writing Stats';
  @override String get insightsAvgWords => 'avg words';
  @override String get insightsMostActiveDay => 'most active';
  @override String get insightsTagImpact => 'Tag Impact on Mood';
  @override String get insightsTagImpactFootnote => 'Tags with \u22653 entries shown';
  @override String get insightsChecklistSection => 'Checklist Insights';
  @override String get insightsListsCreated => 'lists created';
  @override String get insightsAvgCompletion => 'avg completion';
  @override String get insightsItemsCarried => 'carried forward';
  @override String get insightsTopItem => 'top item';

  // ── New keys (Phase 3 L10n audit) ──

  @override String get appTitleTagline => 'Stalio: Do. Tally. Grow.';
  @override String get noEntriesEmptyToday => 'No entries today';
  @override String get noEntriesEmptyPast => 'No entries on this day';
  @override String get noEntriesEmptyAction => 'Tap + to add an entry';
  @override String get welcomeBannerText => 'A thousand miles begins with a single step.';
  @override String get emojiJarTitle => 'My Mood Jar';
  @override String get emojiJarEmpty => 'empty';
  @override String get habitCheckIn => 'Habit Check-in';
  @override String get editHabits => 'Edit Habits';
  @override String get searchEntries => 'Search entries...';
  @override String get noTagsWarning => 'No tags yet. Add tags in Settings first.';
  @override String get deleteEntryConfirm => 'Delete this entry?';
  @override String get viewMemory => 'View Memory';
  @override String get editMemory => 'Edit Memory';
  @override String get addMemory => 'Add Memory';
  @override String get memoryUpdated => 'Memory updated!';
  @override String get memorySaved => 'Memory saved!';
  @override String get addContentPrompt => 'What\'s on your mind?';
  @override String get addContentRequired => 'Please add some content';
  @override String get media => 'Media';
  @override String get mood => 'Mood';
  @override String get manageTags => 'Manage Tags';
  @override String get paused => 'Paused';
  @override String get resume => 'Resume';
  @override String dayStreak(num streak) => '$streak day streak';
  @override String get streakMatrixTitle => 'Streak Matrix';
  @override String get habitsSectionTitle => 'Habits';
  @override String get notesSectionTitle => 'Notes';
  @override String get moodsSectionTitle => 'Moods';
  @override String get noEntriesYet => 'No entries yet\nTap + to add one';
  @override String get privateTag => 'Private';
  @override String get lockedSystemTag => 'System tag (locked)';
  @override String get emptyStateHabits => 'No habits yet';
  @override String get emptyStateRoutines => 'No routines yet';
  @override String get allHabitsDone => 'All habits completed for today!';
  @override String get streakLegendMissed => 'Missed';
  @override String get streakLegendDone => 'Done';
  @override String get totalHabits => 'Total';
  @override String get bestStreak => 'Best Streak';
  @override String get activeHabits => 'Active';
  @override String get activeSection => 'Active';
  @override String get pausedSection => 'Paused';
  @override String get generalSettings => 'General';
  @override String get tagsSettings => 'Tags';
  @override String get habitBuildSettings => 'Habit Build';
  @override String get voiceReminder => 'Voice Reminder';
  @override String get testVoice => 'Test Voice';
  @override String get backupData => 'Backup Data';
  @override String get restoreData => 'Restore Data';
  @override String get fullBackup => 'Full Backup (ZIP)';
  @override String get restoreTitle => 'Restore Data';
  @override String get restoreConfirmMessage => 'This will replace all current data. Continue?';
  @override String get restoreConfirm => 'Confirm Restore';
  @override String restoreSuccess(num entries, num tags, num routines) =>
      'Restored $entries entries, $tags tags, $routines habits';
  @override String get restoreErrorCorrupted => 'Corrupted backup file';
  @override String get restoreErrorEmpty => 'No data found in backup';
  @override String get restoreErrorVersion => 'Backup version mismatch';
  @override String get backupSuccess => 'Backup created successfully';
  @override String get legalTerms => 'Terms of Service';
  @override String get legalPrivacy => 'Privacy Policy';
  @override String get versionInfo => 'Stalio Version 1.0.0';
  @override String get copyToClipboard => 'Copy to Clipboard';
  @override String get copiedToClipboard => 'Copied!';
  @override String get purchaseRemoveAds => 'Remove Ads';
  @override String get purchaseRestore => 'Restore Purchase';
  @override String get purchaseAdsActive => 'Ads: Active';
  @override String get purchaseAdsRemoved => 'Ads: Removed';
  @override String get close => 'Close';
  @override String get expand => 'Expand';
  @override String get collapse => 'Collapse';
  @override String get sun => 'Sun';
  @override String get mon => 'Mon';
  @override String get tue => 'Tue';
  @override String get wed => 'Wed';
  @override String get thu => 'Thu';
  @override String get fri => 'Fri';
  @override String get sat => 'Sat';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  // ── Core navigation & UI ──

  @override String get appName => 'Stalio';
  @override String get home => '首页';
  @override String get calendar => '我的一天';
  @override String get myDay => '我的一天';
  @override String get moment => '瞬间';
  @override String get timeline => '时间轴';
  @override String get add => '添加';
  @override String get routine => '日常';
  @override String get insights => '洞察';
  @override String get settings => '设置';
  @override String get today => '今天';
  @override String get yesterday => '昨天';
  @override String get thisWeek => '本周';
  @override String get thisMonth => '本月';
  @override String get all => '全部';
  @override String get search => '搜索';
  @override String get tags => '标签';
  @override String get tagManagement => '标签管理';
  @override String get addTag => '添加标签';
  @override String get editTag => '编辑标签';
  @override String get deleteTag => '删除标签';
  @override String get addEntry => '添加记录';
  @override String get editEntry => '编辑记录';
  @override String get deleteEntry => '删除记录';
  @override String get content => '内容';
  @override String get save => '保存';
  @override String get cancel => '取消';
  @override String get delete => '删除';
  @override String get edit => '编辑';
  @override String get complete => '完成';

  // ── Routines ──

  @override String get active => '进行中';
  @override String get inactive => '已暂停';
  @override String get addRoutine => '添加日常';
  @override String get editRoutine => '编辑日常';
  @override String get deleteRoutine => '删除日常';
  @override String get routineName => '日常名称';
  @override String get frequency => '频率';
  @override String get daily => '每日';
  @override String get weekly => '每周';
  @override String get monthly => '每月';
  @override String get reminderTime => '提醒时间';
  @override String get target => '目标';
  @override String get completed => '已完成';
  @override String get notCompleted => '未完成';

  // ── Settings ──

  @override String get language => '语言';
  @override String get chinese => '中文';
  @override String get english => '英文';
  @override String get theme => '主题';
  @override String get lightMode => '浅色模式';
  @override String get darkMode => '深色模式';
  @override String get systemTheme => '跟随系统';
  @override String get export => '导出';
  @override String get import => '导入';
  @override String get exportData => '导出数据';
  @override String get importData => '导入数据';

  // ── Empty states ──

  @override String get noEntries => '暂无记录';
  @override String get noRoutines => '暂无日常';
  @override String get noTags => '暂无标签';

  // ── Format types ──

  @override String get text => '文本';
  @override String get noteFormat => '笔记';
  @override String get listFormat => '清单';

  // ── Tags ──

  @override String get selectTags => '选择标签';
  @override String get createdAt => '创建时间';
  @override String get updatedAt => '更新时间';

  // ── Insights / Summary ──

  @override String get summaryNoteCount => '📝 记录数量';
  @override String get summaryHabitCompletion => '✅ 习惯完成率';
  @override String get summaryMoodTrend => '😊 情绪趋势';
  @override String get summaryTopTags => '🏷️ 热门标签';
  @override String get summaryScopeDay => '日';
  @override String get summaryScopeWeek => '周';
  @override String get summaryScopeMonth => '月';
  @override String get summaryNoNotes => '暂无记录数据';
  @override String get summaryNoHabits => '暂无习惯数据';
  @override String get summaryNoMood => '暂无情绪数据（请为记录添加情绪）';
  @override String get summaryNoTags => '暂无标签数据';

  // ── Mood labels ──

  @override String get moodHappy => '开心';
  @override String get moodSad => '悲伤';
  @override String get moodAngry => '愤怒';
  @override String get moodAnxious => '焦虑';
  @override String get moodTired => '疲倦';
  @override String get moodExcited => '兴奋';
  @override String get moodCalm => '平静';
  @override String get moodFrustrated => '沮丧';
  @override String get moodLoving => '温暖';
  @override String get moodNeutral => '平淡';

  // ── Checklist ──

  @override String get listTitleHint => '清单标题';
  @override String get listItemHint => '添加事项';
  @override String itemsDone(Object done, Object total) => '$done / $total 已完成';
  @override String carriedOverBanner(num count) {
    return intl.Intl.pluralLogic(count, locale: localeName,
      other: '$count 个事项从昨天转入',
    );
  }
  @override String get listsSectionHeader => '📋 今日清单';
  @override String get notesSectionHeader => '📝 笔记';
  @override String get listSaveDisabledHint => '请至少添加一个事项';
  @override String get carryForwardDialogTitle => '昨日未完成事项';
  @override String carryForwardDialogMessage(num count) {
    return intl.Intl.pluralLogic(count, locale: localeName,
      other: '昨天的清单还有 $count 项未完成。要添加到今天的清单吗？',
    );
  }
  @override String get carryForwardYes => '添加';
  @override String get carryForwardNo => '跳过';
  @override String get fromYesterdayLabel => '昨日';
  @override String get listAlreadyExistsHint => '今天已有清单，正在打开';
  @override String get listEditHint => '点击选中 \u00b7 拖动排序 \u00b7 \u00d7 删除';
  @override String listDetailSubtitle(Object done, Object total) => '清单 \u00b7 $done/$total 已完成';

  // ── Insights detail ──

  @override String get insightsWritingStats => '写作统计';
  @override String get insightsAvgWords => '平均字数';
  @override String get insightsMostActiveDay => '最活跃日';
  @override String get insightsTagImpact => '标签与情绪';
  @override String get insightsTagImpactFootnote => '显示出现 3 次以上的标签';
  @override String get insightsChecklistSection => '清单洞察';
  @override String get insightsListsCreated => '已创建清单';
  @override String get insightsAvgCompletion => '平均完成率';
  @override String get insightsItemsCarried => '已结转事项';
  @override String get insightsTopItem => '最常见事项';

  // ── New keys (Phase 3 L10n audit) ──

  @override String get appTitleTagline => 'Stalio:行.积.成.';
  @override String get noEntriesEmptyToday => '今天还没有记录';
  @override String get noEntriesEmptyPast => '当天没有记录';
  @override String get noEntriesEmptyAction => '点击 + 添加记录';
  @override String get welcomeBannerText => '千里之行，始于足下。';
  @override String get emojiJarTitle => '情绪罐';
  @override String get emojiJarEmpty => '空';
  @override String get habitCheckIn => '习惯打卡';
  @override String get editHabits => '编辑习惯';
  @override String get searchEntries => '搜索记录...';
  @override String get noTagsWarning => '暂无标签，请先在设置中添加标签';
  @override String get deleteEntryConfirm => '确定要删除这条记录吗？';
  @override String get viewMemory => '查看记录';
  @override String get editMemory => '编辑记录';
  @override String get addMemory => '添加记录';
  @override String get memoryUpdated => '记录已更新！';
  @override String get memorySaved => '记录已保存！';
  @override String get addContentPrompt => '今天有什么想记录的？';
  @override String get addContentRequired => '请添加一些内容';
  @override String get media => '媒体';
  @override String get mood => '心情';
  @override String get manageTags => '管理标签';
  @override String get paused => '已暂停';
  @override String get resume => '恢复';
  @override String dayStreak(num streak) => '$streak 天连续';
  @override String get streakMatrixTitle => '坚持矩阵';
  @override String get habitsSectionTitle => '习惯';
  @override String get notesSectionTitle => '笔记';
  @override String get moodsSectionTitle => '心情';
  @override String get noEntriesYet => '暂无记录\n点击 + 添加第一条';
  @override String get privateTag => '私密';
  @override String get lockedSystemTag => '系统标签（不可删除）';
  @override String get emptyStateHabits => '暂无习惯';
  @override String get emptyStateRoutines => '暂无日常';
  @override String get allHabitsDone => '今日全部习惯已完成！';
  @override String get streakLegendMissed => '未完成';
  @override String get streakLegendDone => '已完成';
  @override String get totalHabits => '总计';
  @override String get bestStreak => '最佳连续';
  @override String get activeHabits => '进行中';
  @override String get activeSection => '进行中';
  @override String get pausedSection => '已暂停';
  @override String get generalSettings => '通用';
  @override String get tagsSettings => '标签';
  @override String get habitBuildSettings => '习惯建设';
  @override String get voiceReminder => '语音提醒';
  @override String get testVoice => '测试语音';
  @override String get backupData => '备份数据';
  @override String get restoreData => '恢复数据';
  @override String get fullBackup => '完整备份（ZIP）';
  @override String get restoreTitle => '恢复数据';
  @override String get restoreConfirmMessage => '这将替换所有当前数据。确定继续？';
  @override String get restoreConfirm => '确认恢复';
  @override String restoreSuccess(num entries, num tags, num routines) =>
      '已恢复 $entries 条记录、$tags 个标签、$routines 个习惯';
  @override String get restoreErrorCorrupted => '备份文件已损坏';
  @override String get restoreErrorEmpty => '备份文件中未找到数据';
  @override String get restoreErrorVersion => '备份版本不匹配';
  @override String get backupSuccess => '备份创建成功';
  @override String get legalTerms => '服务条款';
  @override String get legalPrivacy => '隐私政策';
  @override String get versionInfo => 'Stalio 版本 1.0.0';
  @override String get copyToClipboard => '复制到剪贴板';
  @override String get copiedToClipboard => '已复制！';
  @override String get purchaseRemoveAds => '移除广告';
  @override String get purchaseRestore => '恢复购买';
  @override String get purchaseAdsActive => '广告：已启用';
  @override String get purchaseAdsRemoved => '广告：已移除';
  @override String get close => '关闭';
  @override String get expand => '展开';
  @override String get collapse => '收起';
  @override String get sun => '日';
  @override String get mon => '一';
  @override String get tue => '二';
  @override String get wed => '三';
  @override String get thu => '四';
  @override String get fri => '五';
  @override String get sat => '六';
}

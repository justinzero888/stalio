import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/locale_provider.dart';
import '../../core/services/purchases_service.dart';
import '../../core/services/entitlement_service.dart';
import '../legal_doc_screen.dart';
import '../../core/constants/legal_content.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isPurchasing = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);
    final purchases = context.watch<PurchasesService>();
    final storeReady = purchases.isInitialized;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // Back + Close buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _isPurchasing || _isRestoring ? null : () => Navigator.pop(context),
                      tooltip: isZh ? '返回' : 'Back',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isPurchasing || _isRestoring ? null : () => Navigator.pop(context),
                      tooltip: isZh ? '关闭' : 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Above the fold ──
                _TesseraArt(),
                const SizedBox(height: 24),
                Text(
                  'Blinking Pro',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isZh
                      ? '一次购买，终身解锁全部功能。'
                      : 'A one-time purchase that unlocks the app for life.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),

                // Price
                Text(
                  '\$19.99',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),

                // Get Pro button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: (!storeReady) || _isPurchasing || _isRestoring
                        ? null
                        : () => _handlePurchase(context, isZh),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isPurchasing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isZh ? '获取 Pro — \$19.99' : 'Get Pro — \$19.99',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (!storeReady)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      isZh
                          ? '商店当前不可用，请稍后重试'
                          : 'Store unavailable, please try again later',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange[700], fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 12),

                // Restore Purchases
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: (!storeReady) || _isPurchasing || _isRestoring
                        ? null
                        : () => _handleRestore(context, isZh),
                    child: _isRestoring
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isZh ? '恢复购买' : 'Restore Purchases',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Divider ──
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[200])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        isZh ? 'Pro 包含' : 'What you get with Pro',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[200])),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Below the fold ──
                _FeatureRow(
                  icon: Icons.edit_note,
                  title: isZh ? '笔记：完整编辑 + 删除' : 'Notes: full editing + delete',
                ),
                _FeatureRow(
                  icon: Icons.checklist,
                  title: isZh ? '习惯：添加、编辑、删除、打卡' : 'Habits: add, edit, delete, check-in',
                ),
                _FeatureRow(
                  icon: Icons.auto_awesome,
                  title: isZh
                      ? 'AI 助手：AI 反思'
                      : 'AI assistant: AI reflections',
                ),
                _FeatureRow(
                  icon: Icons.backup,
                  title: isZh
                      ? '备份与恢复：跨设备同步数据'
                      : 'Backup & restore across devices',
                ),
                _FeatureRow(
                  icon: Icons.share,
                  title: isZh
                      ? '分享至 Chorus 社区'
                      : 'Share to Chorus',
                ),
                const SizedBox(height: 32),

                // ── What stays free ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isZh ? '即使不购买 Pro' : 'Even without Pro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _FreeRow(
                        text: isZh
                            ? '阅读和添加新笔记'
                            : 'Read all your notes, add new ones',
                      ),
                      _FreeRow(
                        text: isZh
                            ? '打卡已有习惯'
                            : 'Check existing habits',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Footer ──
                Text(
                  isZh
                      ? '无需订阅，没有定期扣费。一次购买，永久拥有。'
                      : 'No subscription, no recurring billing. One purchase, yours forever.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isZh ? '支持家庭共享。' : 'Family Sharing supported.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Policy links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LegalDocScreen(
                              title: isZh ? '隐私政策' : 'Privacy Policy',
                              content: kPrivacyPolicyContent,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        isZh ? '隐私政策' : 'Privacy policy',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(' ┃ ', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LegalDocScreen(
                              title: isZh ? '服务条款' : 'Terms of Service',
                              content: kTermsOfServiceContent,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        isZh ? '服务条款' : 'Terms',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context, bool isZh) async {
    final service = context.read<PurchasesService>();
    if (!service.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '商店未就绪，请稍后重试' : 'Store not ready, try again later')),
      );
      return;
    }

    setState(() => _isPurchasing = true);

    final info = await service.purchaseProduct('blinking_pro');
    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (info == null && service.lastError == null) {
      // Purchase cancelled by user — no message needed
      return;
    }

    // Refresh customer info to sync latest entitlements
    await service.refreshCustomerInfo();
    if (!mounted) return;

    if (service.isPro || info != null) {
      // Update local entitlement state to paid
      final entitlement = context.read<EntitlementService>();
      await _markEntitlementPaid(entitlement);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isZh ? '欢迎加入 Pro！' : 'Welcome to Pro!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (service.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(service.lastError!)),
      );
    }
  }

  Future<void> _handleRestore(BuildContext context, bool isZh) async {
    final service = context.read<PurchasesService>();
    if (!service.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '商店未就绪' : 'Store not ready')),
      );
      return;
    }

    setState(() => _isRestoring = true);

    final info = await service.restorePurchases();
    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (info == null && service.lastError == null) {
      return;
    }

    await service.refreshCustomerInfo();
    if (!mounted) return;

    if (service.isPro) {
      final entitlement = context.read<EntitlementService>();
      await _markEntitlementPaid(entitlement);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isZh ? '已恢复 Pro。' : 'Pro restored.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isZh
              ? '未找到之前的 Pro 购买记录。'
              : 'No previous Pro purchase found.'),
        ),
      );
    }
  }

  Future<void> _markEntitlementPaid(EntitlementService entitlement) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('entitlement_jwt');
    await prefs.setString('entitlement_state', 'paid');
    await prefs.remove('entitlement_preview_started');
    await prefs.setInt('entitlement_preview_days', -1);
    await prefs.remove('entitlement_was_preview');
    await entitlement.init(prefs);
  }
}

class _TesseraArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.6),
              Colors.purple.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 40,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const Icon(
                Icons.diamond,
                size: 24,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureRow({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeRow extends StatelessWidget {
  final String text;

  const _FreeRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

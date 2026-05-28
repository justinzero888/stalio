/// Legal document content embedded as Dart string constants.
/// Source documents: docs/Blinking_Notes_Privacy_Policy.md
///                   docs/Blinking_Notes_Terms_of_Service.md
/// Chinese versions follow the English versions below.
library;

const String kPrivacyPolicyContent = '''
Privacy Policy — Blinking (记忆闪烁)

Effective Date: March 21, 2026
App Name: Blinking (记忆闪烁)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. OVERVIEW

Blinking (记忆闪烁) is a personal memory and habit-tracking application designed to work entirely on your device. We are committed to protecting your privacy.

The short version: Blinking does not collect, transmit, or share any personal data. All your data stays on your device.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2. INFORMATION WE DO NOT COLLECT

We do not collect, store, or transmit:
• Your name, email address, phone number, or any identity information
• Location data
• Device identifiers or advertising IDs
• Usage analytics or crash reports
• Any content you create in the app (journal entries, habits, notes, or media)

There are no accounts, no sign-in, and no registration required.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3. DATA STORAGE — LOCAL ONLY

All data you create in Blinking is stored exclusively on your device:

• Journal entries, habits, and cards are stored in a local SQLite database on your device.
• Media files (photos attached to entries) are stored in the app's private document directory.
• App preferences (theme, language, settings) are stored in your device's local storage.

No data is uploaded to any server operated by us.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4. INTERNET CONNECTIVITY

Blinking is designed to be fully functional without an internet connection. All core features — journaling, habit tracking, card creation, memory jars, and statistics — work entirely offline.

The app does not require internet access to function.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5. AI ASSISTANT FEATURE (OPTIONAL)

Blinking includes an optional AI Assistant. This feature is enabled during your trial or after upgrading to Pro.

The AI Assistant processes your journal context directly from your device. No journal content is permanently stored on Blinking's servers.

Important disclosures:

• When you use the AI Assistant, your journal context and prompt are transmitted to a third-party AI provider (such as OpenAI) through Blinking's managed service.
• Blinking uses a privacy-preserving architecture: your device assembles the prompt, obtains an anonymous authorization token from Blinking, and communicates with the AI provider directly.
• The third-party AI provider may process and temporarily store the data you send according to their own privacy policies and terms of service.
• You can use the AI feature during your trial period or with an active Pro subscription.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

6. PERMISSIONS

Blinking may request the following device permissions:

Camera — To take photos and attach them to journal entries
Photo Library / Media Images — To select existing photos and attach them to entries

These permissions are requested only when you attempt to use the relevant feature. Blinking does not access your camera or photo library in the background.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

7. DATA EXPORT AND BACKUP

Blinking provides built-in tools to export your data (ZIP backup, JSON, CSV). These exports are generated locally on your device and shared using your device's native sharing mechanism. We do not receive copies of your exported data.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

8. CHILDREN'S PRIVACY

Blinking is not directed at children under the age of 13. We do not knowingly collect any information from children.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

9. CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time. We will notify you of material changes by updating the effective date. Continued use of the app after any changes constitutes your acceptance of the updated policy.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

10. CONTACT

If you have questions about this Privacy Policy, please contact us through the app store listing or the project's public repository.
''';

const String kTermsOfServiceContent = '''
Terms of Service — Blinking (记忆闪烁)

Effective Date: March 21, 2026
App Name: Blinking (记忆闪烁)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ACCEPTANCE OF TERMS

By downloading, installing, or using Blinking (记忆闪烁) ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these Terms, do not use the App.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2. DESCRIPTION OF SERVICE

Blinking is a personal memory and habit-tracking application that runs entirely on your device. The App allows you to:
• Record journal entries, emotions, and memories
• Track personal habits and routines
• Create and manage memory cards
• View personal statistics and summaries
• Optionally interact with the built-in AI assistant

The App is fully functional without an internet connection. No account or registration is required.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3. LICENSE

We grant you a limited, non-exclusive, non-transferable, revocable license to use the App for your personal, non-commercial purposes.

You may not:
• Copy, modify, or distribute the App or its content
• Reverse engineer or attempt to extract the source code of the App
• Use the App for any unlawful purpose
• Use the App in any manner that could damage, disable, or impair the App

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4. YOUR CONTENT

All content you create within the App (journal entries, habits, notes, media) belongs to you. We do not access, claim ownership of, or transmit your content.

Your content is stored locally on your device. You are responsible for maintaining backups of your own data. We are not liable for any data loss resulting from device failure, app uninstallation, or any other cause.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5. AI ASSISTANT FEATURE (OPTIONAL)

The App includes an optional AI Assistant, available during your trial or with a Pro subscription.

By using the AI Assistant feature, you acknowledge and agree that:

• Content you send to the AI Assistant is transmitted to a third-party AI provider. This transmission is governed by that provider's own terms of service and privacy policy, not ours.
• You will not use the AI Assistant to generate unlawful, harmful, or offensive content.
• We make no warranties regarding the accuracy, reliability, or appropriateness of AI-generated responses.
• You use AI-generated content at your own risk.

We are not affiliated with, endorsed by, or responsible for any third-party AI provider.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

6. PRIVACY

Your use of the App is also governed by our Privacy Policy. Key points:
• The App does not collect or transmit your personal data.
• All data is stored locally on your device.
• The App works fully offline without transmitting any information.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

7. DISCLAIMER OF WARRANTIES

THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.

We do not warrant that the App will be uninterrupted, error-free, or secure.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

8. LIMITATION OF LIABILITY

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR LOSS OF PROFITS, ARISING FROM YOUR USE OF THE APP.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

9. DATA LOSS

We are not responsible for any loss of data stored in the App. We strongly recommend using the built-in backup feature (Settings → Full Backup) regularly to protect your data.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

10. THIRD-PARTY SERVICES

The App may integrate with third-party services at your option (AI providers). These services are not operated by us, and we are not responsible for their content, availability, or practices. Your use of any third-party service is subject to that service's own terms and privacy policy.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

11. MODIFICATIONS

We reserve the right to modify or discontinue the App at any time. We may also update these Terms from time to time. Your continued use of the App after changes constitutes acceptance of the updated Terms.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

12. CONTACT

If you have questions about these Terms, please contact us through the app store listing or the project's public repository.
''';

// ─── Chinese versions ────────────────────────────────────────────────────────

const String kPrivacyPolicyContentZh = '''
隐私政策 — Blinking（记忆闪烁）

生效日期：2026 年 3 月 21 日
应用名称：Blinking（记忆闪烁）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 概述

Blinking（记忆闪烁）是一款完全在您设备本地运行的个人记忆与习惯追踪应用。我们致力于保护您的隐私。

简而言之：Blinking 不收集、不传输、不分享任何个人数据。您的所有数据都保存在您的设备上。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2. 我们不收集的信息

我们不收集、存储或传输：
• 您的姓名、电子邮件、电话号码或任何身份信息
• 位置数据
• 设备标识符或广告 ID
• 使用分析数据或崩溃报告
• 您在应用中创建的任何内容（日记、习惯、笔记或媒体文件）

本应用无需账号、无需登录、无需注册。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3. 数据存储 — 仅限本地

您在 Blinking 中创建的所有数据均存储在您的设备上：

• 日记、习惯和卡片存储在设备本地的 SQLite 数据库中。
• 媒体文件（附加到日记的照片）存储在应用的私有文档目录中。
• 应用偏好设置（主题、语言、配置）存储在设备本地存储中。

我们不会将任何数据上传至服务器。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4. 网络连接

Blinking 设计为无需网络连接即可完整运行。所有核心功能 — 日记、习惯追踪、卡片制作、记忆罐和统计 — 均可完全离线使用。

本应用不需要互联网即可正常运行。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5. AI 助手功能（可选）

Blinking 包含一项可选的 AI 助手功能。该功能在试用期或 Pro 订阅期间可用。

AI 助手使用隐私保护架构：您的设备组装提示词，从 Blinking 获取匿名授权令牌，并直接与 AI 服务商通信。Blinking 不会永久存储您的日记内容。

重要说明：

• 当您使用 AI 助手时，您的日记内容和提示词通过 Blinking 的托管服务传输至第三方 AI 服务商。
• 第三方 AI 服务商可能会临时处理和存储您发送的数据。请阅读 AI 服务商的隐私政策。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

6. 权限

Blinking 可能请求以下设备权限：

相机 — 拍摄照片并附加到日记
相册 / 媒体图片 — 选择已有照片并附加到日记

仅在您尝试使用相关功能时才会请求权限。Blinking 不会在后台访问您的相机或相册。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

7. 数据导出与备份

Blinking 提供内置数据导出工具（ZIP 备份、JSON、CSV）。这些导出文件在您的设备本地生成，通过您设备的原生分享机制进行共享。我们不会收到您导出数据的副本。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

8. 儿童隐私

Blinking 不面向 13 岁以下儿童。我们不会故意收集儿童的任何信息。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

9. 本政策的变更

我们可能会不时更新本隐私政策。如有重大变更，我们将通过更新生效日期的方式通知您。在变更后继续使用本应用，即表示您接受更新后的政策。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

10. 联系我们

如您对本隐私政策有任何疑问，请通过应用商店页面或项目公开仓库联系我们。
''';

const String kTermsOfServiceContentZh = '''
服务条款 — Blinking（记忆闪烁）

生效日期：2026 年 3 月 21 日
应用名称：Blinking（记忆闪烁）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 条款接受

下载、安装或使用 Blinking（记忆闪烁）（"本应用"），即表示您同意受本服务条款约束。如您不同意，请勿使用本应用。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2. 服务说明

Blinking 是一款完全在您设备本地运行的个人记忆与习惯追踪应用，提供以下功能：
• 记录日记、情绪和记忆
• 追踪个人习惯与例程
• 创建和管理记忆卡片
• 查看个人统计与摘要
• 使用内置 AI 助手进行反思（可选）

本应用无需网络连接即可完整运行，无需账号或注册。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3. 许可

我们授予您有限的、非排他性的、不可转让的、可撤销的许可，仅供您个人、非商业目的使用本应用。

您不得：
• 复制、修改或分发本应用或其内容
• 对本应用进行逆向工程或尝试提取源代码
• 将本应用用于任何违法目的
• 以任何可能损害、禁用或损害本应用的方式使用

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4. 您的内容

您在应用中创建的所有内容（日记、习惯、笔记、媒体）均归您所有。我们不访问、不主张所有权，也不传输您的内容。

您的内容存储在您的设备本地。您有责任自行备份数据。因设备故障、应用卸载或其他原因导致的数据丢失，我们概不负责。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5. AI 助手功能（可选）

本应用包含可选的 AI 助手功能。该功能在试用期或 Pro 订阅期间可用。

使用 AI 助手功能，即表示您确认并同意：

• 您发送给 AI 助手的内容将传输至第三方 AI 服务商，该传输受该服务商自身的服务条款和隐私政策约束，而非本条款。
• 您不得使用 AI 助手生成违法、有害或冒犯性内容。
• 我们对 AI 生成的回复的准确性、可靠性或适当性不作任何保证。
• 您对使用 AI 生成内容所承担的风险负全责。

我们与任何第三方 AI 服务商均无关联，不受其背书，亦不对其负责。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

6. 隐私

您对本应用的使用亦受我们隐私政策的约束。要点如下：
• 本应用不收集或传输您的个人数据。
• 所有数据均存储在您的设备本地。
• 本应用可完全离线运行，不传输任何信息。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

7. 免责声明

本应用按"现状"和"现有状态"提供，不附带任何形式的明示或暗示保证，包括但不限于适销性、特定用途适用性或不侵权的保证。

我们不保证本应用将不中断、无错误或安全运行。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

8. 责任限制

在适用法律允许的最大范围内，对于因您使用本应用而引起的任何间接、附带、特殊、后果性或惩罚性损害（包括但不限于数据丢失或利润损失），我们概不负责。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

9. 数据丢失

我们对存储在应用中的任何数据丢失不承担责任。我们强烈建议定期使用内置备份功能（设置 → 完整备份）以保护您的数据。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

10. 第三方服务

本应用可选择性地与第三方服务（AI 服务商）集成。这些服务不由我们运营，我们对其内容、可用性或做法不负责任。您对任何第三方服务的使用受该服务自身的条款和隐私政策约束。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

11. 修改

我们保留随时修改或终止本应用的权利。我们也可能不时更新本条款。在变更后继续使用本应用，即表示您接受更新后的条款。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━

12. 联系我们

如您对本服务条款有任何疑问，请通过应用商店页面或项目公开仓库联系我们。
''';

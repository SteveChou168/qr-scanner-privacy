// lib/screens/settings_screen.dart

// TODO: 等 Flutter RadioGroup API 穩定後，將 RadioListTile 改為 RadioGroup 寫法
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_text.dart';
import '../growth/ui/cyber_detail_sheet.dart';
import '../growth/ui/cyber_forge_card.dart';
import '../growth/ui/cyber_workshop/workshop_view.dart';
import '../providers/settings_provider.dart';
import '../rewards/data/reward_constants.dart';
import '../rewards/logic/reward_service.dart';
import '../rewards/ui/reward_popup.dart';

const String kAppVersion = '1.0.0';

class SettingsScreen extends StatefulWidget {
  /// Whether this screen is currently visible/active.
  /// When false, animations are paused to save battery.
  final bool isActive;

  const SettingsScreen({super.key, this.isActive = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _handleGrowthCardTap(BuildContext context) async {
    final rewardService = RewardService.instance;

    // 首次點擊：顯示 intro popup
    if (!rewardService.hasSeenGrowthIntro) {
      await RewardUnlockPopup.showIntro(
        context,
        initialColors: RewardConstants.initialThemeColors,
        initialHistoryLimit: 500,
      );
      await rewardService.markGrowthIntroSeen();
    }

    // 顯示詳情 sheet
    if (context.mounted) {
      CyberDetailSheet.show(context);
    }
  }

  void _handleGrowthCardLongPress(BuildContext context) {
    // Easter egg: Open cyber workshop (hidden pomodoro timer)
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const CyberWorkshopView(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.settingsTitle),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: AppText.settingsAbout,
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            children: [
              // Growth System Card (conditionally shown)
              if (settings.showGrowthCard) ...[
                CyberForgeCard(
                  isActive: widget.isActive && settings.showGrowthCard,
                  onTap: () => _handleGrowthCardTap(context),
                  onLongPress: () => _handleGrowthCardLongPress(context),
                ),
                const SizedBox(height: 8),
              ],

              // Growth Journey Section
              _SectionHeader(title: AppText.settingsGrowthSection),
              SwitchListTile(
                title: Text(AppText.settingsShowGrowth),
                subtitle: Text(AppText.settingsShowGrowthDesc),
                value: settings.showGrowthCard,
                onChanged: (v) => settings.showGrowthCard = v,
              ),
              SwitchListTile(
                title: Text(AppText.settingsShowRewardPopups),
                subtitle: Text(AppText.settingsShowRewardPopupsDesc),
                value: settings.showRewardPopups,
                onChanged: settings.showGrowthCard
                    ? (v) => settings.showRewardPopups = v
                    : null,
              ),

              const Divider(),

              // Scan Settings
              _SectionHeader(title: AppText.settingsScanSection),
              SwitchListTile(
                title: Text(AppText.settingsVibration),
                subtitle: Text(AppText.settingsVibrationDesc),
                value: settings.vibration,
                onChanged: (v) => settings.vibration = v,
              ),
              SwitchListTile(
                title: Text(AppText.settingsSound),
                subtitle: Text(AppText.settingsSoundDesc),
                value: settings.sound,
                onChanged: (v) => settings.sound = v,
              ),
              SwitchListTile(
                title: Text(AppText.settingsAutoOpenUrl),
                subtitle: Text(AppText.settingsAutoOpenUrlDesc),
                value: settings.autoOpenUrl,
                onChanged: (v) => settings.autoOpenUrl = v,
              ),
              SwitchListTile(
                title: Text(AppText.settingsUseExternalBrowser),
                subtitle: Text(AppText.settingsUseExternalBrowserDesc),
                value: settings.useExternalBrowser,
                onChanged: (v) => settings.useExternalBrowser = v,
              ),
              SwitchListTile(
                title: Text(AppText.settingsContinuousScan),
                subtitle: Text(AppText.settingsContinuousScanDesc),
                value: settings.continuousScanMode,
                onChanged: (v) => settings.continuousScanMode = v,
              ),

              const Divider(),

              // History Settings
              _SectionHeader(title: AppText.settingsHistorySection),
              SwitchListTile(
                title: Text(AppText.settingsSaveImage),
                subtitle: Text(AppText.settingsSaveImageDesc),
                value: settings.saveImage,
                onChanged: (v) => settings.saveImage = v,
              ),
              SwitchListTile(
                title: Text(AppText.settingsSaveLocation),
                subtitle: Text(AppText.settingsSaveLocationDesc),
                value: settings.saveLocation,
                onChanged: (v) => settings.saveLocation = v,
              ),
              _buildHistoryLimitTile(context, settings),

              const Divider(),

              // Appearance
              _SectionHeader(title: AppText.settingsAppearanceSection),
              ListTile(
                title: Text(AppText.settingsTheme),
                subtitle: Text(_getThemeLabel(settings.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemePicker(context, settings),
              ),
              ListTile(
                title: Text(AppText.settingsThemeColor),
                subtitle: Text(AppText.settingsThemeColorDesc),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: settings.themeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                onTap: () => _showColorPicker(context, settings),
              ),
              ListTile(
                title: Text(AppText.settingsLanguage),
                subtitle: Text(settings.languageDisplayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguagePicker(context, settings),
              ),

              const Divider(),

              // About
              _SectionHeader(title: AppText.settingsAboutSection),
              ListTile(
                title: Text(AppText.settingsVersion),
                subtitle: const Text(kAppVersion),
              ),
              ListTile(
                title: Text(AppText.settingsPrivacy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacyInfo(context),
              ),

              const Divider(),

              // Open Source
              _SectionHeader(title: AppText.settingsOpenSource),
              _buildLicensesCard(context),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppText.aboutTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${AppText.settingsVersion}：$kAppVersion'),
              const SizedBox(height: 12),
              Text(
                AppText.aboutFeatures,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(AppText.aboutFeatureList),
              const SizedBox(height: 12),
              Text(AppText.aboutDisclaimer),
              const SizedBox(height: 12),
              Text(AppText.aboutPrivacy),
              const SizedBox(height: 12),
              const Text('© 2026 TDC Lab.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppText.btnClose),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => AppText.settingsThemeSystem,
      ThemeMode.light => AppText.settingsThemeLight,
      ThemeMode.dark => AppText.settingsThemeDark,
    };
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppText.settingsTheme,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppText.settingsThemeSystem),
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (v) {
                if (v != null) settings.themeMode = v;
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppText.settingsThemeLight),
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (v) {
                if (v != null) settings.themeMode = v;
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppText.settingsThemeDark),
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (v) {
                if (v != null) settings.themeMode = v;
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    final languages = [
      ('system', AppText.settingsLangSystem),
      ('zh', AppText.settingsLangZh),
      ('en', AppText.settingsLangEn),
      ('ja', AppText.settingsLangJa),
      ('es', AppText.settingsLangEs),
      ('pt', AppText.settingsLangPt),
      ('ko', AppText.settingsLangKo),
      ('vi', AppText.settingsLangVi),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppText.settingsLanguage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final (code, label) = languages[index];
                    return RadioListTile<String>(
                      title: Text(label),
                      value: code,
                      groupValue: settings.language,
                      onChanged: (v) async {
                        if (v != null) await settings.setLanguage(v);
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.settingsPrivacy),
        content: SingleChildScrollView(
          child: Text(AppText.privacyContent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppText.dialogClose),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, SettingsProvider settings) {
    final rewardService = RewardService.instance;
    final unlockedColors = rewardService.unlockedThemeColors;
    final nextColor = rewardService.nextThemeColorToUnlock;
    final locale = settings.language;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppText.settingsThemeColor,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            // 已解鎖的顏色
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: unlockedColors.map((reward) {
                  final isSelected = settings.themeColorId == reward.id;
                  return GestureDetector(
                    onTap: () async {
                      await settings.setThemeColorById(reward.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: reward.color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: reward.color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reward.getName(locale),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            // 下一個即將解鎖的顏色
            if (nextColor != null) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: nextColor.color.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.lock, size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextColor.getName(locale),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          Text(
                            nextColor.unlockCondition.getShortText(locale),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryLimitTile(BuildContext context, SettingsProvider settings) {
    final rewardService = RewardService.instance;
    final currentLimit = rewardService.currentHistoryLimit;
    final nextLimit = rewardService.nextHistoryLimitToUnlock;
    final locale = settings.language;

    final limitText = currentLimit < 0
        ? (locale == 'zh' ? '無上限' : locale == 'ja' ? '無制限' : 'Unlimited')
        : '$currentLimit';

    String? subtitleText;
    if (nextLimit != null) {
      final nextText = nextLimit.limit < 0
          ? (locale == 'zh' ? '無上限' : locale == 'ja' ? '無制限' : '∞')
          : '${nextLimit.limit}';
      subtitleText = '${nextLimit.unlockCondition.getShortText(locale)} → $nextText';
    }

    return ListTile(
      title: Text(AppText.settingsHistoryLimit),
      subtitle: subtitleText != null
          ? Text(subtitleText, style: TextStyle(color: Theme.of(context).colorScheme.primary))
          : Text(AppText.settingsHistoryLimitDesc),
      trailing: Text(
        limitText,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildLicensesCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.description_outlined, color: colorScheme.primary),
        title: Text(AppText.settingsLicenses),
        subtitle: Text(
          AppText.settingsLicensesSub,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.green.shade900.withValues(alpha: 0.3)
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: isDark
                            ? Colors.green.shade400
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppText.settingsLicensesNote,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.green.shade300
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: AppText.appTitle,
                      applicationVersion: kAppVersion,
                      applicationLegalese: '© 2025 TDC Lab.',
                    ),
                    icon: const Icon(Icons.launch, size: 18),
                    label: Text(AppText.settingsViewAllLicenses),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../app_text.dart';
import '../growth/logic/growth_service.dart';
import '../providers/settings_provider.dart';
import '../rewards/logic/reward_service.dart';
import '../rewards/ui/reward_popup.dart';
import '../services/ad_service.dart';
import 'scan_screen.dart';
import 'codex_screen.dart';
import 'history_screen.dart';
import 'generator_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  final AdService _adService = AdService();
  bool _inGalleryMode = false;

  // Use PageStorageBucket to preserve scroll positions
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _initAds();
    _checkPendingRewards();
  }

  void _initAds() {
    _adService.onBannerAdLoaded = () {
      if (mounted) setState(() {});
    };
    _adService.loadBannerAd();
  }

  /// 檢查是否有待顯示的獎勵彈窗
  void _checkPendingRewards() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // 檢查用戶是否關閉了獎勵通知
      final settings = context.read<SettingsProvider>();
      if (!settings.showRewardPopups) return;

      final growthService = GrowthService.instance;
      final rewardService = RewardService.instance;

      // 獲取待處理的登入結果
      final pendingResult = growthService.consumePendingResult();
      if (pendingResult == null) return;

      // 檢查模組完成獎勵
      if (pendingResult.completedModuleIndex != null &&
          pendingResult.completedModuleYear != null) {
        final rewards = rewardService.checkModuleCompleteRewards(
          pendingResult.completedModuleYear!,
          pendingResult.completedModuleIndex!,
        );

        if (rewards.hasNewRewards && mounted) {
          final moduleName = AppText.growthModuleName(
            _getModuleIdForIndex(
              pendingResult.completedModuleYear!,
              pendingResult.completedModuleIndex!,
            ),
          );
          await RewardUnlockPopup.show(
            context,
            result: rewards,
            moduleName: moduleName,
            isYearComplete: false,
          );
        }
      }

      // 檢查年度完成獎勵
      if (pendingResult.completedYear != null && mounted) {
        final rewards = rewardService.checkYearCompleteRewards(
          pendingResult.completedYear!,
        );

        if (rewards.hasNewRewards && mounted) {
          final yearTitle = switch (pendingResult.completedYear) {
            1 => AppText.growthYear1Title,
            2 => AppText.growthYear2Title,
            3 => AppText.growthYear3Title,
            _ => 'Year ${pendingResult.completedYear}',
          };
          await RewardUnlockPopup.show(
            context,
            result: rewards,
            moduleName: yearTitle,
            isYearComplete: true,
          );
        }
      }
    });
  }

  /// 根據年份和模組索引獲取模組 ID
  String _getModuleIdForIndex(int year, int moduleIndex) {
    // 這些 ID 與 growth_constants.dart 中的模組 ID 對應
    final moduleIds = switch (year) {
      1 => [
          'y1_physical_base', 'y1_energy_core', 'y1_optical_module',
          'y1_storage_array', 'y1_cooling_system', 'y1_comm_mast',
          'y1_structure_keel', 'y1_solar_wing', 'y1_repair_drones',
          'y1_quantum_shield', 'y1_data_relay', 'y1_propulsion',
          'y1_heavy_assembly', 'y1_ai_command', 'y1_ultimate_activation',
        ],
      2 => [
          'y2_neural_network', 'y2_spinal_frame', 'y2_energy_heart',
          'y2_visual_sensors', 'y2_left_power_arm', 'y2_right_work_arm',
          'y2_support_legs', 'y2_hydraulic_system', 'y2_internal_loop',
          'y2_defense_chestplate', 'y2_shoulder_radar', 'y2_jet_pack',
          'y2_shell_assembly', 'y2_ai_interface', 'y2_ultimate_awakening',
        ],
      3 => [
          'y3_underground_fiber', 'y3_giant_foundation', 'y3_power_room',
          'y3_cooling_pool', 'y3_central_stairs', 'y3_server_floor',
          'y3_data_terminal', 'y3_external_frame', 'y3_signal_tower',
          'y3_solar_curtain', 'y3_drone_port', 'y3_quantum_chamber',
          'y3_lightning_radar', 'y3_neon_spire', 'y3_data_ascension',
        ],
      _ => <String>[],
    };
    if (moduleIndex >= 0 && moduleIndex < moduleIds.length) {
      return moduleIds[moduleIndex];
    }
    return 'unknown_module';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onGalleryModeChanged(bool inGalleryMode) {
    setState(() {
      _inGalleryMode = inGalleryMode;
    });
  }

  // Show banner on all pages except Scan (index 0)
  // index 0: Scan, 1: Generator, 2: History, 3: Codex, 4: Settings
  bool get _shouldShowBanner => _currentIndex != 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageStorage(
              bucket: _bucket,
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                // 照片模式時禁止左右滑動，讓手勢用於照片平移
                physics: _inGalleryMode ? const NeverScrollableScrollPhysics() : null,
                children: [
                  ScanScreen(
                    isActive: _currentIndex == 0,
                    onGalleryModeChanged: _onGalleryModeChanged,
                  ),
                  const GeneratorScreen(),
                  const HistoryScreen(),
                  const CodexScreen(),
                  SettingsScreen(isActive: _currentIndex == 4),
                ],
              ),
            ),
          ),
          // Banner Ad - only show on History & Codex pages
          if (_shouldShowBanner && _adService.isBannerAdLoaded && _adService.bannerAd != null)
            Container(
              color: colorScheme.surface,
              width: _adService.bannerAd!.size.width.toDouble(),
              height: _adService.bannerAd!.size.height.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _adService.bannerAd!),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: const Icon(Icons.qr_code_scanner),
            label: AppText.navScan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_2_outlined),
            selectedIcon: const Icon(Icons.qr_code_2),
            label: AppText.navGenerator,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: AppText.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: const Icon(Icons.auto_awesome_mosaic),
            label: AppText.navCodex,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: AppText.navSettings,
          ),
        ],
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

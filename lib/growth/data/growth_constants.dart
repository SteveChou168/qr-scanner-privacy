import 'cyber_part.dart';
import 'year_config.dart';

/// Complete 3-year growth system constants.
///
/// Contains all 227 parts across 3 years:
/// - Year 1 (2026): 🛰️ Satellite Assembly - 99 parts
/// - Year 2 (2027): 🤖 Mecha Warrior - 68 parts
/// - Year 3 (2028): 🗼 Data Spire - 60 parts
abstract class GrowthConstants {
  /// Get the YearConfig for a specific year (1, 2, or 3).
  static YearConfig getYearConfig(int year) {
    return switch (year) {
      1 => year1Config,
      2 => year2Config,
      3 => year3Config,
      _ => throw ArgumentError('Invalid year: $year. Must be 1, 2, or 3.'),
    };
  }

  /// All year configurations.
  static const allYears = [year1Config, year2Config, year3Config];

  // ═══════════════════════════════════════════════════════════════════════════
  // YEAR 1 (2026): 🛰️ SATELLITE ASSEMBLY - 99 PARTS
  // Theme: "Stacking & Settling" - Deep cosmic black background
  // ═══════════════════════════════════════════════════════════════════════════

  static const year1Config = YearConfig(
    year: 1,
    awardEmoji: '🛰️',
    themeName: YearTheme.satellite,
    progressFormat: ProgressFormat.day,
    backgroundColors: YearColors.year1Background,
    accentColor: YearColors.year1Accent,
    modules: _year1Modules,
  );

  static const _year1Modules = [
    // Round 01: 物理底座 Physical Base (6 parts)
    ModuleConfig(
      id: 'y1_physical_base',
      moduleIndex: 0,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m0_p0_screw', emoji: '🔩', year: 1, moduleIndex: 0, partIndex: 0),
        CyberPart(id: 'y1_m0_p1_brick', emoji: '🧱', year: 1, moduleIndex: 0, partIndex: 1),
        CyberPart(id: 'y1_m0_p2_construction', emoji: '🏗️', year: 1, moduleIndex: 0, partIndex: 2),
        CyberPart(id: 'y1_m0_p3_hammer', emoji: '🔨', year: 1, moduleIndex: 0, partIndex: 3),
        CyberPart(id: 'y1_m0_p4_ladder', emoji: '🪜', year: 1, moduleIndex: 0, partIndex: 4),
        CyberPart(id: 'y1_m0_p5_ruler', emoji: '📏', year: 1, moduleIndex: 0, partIndex: 5),
      ],
    ),
    // Round 02: 能源核心 Energy Core (7 parts)
    ModuleConfig(
      id: 'y1_energy_core',
      moduleIndex: 1,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m1_p0_battery', emoji: '🔋', year: 1, moduleIndex: 1, partIndex: 0),
        CyberPart(id: 'y1_m1_p1_plug', emoji: '🔌', year: 1, moduleIndex: 1, partIndex: 1),
        CyberPart(id: 'y1_m1_p2_lightning', emoji: '⚡', year: 1, moduleIndex: 1, partIndex: 2),
        CyberPart(id: 'y1_m1_p3_gear', emoji: '⚙️', year: 1, moduleIndex: 1, partIndex: 3),
        CyberPart(id: 'y1_m1_p4_fire', emoji: '🔥', year: 1, moduleIndex: 1, partIndex: 4),
        CyberPart(id: 'y1_m1_p5_hotspring', emoji: '♨️', year: 1, moduleIndex: 1, partIndex: 5),
        CyberPart(id: 'y1_m1_p6_flask', emoji: '🧪', year: 1, moduleIndex: 1, partIndex: 6),
      ],
    ),
    // Round 03: 光學模組 Optical Module (7 parts)
    ModuleConfig(
      id: 'y1_optical_module',
      moduleIndex: 2,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m2_p0_magnify', emoji: '🔍', year: 1, moduleIndex: 2, partIndex: 0),
        CyberPart(id: 'y1_m2_p1_telescope', emoji: '🔭', year: 1, moduleIndex: 2, partIndex: 1),
        CyberPart(id: 'y1_m2_p2_crystal', emoji: '🔮', year: 1, moduleIndex: 2, partIndex: 2),
        CyberPart(id: 'y1_m2_p3_eye', emoji: '👁️', year: 1, moduleIndex: 2, partIndex: 3),
        CyberPart(id: 'y1_m2_p4_camera', emoji: '📸', year: 1, moduleIndex: 2, partIndex: 4),
        CyberPart(id: 'y1_m2_p5_flashlight', emoji: '🔦', year: 1, moduleIndex: 2, partIndex: 5),
        CyberPart(id: 'y1_m2_p6_rainbow', emoji: '🌈', year: 1, moduleIndex: 2, partIndex: 6),
      ],
    ),
    // Round 04: 存儲陣列 Storage Array (7 parts)
    ModuleConfig(
      id: 'y1_storage_array',
      moduleIndex: 3,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m3_p0_floppy', emoji: '💾', year: 1, moduleIndex: 3, partIndex: 0),
        CyberPart(id: 'y1_m3_p1_folder', emoji: '📁', year: 1, moduleIndex: 3, partIndex: 1),
        CyberPart(id: 'y1_m3_p2_folderopen', emoji: '📂', year: 1, moduleIndex: 3, partIndex: 2),
        CyberPart(id: 'y1_m3_p3_cd', emoji: '💿', year: 1, moduleIndex: 3, partIndex: 3),
        CyberPart(id: 'y1_m3_p4_vhs', emoji: '📼', year: 1, moduleIndex: 3, partIndex: 4),
        CyberPart(id: 'y1_m3_p5_pager', emoji: '📟', year: 1, moduleIndex: 3, partIndex: 5),
        CyberPart(id: 'y1_m3_p6_brain', emoji: '🧠', year: 1, moduleIndex: 3, partIndex: 6),
      ],
    ),
    // Round 05: 冷卻系統 Cooling System (7 parts)
    ModuleConfig(
      id: 'y1_cooling_system',
      moduleIndex: 4,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m4_p0_thermometer', emoji: '🌡️', year: 1, moduleIndex: 4, partIndex: 0),
        CyberPart(id: 'y1_m4_p1_snowflake', emoji: '❄️', year: 1, moduleIndex: 4, partIndex: 1),
        CyberPart(id: 'y1_m4_p2_ice', emoji: '🧊', year: 1, moduleIndex: 4, partIndex: 2),
        CyberPart(id: 'y1_m4_p3_flask2', emoji: '🧪', year: 1, moduleIndex: 4, partIndex: 3),
        CyberPart(id: 'y1_m4_p4_droplet', emoji: '💧', year: 1, moduleIndex: 4, partIndex: 4),
        CyberPart(id: 'y1_m4_p5_wind', emoji: '🌬️', year: 1, moduleIndex: 4, partIndex: 5),
        CyberPart(id: 'y1_m4_p6_bubble', emoji: '🫧', year: 1, moduleIndex: 4, partIndex: 6),
      ],
    ),
    // Round 06: 通訊桅桿 Comm Mast (7 parts)
    ModuleConfig(
      id: 'y1_comm_mast',
      moduleIndex: 5,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m5_p0_satellite_dish', emoji: '📡', year: 1, moduleIndex: 5, partIndex: 0),
        CyberPart(id: 'y1_m5_p1_signal', emoji: '📶', year: 1, moduleIndex: 5, partIndex: 1),
        CyberPart(id: 'y1_m5_p2_pager_reuse', emoji: '📟', year: 1, moduleIndex: 5, partIndex: 2, isReuse: true, reuseSourceId: 'y1_m3_p5_pager', reuseFromYear: 1),
        CyberPart(id: 'y1_m5_p3_phone', emoji: '☎️', year: 1, moduleIndex: 5, partIndex: 3),
        CyberPart(id: 'y1_m5_p4_megaphone', emoji: '📢', year: 1, moduleIndex: 5, partIndex: 4),
        CyberPart(id: 'y1_m5_p5_radio', emoji: '📻', year: 1, moduleIndex: 5, partIndex: 5),
        CyberPart(id: 'y1_m5_p6_globe', emoji: '🌐', year: 1, moduleIndex: 5, partIndex: 6),
      ],
    ),
    // Round 07: 結構龍骨 Structure Keel (6 parts)
    ModuleConfig(
      id: 'y1_structure_keel',
      moduleIndex: 6,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m6_p0_screw_reuse', emoji: '🔩', year: 1, moduleIndex: 6, partIndex: 0, isReuse: true, reuseSourceId: 'y1_m0_p0_screw', reuseFromYear: 1),
        CyberPart(id: 'y1_m6_p1_chain', emoji: '⛓️', year: 1, moduleIndex: 6, partIndex: 1),
        CyberPart(id: 'y1_m6_p2_link', emoji: '🔗', year: 1, moduleIndex: 6, partIndex: 2),
        CyberPart(id: 'y1_m6_p3_paperclip', emoji: '📎', year: 1, moduleIndex: 6, partIndex: 3),
        CyberPart(id: 'y1_m6_p4_shield', emoji: '🛡️', year: 1, moduleIndex: 6, partIndex: 4),
        CyberPart(id: 'y1_m6_p5_barrier', emoji: '🚧', year: 1, moduleIndex: 6, partIndex: 5),
      ],
    ),
    // Round 08: 光能翼板 Solar Wing (7 parts)
    ModuleConfig(
      id: 'y1_solar_wing',
      moduleIndex: 7,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m7_p0_bluesquare', emoji: '🟦', year: 1, moduleIndex: 7, partIndex: 0),
        CyberPart(id: 'y1_m7_p1_triangle', emoji: '📐', year: 1, moduleIndex: 7, partIndex: 1),
        CyberPart(id: 'y1_m7_p2_sun', emoji: '☀️', year: 1, moduleIndex: 7, partIndex: 2),
        CyberPart(id: 'y1_m7_p3_lightning_reuse', emoji: '⚡', year: 1, moduleIndex: 7, partIndex: 3, isReuse: true, reuseSourceId: 'y1_m1_p2_lightning', reuseFromYear: 1),
        CyberPart(id: 'y1_m7_p4_dish_reuse', emoji: '📡', year: 1, moduleIndex: 7, partIndex: 4, isReuse: true, reuseSourceId: 'y1_m5_p0_satellite_dish', reuseFromYear: 1),
        CyberPart(id: 'y1_m7_p5_sparkles', emoji: '✨', year: 1, moduleIndex: 7, partIndex: 5),
        CyberPart(id: 'y1_m7_p6_map', emoji: '🗺️', year: 1, moduleIndex: 7, partIndex: 6),
      ],
    ),
    // Round 09: 維修工蜂 Repair Drones (7 parts)
    ModuleConfig(
      id: 'y1_repair_drones',
      moduleIndex: 8,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m8_p0_ufo', emoji: '🛸', year: 1, moduleIndex: 8, partIndex: 0),
        CyberPart(id: 'y1_m8_p1_mecharm', emoji: '🦾', year: 1, moduleIndex: 8, partIndex: 1),
        CyberPart(id: 'y1_m8_p2_wrench', emoji: '🔧', year: 1, moduleIndex: 8, partIndex: 2),
        CyberPart(id: 'y1_m8_p3_tools', emoji: '🛠️', year: 1, moduleIndex: 8, partIndex: 3),
        CyberPart(id: 'y1_m8_p4_screw_reuse2', emoji: '🔩', year: 1, moduleIndex: 8, partIndex: 4, isReuse: true, reuseSourceId: 'y1_m0_p0_screw', reuseFromYear: 1),
        CyberPart(id: 'y1_m8_p5_screwdriver', emoji: '🪛', year: 1, moduleIndex: 8, partIndex: 5),
        CyberPart(id: 'y1_m8_p6_gear_reuse', emoji: '⚙️', year: 1, moduleIndex: 8, partIndex: 6, isReuse: true, reuseSourceId: 'y1_m1_p3_gear', reuseFromYear: 1),
      ],
    ),
    // Round 10: 量子防護 Quantum Shield (6 parts)
    ModuleConfig(
      id: 'y1_quantum_shield',
      moduleIndex: 9,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m9_p0_shield_reuse', emoji: '🛡️', year: 1, moduleIndex: 9, partIndex: 0, isReuse: true, reuseSourceId: 'y1_m6_p4_shield', reuseFromYear: 1),
        CyberPart(id: 'y1_m9_p1_diamond', emoji: '💎', year: 1, moduleIndex: 9, partIndex: 1),
        CyberPart(id: 'y1_m9_p2_purple', emoji: '🟣', year: 1, moduleIndex: 9, partIndex: 2),
        CyberPart(id: 'y1_m9_p3_bubble_reuse', emoji: '🫧', year: 1, moduleIndex: 9, partIndex: 3, isReuse: true, reuseSourceId: 'y1_m4_p6_bubble', reuseFromYear: 1),
        CyberPart(id: 'y1_m9_p4_windchime', emoji: '🎐', year: 1, moduleIndex: 9, partIndex: 4),
        CyberPart(id: 'y1_m9_p5_nazareye', emoji: '🧿', year: 1, moduleIndex: 9, partIndex: 5),
      ],
    ),
    // Round 11: 數據中繼 Data Relay (6 parts)
    ModuleConfig(
      id: 'y1_data_relay',
      moduleIndex: 10,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m10_p0_dish_reuse2', emoji: '📡', year: 1, moduleIndex: 10, partIndex: 0, isReuse: true, reuseSourceId: 'y1_m5_p0_satellite_dish', reuseFromYear: 1),
        CyberPart(id: 'y1_m10_p1_plug_reuse', emoji: '🔌', year: 1, moduleIndex: 10, partIndex: 1, isReuse: true, reuseSourceId: 'y1_m1_p1_plug', reuseFromYear: 1),
        CyberPart(id: 'y1_m10_p2_floppy_reuse', emoji: '💾', year: 1, moduleIndex: 10, partIndex: 2, isReuse: true, reuseSourceId: 'y1_m3_p0_floppy', reuseFromYear: 1),
        CyberPart(id: 'y1_m10_p3_pager_reuse2', emoji: '📟', year: 1, moduleIndex: 10, partIndex: 3, isReuse: true, reuseSourceId: 'y1_m3_p5_pager', reuseFromYear: 1),
        CyberPart(id: 'y1_m10_p4_ufo_reuse', emoji: '🛸', year: 1, moduleIndex: 10, partIndex: 4, isReuse: true, reuseSourceId: 'y1_m8_p0_ufo', reuseFromYear: 1),
        CyberPart(id: 'y1_m10_p5_satellite', emoji: '🛰️', year: 1, moduleIndex: 10, partIndex: 5),
      ],
    ),
    // Round 12: 推進噴口 Propulsion (7 parts)
    ModuleConfig(
      id: 'y1_propulsion',
      moduleIndex: 11,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m11_p0_fuel', emoji: '⛽', year: 1, moduleIndex: 11, partIndex: 0),
        CyberPart(id: 'y1_m11_p1_fire_reuse', emoji: '🔥', year: 1, moduleIndex: 11, partIndex: 1, isReuse: true, reuseSourceId: 'y1_m1_p4_fire', reuseFromYear: 1),
        CyberPart(id: 'y1_m11_p2_rocket', emoji: '🚀', year: 1, moduleIndex: 11, partIndex: 2),
        CyberPart(id: 'y1_m11_p3_comet', emoji: '☄️', year: 1, moduleIndex: 11, partIndex: 3),
        CyberPart(id: 'y1_m11_p4_fireworks', emoji: '🎇', year: 1, moduleIndex: 11, partIndex: 4),
        CyberPart(id: 'y1_m11_p5_boom', emoji: '💥', year: 1, moduleIndex: 11, partIndex: 5),
        CyberPart(id: 'y1_m11_p6_cyclone', emoji: '🌀', year: 1, moduleIndex: 11, partIndex: 6),
      ],
    ),
    // Round 13: 重裝合成 Heavy Assembly (6 parts)
    ModuleConfig(
      id: 'y1_heavy_assembly',
      moduleIndex: 12,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m12_p0_construction_reuse', emoji: '🏗️', year: 1, moduleIndex: 12, partIndex: 0, isReuse: true, reuseSourceId: 'y1_m0_p2_construction', reuseFromYear: 1),
        CyberPart(id: 'y1_m12_p1_brick_reuse', emoji: '🧱', year: 1, moduleIndex: 12, partIndex: 1, isReuse: true, reuseSourceId: 'y1_m0_p1_brick', reuseFromYear: 1),
        CyberPart(id: 'y1_m12_p2_chain_reuse', emoji: '⛓️', year: 1, moduleIndex: 12, partIndex: 2, isReuse: true, reuseSourceId: 'y1_m6_p1_chain', reuseFromYear: 1),
        CyberPart(id: 'y1_m12_p3_screw_reuse3', emoji: '🔩', year: 1, moduleIndex: 12, partIndex: 3, isReuse: true, reuseSourceId: 'y1_m0_p0_screw', reuseFromYear: 1),
        CyberPart(id: 'y1_m12_p4_diamond_reuse', emoji: '💎', year: 1, moduleIndex: 12, partIndex: 4, isReuse: true, reuseSourceId: 'y1_m9_p1_diamond', reuseFromYear: 1),
        CyberPart(id: 'y1_m12_p5_shield_reuse2', emoji: '🛡️', year: 1, moduleIndex: 12, partIndex: 5, isReuse: true, reuseSourceId: 'y1_m6_p4_shield', reuseFromYear: 1),
      ],
    ),
    // Round 14: AI指揮台 AI Command (7 parts)
    ModuleConfig(
      id: 'y1_ai_command',
      moduleIndex: 13,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m13_p0_joystick', emoji: '🕹️', year: 1, moduleIndex: 13, partIndex: 0),
        CyberPart(id: 'y1_m13_p1_alien', emoji: '👾', year: 1, moduleIndex: 13, partIndex: 1),
        CyberPart(id: 'y1_m13_p2_laptop', emoji: '💻', year: 1, moduleIndex: 13, partIndex: 2),
        CyberPart(id: 'y1_m13_p3_mobile', emoji: '📱', year: 1, moduleIndex: 13, partIndex: 3),
        CyberPart(id: 'y1_m13_p4_brain_reuse', emoji: '🧠', year: 1, moduleIndex: 13, partIndex: 4, isReuse: true, reuseSourceId: 'y1_m3_p6_brain', reuseFromYear: 1),
        CyberPart(id: 'y1_m13_p5_eye_reuse', emoji: '👁️', year: 1, moduleIndex: 13, partIndex: 5, isReuse: true, reuseSourceId: 'y1_m2_p3_eye', reuseFromYear: 1),
        CyberPart(id: 'y1_m13_p6_robot', emoji: '🤖', year: 1, moduleIndex: 13, partIndex: 6),
      ],
    ),
    // Round 15: 終極啟動 Ultimate Activation (7 parts)
    ModuleConfig(
      id: 'y1_ultimate_activation',
      moduleIndex: 14,
      year: 1,
      parts: [
        CyberPart(id: 'y1_m14_p0_sparkles_reuse', emoji: '✨', year: 1, moduleIndex: 14, partIndex: 0, isReuse: true, reuseSourceId: 'y1_m7_p5_sparkles', reuseFromYear: 1),
        CyberPart(id: 'y1_m14_p1_rainbow_reuse', emoji: '🌈', year: 1, moduleIndex: 14, partIndex: 1, isReuse: true, reuseSourceId: 'y1_m2_p6_rainbow', reuseFromYear: 1),
        CyberPart(id: 'y1_m14_p2_star', emoji: '⭐', year: 1, moduleIndex: 14, partIndex: 2),
        CyberPart(id: 'y1_m14_p3_glowstar', emoji: '🌟', year: 1, moduleIndex: 14, partIndex: 3),
        CyberPart(id: 'y1_m14_p4_sun_reuse', emoji: '☀️', year: 1, moduleIndex: 14, partIndex: 4, isReuse: true, reuseSourceId: 'y1_m7_p2_sun', reuseFromYear: 1),
        CyberPart(id: 'y1_m14_p5_cyclone_reuse', emoji: '🌀', year: 1, moduleIndex: 14, partIndex: 5, isReuse: true, reuseSourceId: 'y1_m11_p6_cyclone', reuseFromYear: 1),
        CyberPart(id: 'y1_m14_p6_milkyway', emoji: '🌌', year: 1, moduleIndex: 14, partIndex: 6),
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // YEAR 2 (2027): 🤖 MECHA WARRIOR - 95 PARTS
  // Theme: "Inside Out" - Factory grid with spark effects
  // ═══════════════════════════════════════════════════════════════════════════

  static const year2Config = YearConfig(
    year: 2,
    awardEmoji: '🤖',
    themeName: YearTheme.mecha,
    progressFormat: ProgressFormat.sync,
    backgroundColors: YearColors.year2Background,
    accentColor: YearColors.year2Accent,
    modules: _year2Modules,
  );

  static const _year2Modules = [
    // Round 01: 神經網路 Neural Network (7 parts)
    ModuleConfig(
      id: 'y2_neural_network',
      moduleIndex: 0,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m0_p0_brain', emoji: '🧠', year: 2, moduleIndex: 0, partIndex: 0),
        CyberPart(id: 'y2_m0_p1_dna', emoji: '🧬', year: 2, moduleIndex: 0, partIndex: 1),
        CyberPart(id: 'y2_m0_p2_dna2', emoji: '🧬', year: 2, moduleIndex: 0, partIndex: 2),
        CyberPart(id: 'y2_m0_p3_chain', emoji: '⛓️', year: 2, moduleIndex: 0, partIndex: 3),
        CyberPart(id: 'y2_m0_p4_plug', emoji: '🔌', year: 2, moduleIndex: 0, partIndex: 4),
        CyberPart(id: 'y2_m0_p5_link', emoji: '🔗', year: 2, moduleIndex: 0, partIndex: 5),
        CyberPart(id: 'y2_m0_p6_thread', emoji: '🧵', year: 2, moduleIndex: 0, partIndex: 6),
      ],
    ),
    // Round 02: 脊椎骨架 Spinal Frame (7 parts)
    ModuleConfig(
      id: 'y2_spinal_frame',
      moduleIndex: 1,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m1_p0_bone', emoji: '🦴', year: 2, moduleIndex: 1, partIndex: 0),
        CyberPart(id: 'y2_m1_p1_bone2', emoji: '🦴', year: 2, moduleIndex: 1, partIndex: 1),
        CyberPart(id: 'y2_m1_p2_screw', emoji: '🔩', year: 2, moduleIndex: 1, partIndex: 2),
        CyberPart(id: 'y2_m1_p3_hammer', emoji: '🔨', year: 2, moduleIndex: 1, partIndex: 3),
        CyberPart(id: 'y2_m1_p4_ladder', emoji: '🪜', year: 2, moduleIndex: 1, partIndex: 4),
        CyberPart(id: 'y2_m1_p5_ruler', emoji: '📏', year: 2, moduleIndex: 1, partIndex: 5),
        CyberPart(id: 'y2_m1_p6_clip', emoji: '📎', year: 2, moduleIndex: 1, partIndex: 6),
      ],
    ),
    // Round 03: 能源心臟 Energy Heart (7 parts)
    ModuleConfig(
      id: 'y2_energy_heart',
      moduleIndex: 2,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m2_p0_heart', emoji: '🫀', year: 2, moduleIndex: 2, partIndex: 0),
        CyberPart(id: 'y2_m2_p1_battery', emoji: '🔋', year: 2, moduleIndex: 2, partIndex: 1),
        CyberPart(id: 'y2_m2_p2_lightning', emoji: '⚡', year: 2, moduleIndex: 2, partIndex: 2),
        CyberPart(id: 'y2_m2_p3_fire', emoji: '🔥', year: 2, moduleIndex: 2, partIndex: 3),
        CyberPart(id: 'y2_m2_p4_diamond', emoji: '💎', year: 2, moduleIndex: 2, partIndex: 4),
        CyberPart(id: 'y2_m2_p5_red_circle', emoji: '🔴', year: 2, moduleIndex: 2, partIndex: 5),
        CyberPart(id: 'y2_m2_p6_firecracker', emoji: '🧨', year: 2, moduleIndex: 2, partIndex: 6),
      ],
    ),
    // Round 04: 視覺感知 Visual Sensors (7 parts)
    ModuleConfig(
      id: 'y2_visual_sensors',
      moduleIndex: 3,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m3_p0_eye', emoji: '👁️', year: 2, moduleIndex: 3, partIndex: 0),
        CyberPart(id: 'y2_m3_p1_camera', emoji: '📸', year: 2, moduleIndex: 3, partIndex: 1),
        CyberPart(id: 'y2_m3_p2_flashlight', emoji: '🔦', year: 2, moduleIndex: 3, partIndex: 2),
        CyberPart(id: 'y2_m3_p3_crystal', emoji: '🔮', year: 2, moduleIndex: 3, partIndex: 3),
        CyberPart(id: 'y2_m3_p4_dish', emoji: '📡', year: 2, moduleIndex: 3, partIndex: 4),
        CyberPart(id: 'y2_m3_p5_telescope', emoji: '🔭', year: 2, moduleIndex: 3, partIndex: 5),
        CyberPart(id: 'y2_m3_p6_candle', emoji: '🕯️', year: 2, moduleIndex: 3, partIndex: 6),
      ],
    ),
    // Round 05: 左舷動力臂 Left Power Arm (7 parts)
    ModuleConfig(
      id: 'y2_left_power_arm',
      moduleIndex: 4,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m4_p0_mecharm', emoji: '🦾', year: 2, moduleIndex: 4, partIndex: 0),
        CyberPart(id: 'y2_m4_p1_gear', emoji: '⚙️', year: 2, moduleIndex: 4, partIndex: 1),
        CyberPart(id: 'y2_m4_p2_wrench', emoji: '🔧', year: 2, moduleIndex: 4, partIndex: 2),
        CyberPart(id: 'y2_m4_p3_screw', emoji: '🔩', year: 2, moduleIndex: 4, partIndex: 3),
        CyberPart(id: 'y2_m4_p4_fist', emoji: '✊', year: 2, moduleIndex: 4, partIndex: 4),
        CyberPart(id: 'y2_m4_p5_hammer', emoji: '🔨', year: 2, moduleIndex: 4, partIndex: 5),
        CyberPart(id: 'y2_m4_p6_tools', emoji: '🛠️', year: 2, moduleIndex: 4, partIndex: 6),
      ],
    ),
    // Round 06: 右舷作業臂 Right Work Arm (6 parts)
    ModuleConfig(
      id: 'y2_right_work_arm',
      moduleIndex: 5,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m5_p0_mecharm', emoji: '🦾', year: 2, moduleIndex: 5, partIndex: 0),
        CyberPart(id: 'y2_m5_p1_screwdriver', emoji: '🪛', year: 2, moduleIndex: 5, partIndex: 1),
        CyberPart(id: 'y2_m5_p2_tools', emoji: '🛠️', year: 2, moduleIndex: 5, partIndex: 2),
        CyberPart(id: 'y2_m5_p3_chain', emoji: '⛓️', year: 2, moduleIndex: 5, partIndex: 3),
        CyberPart(id: 'y2_m5_p4_satellite', emoji: '🛰️', year: 2, moduleIndex: 5, partIndex: 4),
        CyberPart(id: 'y2_m5_p5_clamp', emoji: '🗜️', year: 2, moduleIndex: 5, partIndex: 5),
      ],
    ),
    // Round 07: 支撐下肢 Support Legs (6 parts)
    ModuleConfig(
      id: 'y2_support_legs',
      moduleIndex: 6,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m6_p0_mechleg', emoji: '🦿', year: 2, moduleIndex: 6, partIndex: 0),
        CyberPart(id: 'y2_m6_p1_gear', emoji: '⚙️', year: 2, moduleIndex: 6, partIndex: 1),
        CyberPart(id: 'y2_m6_p2_brick', emoji: '🧱', year: 2, moduleIndex: 6, partIndex: 2),
        CyberPart(id: 'y2_m6_p3_construction', emoji: '🏗️', year: 2, moduleIndex: 6, partIndex: 3),
        CyberPart(id: 'y2_m6_p4_foot', emoji: '🦶', year: 2, moduleIndex: 6, partIndex: 4),
        CyberPart(id: 'y2_m6_p5_shoe', emoji: '👟', year: 2, moduleIndex: 6, partIndex: 5),
      ],
    ),
    // Round 08: 液壓系統 Hydraulic System (7 parts)
    ModuleConfig(
      id: 'y2_hydraulic_system',
      moduleIndex: 7,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m7_p0_droplet', emoji: '💧', year: 2, moduleIndex: 7, partIndex: 0),
        CyberPart(id: 'y2_m7_p1_flask', emoji: '🧪', year: 2, moduleIndex: 7, partIndex: 1),
        CyberPart(id: 'y2_m7_p2_thermometer', emoji: '🌡️', year: 2, moduleIndex: 7, partIndex: 2),
        CyberPart(id: 'y2_m7_p3_snowflake', emoji: '❄️', year: 2, moduleIndex: 7, partIndex: 3),
        CyberPart(id: 'y2_m7_p4_ice', emoji: '🧊', year: 2, moduleIndex: 7, partIndex: 4),
        CyberPart(id: 'y2_m7_p5_faucet', emoji: '🚰', year: 2, moduleIndex: 7, partIndex: 5),
        CyberPart(id: 'y2_m7_p6_lotion', emoji: '🧴', year: 2, moduleIndex: 7, partIndex: 6),
      ],
    ),
    // Round 09: 內部循環 Internal Loop (6 parts)
    ModuleConfig(
      id: 'y2_internal_loop',
      moduleIndex: 8,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m8_p0_blood', emoji: '🩸', year: 2, moduleIndex: 8, partIndex: 0),
        CyberPart(id: 'y2_m8_p1_dna', emoji: '🧬', year: 2, moduleIndex: 8, partIndex: 1),
        CyberPart(id: 'y2_m8_p2_battery', emoji: '🔋', year: 2, moduleIndex: 8, partIndex: 2),
        CyberPart(id: 'y2_m8_p3_lightning', emoji: '⚡', year: 2, moduleIndex: 8, partIndex: 3),
        CyberPart(id: 'y2_m8_p4_syringe', emoji: '💉', year: 2, moduleIndex: 8, partIndex: 4),
        CyberPart(id: 'y2_m8_p5_pill', emoji: '💊', year: 2, moduleIndex: 8, partIndex: 5),
      ],
    ),
    // Round 10: 防禦胸甲 Defense Chestplate (6 parts)
    ModuleConfig(
      id: 'y2_defense_chestplate',
      moduleIndex: 9,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m9_p0_shield', emoji: '🛡️', year: 2, moduleIndex: 9, partIndex: 0),
        CyberPart(id: 'y2_m9_p1_brick', emoji: '🧱', year: 2, moduleIndex: 9, partIndex: 1),
        CyberPart(id: 'y2_m9_p2_screw', emoji: '🔩', year: 2, moduleIndex: 9, partIndex: 2),
        CyberPart(id: 'y2_m9_p3_barrier', emoji: '🚧', year: 2, moduleIndex: 9, partIndex: 3),
        CyberPart(id: 'y2_m9_p4_brick2', emoji: '🧱', year: 2, moduleIndex: 9, partIndex: 4),
        CyberPart(id: 'y2_m9_p5_screw2', emoji: '🔩', year: 2, moduleIndex: 9, partIndex: 5),
      ],
    ),
    // Round 11: 肩部雷達 Shoulder Radar (6 parts)
    ModuleConfig(
      id: 'y2_shoulder_radar',
      moduleIndex: 10,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m10_p0_dish', emoji: '📡', year: 2, moduleIndex: 10, partIndex: 0),
        CyberPart(id: 'y2_m10_p1_signal', emoji: '📶', year: 2, moduleIndex: 10, partIndex: 1),
        CyberPart(id: 'y2_m10_p2_dish2', emoji: '📡', year: 2, moduleIndex: 10, partIndex: 2),
        CyberPart(id: 'y2_m10_p3_pager', emoji: '📟', year: 2, moduleIndex: 10, partIndex: 3),
        CyberPart(id: 'y2_m10_p4_radio', emoji: '📻', year: 2, moduleIndex: 10, partIndex: 4),
        CyberPart(id: 'y2_m10_p5_fax', emoji: '📠', year: 2, moduleIndex: 10, partIndex: 5),
      ],
    ),
    // Round 12: 噴射背囊 Jet Pack (6 parts)
    ModuleConfig(
      id: 'y2_jet_pack',
      moduleIndex: 11,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m11_p0_rocket', emoji: '🚀', year: 2, moduleIndex: 11, partIndex: 0),
        CyberPart(id: 'y2_m11_p1_fire', emoji: '🔥', year: 2, moduleIndex: 11, partIndex: 1),
        CyberPart(id: 'y2_m11_p2_dash', emoji: '💨', year: 2, moduleIndex: 11, partIndex: 2),
        CyberPart(id: 'y2_m11_p3_fireworks', emoji: '🎇', year: 2, moduleIndex: 11, partIndex: 3),
        CyberPart(id: 'y2_m11_p4_boom', emoji: '💥', year: 2, moduleIndex: 11, partIndex: 4),
        CyberPart(id: 'y2_m11_p5_cyclone', emoji: '🌀', year: 2, moduleIndex: 11, partIndex: 5),
      ],
    ),
    // Round 13: 外殼總成 Shell Assembly (6 parts)
    ModuleConfig(
      id: 'y2_shell_assembly',
      moduleIndex: 12,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m12_p0_brick', emoji: '🧱', year: 2, moduleIndex: 12, partIndex: 0),
        CyberPart(id: 'y2_m12_p1_shield', emoji: '🛡️', year: 2, moduleIndex: 12, partIndex: 1),
        CyberPart(id: 'y2_m12_p2_diamond', emoji: '💎', year: 2, moduleIndex: 12, partIndex: 2),
        CyberPart(id: 'y2_m12_p3_gear', emoji: '⚙️', year: 2, moduleIndex: 12, partIndex: 3),
        CyberPart(id: 'y2_m12_p4_screw', emoji: '🔩', year: 2, moduleIndex: 12, partIndex: 4),
        CyberPart(id: 'y2_m12_p5_screw2', emoji: '🔩', year: 2, moduleIndex: 12, partIndex: 5),
      ],
    ),
    // Round 14: AI介面 AI Interface (6 parts)
    ModuleConfig(
      id: 'y2_ai_interface',
      moduleIndex: 13,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m13_p0_laptop', emoji: '💻', year: 2, moduleIndex: 13, partIndex: 0),
        CyberPart(id: 'y2_m13_p1_mobile', emoji: '📱', year: 2, moduleIndex: 13, partIndex: 1),
        CyberPart(id: 'y2_m13_p2_joystick', emoji: '🕹️', year: 2, moduleIndex: 13, partIndex: 2),
        CyberPart(id: 'y2_m13_p3_alien', emoji: '👾', year: 2, moduleIndex: 13, partIndex: 3),
        CyberPart(id: 'y2_m13_p4_robot', emoji: '🤖', year: 2, moduleIndex: 13, partIndex: 4),
        CyberPart(id: 'y2_m13_p5_pager', emoji: '📟', year: 2, moduleIndex: 13, partIndex: 5),
      ],
    ),
    // Round 15: 終極覺醒 Ultimate Awakening (7 parts)
    ModuleConfig(
      id: 'y2_ultimate_awakening',
      moduleIndex: 14,
      year: 2,
      parts: [
        CyberPart(id: 'y2_m14_p0_sparkles', emoji: '✨', year: 2, moduleIndex: 14, partIndex: 0),
        CyberPart(id: 'y2_m14_p1_rainbow', emoji: '🌈', year: 2, moduleIndex: 14, partIndex: 1),
        CyberPart(id: 'y2_m14_p2_fire', emoji: '🔥', year: 2, moduleIndex: 14, partIndex: 2),
        CyberPart(id: 'y2_m14_p3_lightning', emoji: '⚡', year: 2, moduleIndex: 14, partIndex: 3),
        CyberPart(id: 'y2_m14_p4_cyclone', emoji: '🌀', year: 2, moduleIndex: 14, partIndex: 4),
        CyberPart(id: 'y2_m14_p5_star', emoji: '🌟', year: 2, moduleIndex: 14, partIndex: 5),
        CyberPart(id: 'y2_m14_p6_sun', emoji: '☀️', year: 2, moduleIndex: 14, partIndex: 6),
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // YEAR 3 (2028): 🗼 DATA SPIRE - 91 PARTS
  // Theme: "Bottom Up" - Neon cityscape with digital effects
  // ═══════════════════════════════════════════════════════════════════════════

  static const year3Config = YearConfig(
    year: 3,
    awardEmoji: '🗼',
    themeName: YearTheme.spire,
    progressFormat: ProgressFormat.floor,
    backgroundColors: YearColors.year3Background,
    accentColor: YearColors.year3Accent,
    modules: _year3Modules,
  );

  static const _year3Modules = [
    // Round 01: 地底光纖 Underground Fiber (6 parts)
    ModuleConfig(
      id: 'y3_underground_fiber',
      moduleIndex: 0,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m0_p0_screw', emoji: '🔩', year: 3, moduleIndex: 0, partIndex: 0),
        CyberPart(id: 'y3_m0_p1_chain', emoji: '⛓️', year: 3, moduleIndex: 0, partIndex: 1),
        CyberPart(id: 'y3_m0_p2_plug', emoji: '🔌', year: 3, moduleIndex: 0, partIndex: 2),
        CyberPart(id: 'y3_m0_p3_road', emoji: '🛣️', year: 3, moduleIndex: 0, partIndex: 3),
        CyberPart(id: 'y3_m0_p4_railway', emoji: '🛤️', year: 3, moduleIndex: 0, partIndex: 4),
        CyberPart(id: 'y3_m0_p5_metro', emoji: '🚇', year: 3, moduleIndex: 0, partIndex: 5),
      ],
    ),
    // Round 02: 巨型地基 Giant Foundation (6 parts)
    ModuleConfig(
      id: 'y3_giant_foundation',
      moduleIndex: 1,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m1_p0_brick', emoji: '🧱', year: 3, moduleIndex: 1, partIndex: 0),
        CyberPart(id: 'y3_m1_p1_brick2', emoji: '🧱', year: 3, moduleIndex: 1, partIndex: 1),
        CyberPart(id: 'y3_m1_p2_construction', emoji: '🏗️', year: 3, moduleIndex: 1, partIndex: 2),
        CyberPart(id: 'y3_m1_p3_barrier', emoji: '🚧', year: 3, moduleIndex: 1, partIndex: 3),
        CyberPart(id: 'y3_m1_p4_axe', emoji: '⚒️', year: 3, moduleIndex: 1, partIndex: 4),
        CyberPart(id: 'y3_m1_p5_pickaxe', emoji: '⛏️', year: 3, moduleIndex: 1, partIndex: 5),
      ],
    ),
    // Round 03: 能源室 1F Power Room (6 parts)
    ModuleConfig(
      id: 'y3_power_room',
      moduleIndex: 2,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m2_p0_battery', emoji: '🔋', year: 3, moduleIndex: 2, partIndex: 0),
        CyberPart(id: 'y3_m2_p1_lightning', emoji: '⚡', year: 3, moduleIndex: 2, partIndex: 1),
        CyberPart(id: 'y3_m2_p2_radioactive', emoji: '☢️', year: 3, moduleIndex: 2, partIndex: 2),
        CyberPart(id: 'y3_m2_p3_flashlight', emoji: '🔦', year: 3, moduleIndex: 2, partIndex: 3),
        CyberPart(id: 'y3_m2_p4_bulb', emoji: '💡', year: 3, moduleIndex: 2, partIndex: 4),
        CyberPart(id: 'y3_m2_p5_candle', emoji: '🕯️', year: 3, moduleIndex: 2, partIndex: 5),
      ],
    ),
    // Round 04: 冷卻池 Cooling Pool (6 parts)
    ModuleConfig(
      id: 'y3_cooling_pool',
      moduleIndex: 3,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m3_p0_flask', emoji: '🧪', year: 3, moduleIndex: 3, partIndex: 0),
        CyberPart(id: 'y3_m3_p1_droplet', emoji: '💧', year: 3, moduleIndex: 3, partIndex: 1),
        CyberPart(id: 'y3_m3_p2_wave', emoji: '🌊', year: 3, moduleIndex: 3, partIndex: 2),
        CyberPart(id: 'y3_m3_p3_snowflake', emoji: '❄️', year: 3, moduleIndex: 3, partIndex: 3),
        CyberPart(id: 'y3_m3_p4_fountain', emoji: '⛲', year: 3, moduleIndex: 3, partIndex: 4),
        CyberPart(id: 'y3_m3_p5_bathtub', emoji: '🛁', year: 3, moduleIndex: 3, partIndex: 5),
      ],
    ),
    // Round 05: 中央梯間 Central Stairs (6 parts)
    ModuleConfig(
      id: 'y3_central_stairs',
      moduleIndex: 4,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m4_p0_ladder', emoji: '🪜', year: 3, moduleIndex: 4, partIndex: 0),
        CyberPart(id: 'y3_m4_p1_elevator', emoji: '🛗', year: 3, moduleIndex: 4, partIndex: 1),
        CyberPart(id: 'y3_m4_p2_chain', emoji: '⛓️', year: 3, moduleIndex: 4, partIndex: 2),
        CyberPart(id: 'y3_m4_p3_tools', emoji: '🛠️', year: 3, moduleIndex: 4, partIndex: 3),
        CyberPart(id: 'y3_m4_p4_hook', emoji: '🪝', year: 3, moduleIndex: 4, partIndex: 4),
        CyberPart(id: 'y3_m4_p5_thread', emoji: '🧵', year: 3, moduleIndex: 4, partIndex: 5),
      ],
    ),
    // Round 06: 伺服器層 2F Server Floor (6 parts)
    ModuleConfig(
      id: 'y3_server_floor',
      moduleIndex: 5,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m5_p0_floppy', emoji: '💾', year: 3, moduleIndex: 5, partIndex: 0),
        CyberPart(id: 'y3_m5_p1_cd', emoji: '💿', year: 3, moduleIndex: 5, partIndex: 1),
        CyberPart(id: 'y3_m5_p2_dvd', emoji: '📀', year: 3, moduleIndex: 5, partIndex: 2),
        CyberPart(id: 'y3_m5_p3_laptop', emoji: '💻', year: 3, moduleIndex: 5, partIndex: 3),
        CyberPart(id: 'y3_m5_p4_keyboard', emoji: '⌨️', year: 3, moduleIndex: 5, partIndex: 4),
        CyberPart(id: 'y3_m5_p5_mouse', emoji: '🖱️', year: 3, moduleIndex: 5, partIndex: 5),
      ],
    ),
    // Round 07: 數據終端 3F Data Terminal (6 parts)
    ModuleConfig(
      id: 'y3_data_terminal',
      moduleIndex: 6,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m6_p0_mobile', emoji: '📱', year: 3, moduleIndex: 6, partIndex: 0),
        CyberPart(id: 'y3_m6_p1_pager', emoji: '📟', year: 3, moduleIndex: 6, partIndex: 1),
        CyberPart(id: 'y3_m6_p2_phone', emoji: '☎️', year: 3, moduleIndex: 6, partIndex: 2),
        CyberPart(id: 'y3_m6_p3_tv', emoji: '📺', year: 3, moduleIndex: 6, partIndex: 3),
        CyberPart(id: 'y3_m6_p4_radio', emoji: '📻', year: 3, moduleIndex: 6, partIndex: 4),
        CyberPart(id: 'y3_m6_p5_joystick', emoji: '🕹️', year: 3, moduleIndex: 6, partIndex: 5),
      ],
    ),
    // Round 08: 外部結構架 External Frame (6 parts)
    ModuleConfig(
      id: 'y3_external_frame',
      moduleIndex: 7,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m7_p0_construction', emoji: '🏗️', year: 3, moduleIndex: 7, partIndex: 0),
        CyberPart(id: 'y3_m7_p1_screw', emoji: '🔩', year: 3, moduleIndex: 7, partIndex: 1),
        CyberPart(id: 'y3_m7_p2_tools', emoji: '🛠️', year: 3, moduleIndex: 7, partIndex: 2),
        CyberPart(id: 'y3_m7_p3_triangle', emoji: '📐', year: 3, moduleIndex: 7, partIndex: 3),
        CyberPart(id: 'y3_m7_p4_ruler', emoji: '📏', year: 3, moduleIndex: 7, partIndex: 4),
        CyberPart(id: 'y3_m7_p5_hammer', emoji: '🔨', year: 3, moduleIndex: 7, partIndex: 5),
      ],
    ),
    // Round 09: 信號發射塔 Signal Tower (6 parts)
    ModuleConfig(
      id: 'y3_signal_tower',
      moduleIndex: 8,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m8_p0_dish', emoji: '📡', year: 3, moduleIndex: 8, partIndex: 0),
        CyberPart(id: 'y3_m8_p1_signal', emoji: '📶', year: 3, moduleIndex: 8, partIndex: 1),
        CyberPart(id: 'y3_m8_p2_signal2', emoji: '📶', year: 3, moduleIndex: 8, partIndex: 2),
        CyberPart(id: 'y3_m8_p3_radio', emoji: '📻', year: 3, moduleIndex: 8, partIndex: 3),
        CyberPart(id: 'y3_m8_p4_telescope', emoji: '🔭', year: 3, moduleIndex: 8, partIndex: 4),
        CyberPart(id: 'y3_m8_p5_megaphone', emoji: '📢', year: 3, moduleIndex: 8, partIndex: 5),
      ],
    ),
    // Round 10: 太陽能帷幕 Solar Curtain (6 parts)
    ModuleConfig(
      id: 'y3_solar_curtain',
      moduleIndex: 9,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m9_p0_bluesquare', emoji: '🟦', year: 3, moduleIndex: 9, partIndex: 0),
        CyberPart(id: 'y3_m9_p1_sun', emoji: '☀️', year: 3, moduleIndex: 9, partIndex: 1),
        CyberPart(id: 'y3_m9_p2_rainbow', emoji: '🌈', year: 3, moduleIndex: 9, partIndex: 2),
        CyberPart(id: 'y3_m9_p3_sparkles', emoji: '✨', year: 3, moduleIndex: 9, partIndex: 3),
        CyberPart(id: 'y3_m9_p4_fog', emoji: '🌫️', year: 3, moduleIndex: 9, partIndex: 4),
        CyberPart(id: 'y3_m9_p5_wind', emoji: '🌬️', year: 3, moduleIndex: 9, partIndex: 5),
      ],
    ),
    // Round 11: 無人機港口 Drone Port (6 parts)
    ModuleConfig(
      id: 'y3_drone_port',
      moduleIndex: 10,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m10_p0_ufo', emoji: '🛸', year: 3, moduleIndex: 10, partIndex: 0),
        CyberPart(id: 'y3_m10_p1_helicopter', emoji: '🚁', year: 3, moduleIndex: 10, partIndex: 1),
        CyberPart(id: 'y3_m10_p2_departure', emoji: '🛫', year: 3, moduleIndex: 10, partIndex: 2),
        CyberPart(id: 'y3_m10_p3_tools', emoji: '🛠️', year: 3, moduleIndex: 10, partIndex: 3),
        CyberPart(id: 'y3_m10_p4_anchor', emoji: '⚓', year: 3, moduleIndex: 10, partIndex: 4),
        CyberPart(id: 'y3_m10_p5_traffic_light', emoji: '🚦', year: 3, moduleIndex: 10, partIndex: 5),
      ],
    ),
    // Round 12: 量子處理室 Quantum Chamber (6 parts)
    ModuleConfig(
      id: 'y3_quantum_chamber',
      moduleIndex: 11,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m11_p0_brain', emoji: '🧠', year: 3, moduleIndex: 11, partIndex: 0),
        CyberPart(id: 'y3_m11_p1_diamond', emoji: '💎', year: 3, moduleIndex: 11, partIndex: 1),
        CyberPart(id: 'y3_m11_p2_crystal', emoji: '🔮', year: 3, moduleIndex: 11, partIndex: 2),
        CyberPart(id: 'y3_m11_p3_cyclone', emoji: '🌀', year: 3, moduleIndex: 11, partIndex: 3),
        CyberPart(id: 'y3_m11_p4_nazar', emoji: '🧿', year: 3, moduleIndex: 11, partIndex: 4),
        CyberPart(id: 'y3_m11_p5_dna', emoji: '🧬', year: 3, moduleIndex: 11, partIndex: 5),
      ],
    ),
    // Round 13: 防雷雷達 Lightning Radar (6 parts)
    ModuleConfig(
      id: 'y3_lightning_radar',
      moduleIndex: 12,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m12_p0_shield', emoji: '🛡️', year: 3, moduleIndex: 12, partIndex: 0),
        CyberPart(id: 'y3_m12_p1_lightning', emoji: '⚡', year: 3, moduleIndex: 12, partIndex: 1),
        CyberPart(id: 'y3_m12_p2_satellite', emoji: '🛰️', year: 3, moduleIndex: 12, partIndex: 2),
        CyberPart(id: 'y3_m12_p3_telescope', emoji: '🔭', year: 3, moduleIndex: 12, partIndex: 3),
        CyberPart(id: 'y3_m12_p4_flashlight', emoji: '🔦', year: 3, moduleIndex: 12, partIndex: 4),
        CyberPart(id: 'y3_m12_p5_battery', emoji: '🔋', year: 3, moduleIndex: 12, partIndex: 5),
      ],
    ),
    // Round 14: 霓虹尖塔 Neon Spire (6 parts)
    ModuleConfig(
      id: 'y3_neon_spire',
      moduleIndex: 13,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m13_p0_traffic', emoji: '🚥', year: 3, moduleIndex: 13, partIndex: 0),
        CyberPart(id: 'y3_m13_p1_firework', emoji: '🎆', year: 3, moduleIndex: 13, partIndex: 1),
        CyberPart(id: 'y3_m13_p2_shooting', emoji: '🌠', year: 3, moduleIndex: 13, partIndex: 2),
        CyberPart(id: 'y3_m13_p3_milkyway', emoji: '🌌', year: 3, moduleIndex: 13, partIndex: 3),
        CyberPart(id: 'y3_m13_p4_cityscape', emoji: '🌃', year: 3, moduleIndex: 13, partIndex: 4),
        CyberPart(id: 'y3_m13_p5_lantern', emoji: '🏮', year: 3, moduleIndex: 13, partIndex: 5),
      ],
    ),
    // Round 15: 數據通天 Data Ascension (7 parts)
    ModuleConfig(
      id: 'y3_data_ascension',
      moduleIndex: 14,
      year: 3,
      parts: [
        CyberPart(id: 'y3_m14_p0_sparkles', emoji: '✨', year: 3, moduleIndex: 14, partIndex: 0),
        CyberPart(id: 'y3_m14_p1_cyclone', emoji: '🌀', year: 3, moduleIndex: 14, partIndex: 1),
        CyberPart(id: 'y3_m14_p2_rainbow', emoji: '🌈', year: 3, moduleIndex: 14, partIndex: 2),
        CyberPart(id: 'y3_m14_p3_sun', emoji: '☀️', year: 3, moduleIndex: 14, partIndex: 3),
        CyberPart(id: 'y3_m14_p4_star', emoji: '🌟', year: 3, moduleIndex: 14, partIndex: 4),
        CyberPart(id: 'y3_m14_p5_planet', emoji: '🪐', year: 3, moduleIndex: 14, partIndex: 5),
        CyberPart(id: 'y3_m14_p6_milkyway', emoji: '🌌', year: 3, moduleIndex: 14, partIndex: 6),
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Find a part by its ID across all years.
  static CyberPart? findPartById(String partId) {
    for (final year in allYears) {
      for (final module in year.modules) {
        for (final part in module.parts) {
          if (part.id == partId) return part;
        }
      }
    }
    return null;
  }

  /// Get the original (non-reuse) part for a reuse part.
  static CyberPart? getOriginalPart(CyberPart reusePart) {
    if (!reusePart.isReuse || reusePart.reuseSourceId == null) return null;
    return findPartById(reusePart.reuseSourceId!);
  }

  /// Get total parts count across all years.
  static int get totalPartsAllYears =>
      year1Config.totalParts + year2Config.totalParts + year3Config.totalParts;
}

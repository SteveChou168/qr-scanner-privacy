// lib/data/info_type_options.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_text.dart';

/// 資訊類型 QR Code 選項（文本、網址、Email、電話、WiFi）
class InfoTypeOption {
  final String id;
  final String Function() nameGetter;
  final IconData icon;
  final Color color;

  const InfoTypeOption({
    required this.id,
    required this.nameGetter,
    required this.icon,
    required this.color,
  });

  String get name => nameGetter();
}

/// 取得資訊類型選項列表
List<InfoTypeOption> getInfoTypeOptions() => [
  InfoTypeOption(
    id: 'text',
    nameGetter: () => AppText.templateText,
    icon: FontAwesomeIcons.solidNoteSticky,
    color: const Color(0xFFFFB300), // 琥珀色 - 便利貼感
  ),
  InfoTypeOption(
    id: 'url',
    nameGetter: () => AppText.templateUrl,
    icon: FontAwesomeIcons.link,
    color: const Color(0xFF1E88E5), // 藍色 - 乾淨
  ),
  InfoTypeOption(
    id: 'email',
    nameGetter: () => AppText.templateEmail,
    icon: FontAwesomeIcons.solidPaperPlane,
    color: const Color(0xFF039BE5), // 天藍色 - 發送感
  ),
  InfoTypeOption(
    id: 'phone',
    nameGetter: () => AppText.templatePhone,
    icon: FontAwesomeIcons.phone,
    color: const Color(0xFF43A047), // 綠色 - 通話鍵
  ),
  InfoTypeOption(
    id: 'wifi',
    nameGetter: () => AppText.templateWifi,
    icon: FontAwesomeIcons.wifi,
    color: const Color(0xFF5E35B1), // 靛藍色 - 科技感
  ),
];

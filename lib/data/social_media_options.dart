// lib/data/social_media_options.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 社交媒體 QR Code 選項
class SocialMediaOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String prefix;
  final String hint;
  final String suffix;

  const SocialMediaOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.prefix,
    required this.hint,
    this.suffix = '',
  });

  /// 組合完整的 URL/內容
  String buildContent(String input) {
    if (input.isEmpty) return '';
    return '$prefix$input$suffix';
  }

  /// 取得簡短的 prefix 顯示文字（用於輸入框前綴）
  /// 例如：https://www.tiktok.com/@ → tiktok.com/@
  String get displayPrefix {
    var display = prefix;
    // 移除 protocol
    display = display.replaceFirst(RegExp(r'^https?://'), '');
    // 移除 www.
    display = display.replaceFirst(RegExp(r'^www\.'), '');
    return display;
  }
}

/// 根據語系取得社交媒體選項列表
List<SocialMediaOption> getSocialMediaOptions(String localeCode) {
  // 1. 先嘗試精確匹配
  if (_localizedSocialMedia.containsKey(localeCode)) {
    return _localizedSocialMedia[localeCode]!;
  }

  // 2. 中文特殊處理：所有中文都 fallback 到繁中
  if (localeCode.startsWith('zh')) {
    return _localizedSocialMedia['zh_TW']!;
  }

  // 3. 嘗試只用 languageCode 匹配（處理 'ja' -> 'ja_JP' 的情況）
  final langCode = localeCode.split('_').first;

  // 語言代碼對應表
  const langToLocale = {
    'ja': 'ja_JP',
    'ko': 'ko_KR',
    'es': 'es_ES',
    'pt': 'pt_BR',
    'vi': 'vi_VN',
    'en': 'en_US',
  };

  final mappedKey = langToLocale[langCode];
  if (mappedKey != null && _localizedSocialMedia.containsKey(mappedKey)) {
    return _localizedSocialMedia[mappedKey]!;
  }

  // 4. 最終 fallback 到英文
  return _localizedSocialMedia['en_US']!;
}

/// 從 Flutter Locale 取得 locale code
String getLocaleCode(Locale locale) {
  if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
    return '${locale.languageCode}_${locale.countryCode}';
  }
  return locale.languageCode;
}

/// 各語系的社交媒體選項
final Map<String, List<SocialMediaOption>> _localizedSocialMedia = {
  // ------------------------------------------------------
  // 1. 繁體中文 (台灣) - 10 個平台
  // 排序依據：使用率從高到低
  // ------------------------------------------------------
  'zh_TW': [
    SocialMediaOption(
      id: 'line',
      name: 'LINE',
      icon: FontAwesomeIcons.line,
      color: const Color(0xFF00C300),
      prefix: 'https://line.me/ti/p/~',
      hint: '你的 LINE ID',
    ),
    SocialMediaOption(
      id: 'facebook',
      name: 'Facebook',
      icon: FontAwesomeIcons.facebook,
      color: const Color(0xFF1877F2),
      prefix: 'https://www.facebook.com/',
      hint: 'facebook.com/your.name',
    ),
    SocialMediaOption(
      id: 'instagram',
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      color: const Color(0xFFE4405F),
      prefix: 'https://www.instagram.com/',
      hint: 'instagram.com/your_name',
    ),
    SocialMediaOption(
      id: 'youtube',
      name: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      color: const Color(0xFFFF0000),
      prefix: 'https://www.youtube.com/@',
      hint: 'youtube.com/@channel',
    ),
    SocialMediaOption(
      id: 'tiktok',
      name: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      color: Colors.black,
      prefix: 'https://www.tiktok.com/@',
      hint: 'tiktok.com/@name',
    ),
    SocialMediaOption(
      id: 'threads',
      name: 'Threads',
      icon: FontAwesomeIcons.threads,
      color: Colors.black,
      prefix: 'https://www.threads.net/@',
      hint: 'threads.net/@name',
    ),
    SocialMediaOption(
      id: 'dcard',
      name: 'Dcard',
      icon: FontAwesomeIcons.graduationCap,
      color: const Color(0xFF006AA6),
      prefix: 'https://www.dcard.tw/@',
      hint: 'dcard.tw/@卡稱',
    ),
    SocialMediaOption(
      id: 'telegram',
      name: 'Telegram',
      icon: FontAwesomeIcons.telegram,
      color: const Color(0xFF0088CC),
      prefix: 'https://t.me/',
      hint: 't.me/username',
    ),
    SocialMediaOption(
      id: 'twitter',
      name: 'X (Twitter)',
      icon: FontAwesomeIcons.xTwitter,
      color: Colors.black,
      prefix: 'https://x.com/',
      hint: 'x.com/username',
    ),
    SocialMediaOption(
      id: 'linkedin',
      name: 'LinkedIn',
      icon: FontAwesomeIcons.linkedin,
      color: const Color(0xFF0A66C2),
      prefix: 'https://www.linkedin.com/in/',
      hint: 'in/your-name',
    ),
  ],

  // ------------------------------------------------------
  // 2. 日文 (日本) - 10 個平台
  // 排序依據：使用率從高到低
  // ------------------------------------------------------
  'ja_JP': [
    SocialMediaOption(
      id: 'line',
      name: 'LINE',
      icon: FontAwesomeIcons.line,
      color: const Color(0xFF00C300),
      prefix: 'https://line.me/ti/p/~',
      hint: 'あなたの LINE ID',
    ),
    SocialMediaOption(
      id: 'twitter',
      name: 'X (Twitter)',
      icon: FontAwesomeIcons.xTwitter,
      color: Colors.black,
      prefix: 'https://x.com/',
      hint: 'x.com/username',
    ),
    SocialMediaOption(
      id: 'instagram',
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      color: const Color(0xFFE4405F),
      prefix: 'https://www.instagram.com/',
      hint: 'instagram.com/name',
    ),
    SocialMediaOption(
      id: 'youtube',
      name: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      color: const Color(0xFFFF0000),
      prefix: 'https://www.youtube.com/@',
      hint: 'youtube.com/@channel',
    ),
    SocialMediaOption(
      id: 'tiktok',
      name: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      color: Colors.black,
      prefix: 'https://www.tiktok.com/@',
      hint: 'tiktok.com/@name',
    ),
    SocialMediaOption(
      id: 'threads',
      name: 'Threads',
      icon: FontAwesomeIcons.threads,
      color: Colors.black,
      prefix: 'https://www.threads.net/@',
      hint: 'threads.net/@name',
    ),
    SocialMediaOption(
      id: 'facebook',
      name: 'Facebook',
      icon: FontAwesomeIcons.facebook,
      color: const Color(0xFF1877F2),
      prefix: 'https://www.facebook.com/',
      hint: 'facebook.com/name',
    ),
    SocialMediaOption(
      id: 'ameba',
      name: 'Ameba',
      icon: FontAwesomeIcons.penNib,
      color: const Color(0xFF2D8C3C),
      prefix: 'https://ameblo.jp/',
      hint: 'ameblo.jp/name',
    ),
    SocialMediaOption(
      id: 'pinterest',
      name: 'Pinterest',
      icon: FontAwesomeIcons.pinterest,
      color: const Color(0xFFE60023),
      prefix: 'https://www.pinterest.com/',
      hint: 'pinterest.com/name',
    ),
    SocialMediaOption(
      id: 'linkedin',
      name: 'LinkedIn',
      icon: FontAwesomeIcons.linkedin,
      color: const Color(0xFF0A66C2),
      prefix: 'https://www.linkedin.com/in/',
      hint: 'in/your-name',
    ),
  ],

  // ------------------------------------------------------
  // 3. 韓文 (韓國) - 12 個平台
  // 排序依據：使用率從高到低
  // ------------------------------------------------------
  'ko_KR': [
    SocialMediaOption(
      id: 'kakao',
      name: 'Kakao',
      icon: FontAwesomeIcons.comment,
      color: const Color(0xFFFEE500),
      prefix: 'https://open.kakao.com/o/',
      hint: 'open.kakao.com/o/code',
    ),
    SocialMediaOption(
      id: 'youtube',
      name: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      color: const Color(0xFFFF0000),
      prefix: 'https://www.youtube.com/@',
      hint: 'youtube.com/@channel',
    ),
    SocialMediaOption(
      id: 'instagram',
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      color: const Color(0xFFE4405F),
      prefix: 'https://www.instagram.com/',
      hint: 'instagram.com/name',
    ),
    SocialMediaOption(
      id: 'naver_blog',
      name: 'Naver Blog',
      icon: FontAwesomeIcons.newspaper,
      color: const Color(0xFF03C75A),
      prefix: 'https://blog.naver.com/',
      hint: 'blog.naver.com/id',
    ),
    SocialMediaOption(
      id: 'naver_cafe',
      name: 'Naver Cafe',
      icon: FontAwesomeIcons.mugSaucer,
      color: const Color(0xFF03C75A),
      prefix: 'https://cafe.naver.com/',
      hint: 'cafe.naver.com/name',
    ),
    SocialMediaOption(
      id: 'band',
      name: 'Band',
      icon: FontAwesomeIcons.users,
      color: const Color(0xFF42C86A),
      prefix: 'https://band.us/n/',
      hint: 'band.us/n/code',
    ),
    SocialMediaOption(
      id: 'threads',
      name: 'Threads',
      icon: FontAwesomeIcons.threads,
      color: Colors.black,
      prefix: 'https://www.threads.net/@',
      hint: 'threads.net/@name',
    ),
    SocialMediaOption(
      id: 'facebook',
      name: 'Facebook',
      icon: FontAwesomeIcons.facebook,
      color: const Color(0xFF1877F2),
      prefix: 'https://www.facebook.com/',
      hint: 'facebook.com/name',
    ),
    SocialMediaOption(
      id: 'tiktok',
      name: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      color: Colors.black,
      prefix: 'https://www.tiktok.com/@',
      hint: 'tiktok.com/@name',
    ),
    SocialMediaOption(
      id: 'twitter',
      name: 'X (Twitter)',
      icon: FontAwesomeIcons.xTwitter,
      color: Colors.black,
      prefix: 'https://x.com/',
      hint: 'x.com/username',
    ),
    SocialMediaOption(
      id: 'linkedin',
      name: 'LinkedIn',
      icon: FontAwesomeIcons.linkedin,
      color: const Color(0xFF0A66C2),
      prefix: 'https://www.linkedin.com/in/',
      hint: 'in/your-name',
    ),
    SocialMediaOption(
      id: 'pinterest',
      name: 'Pinterest',
      icon: FontAwesomeIcons.pinterest,
      color: const Color(0xFFE60023),
      prefix: 'https://www.pinterest.com/',
      hint: 'pinterest.com/name',
    ),
  ],

  // ------------------------------------------------------
  // 4. 英文 (美國/全球) - 12 個平台
  // 排序依據：使用率從高到低
  // ------------------------------------------------------
  'en_US': [
    SocialMediaOption(
      id: 'youtube',
      name: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      color: const Color(0xFFFF0000),
      prefix: 'https://www.youtube.com/@',
      hint: 'youtube.com/@channel',
    ),
    SocialMediaOption(
      id: 'facebook',
      name: 'Facebook',
      icon: FontAwesomeIcons.facebook,
      color: const Color(0xFF1877F2),
      prefix: 'https://www.facebook.com/',
      hint: 'facebook.com/name',
    ),
    SocialMediaOption(
      id: 'instagram',
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      color: const Color(0xFFE4405F),
      prefix: 'https://www.instagram.com/',
      hint: 'instagram.com/name',
    ),
    SocialMediaOption(
      id: 'tiktok',
      name: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      color: Colors.black,
      prefix: 'https://www.tiktok.com/@',
      hint: 'tiktok.com/@name',
    ),
    SocialMediaOption(
      id: 'snapchat',
      name: 'Snapchat',
      icon: FontAwesomeIcons.snapchat,
      color: const Color(0xFFFFFC00),
      prefix: 'https://www.snapchat.com/add/',
      hint: 'snapchat.com/add/name',
    ),
    SocialMediaOption(
      id: 'twitch',
      name: 'Twitch',
      icon: FontAwesomeIcons.twitch,
      color: const Color(0xFF9146FF),
      prefix: 'https://www.twitch.tv/',
      hint: 'twitch.tv/channel',
    ),
    SocialMediaOption(
      id: 'reddit',
      name: 'Reddit',
      icon: FontAwesomeIcons.reddit,
      color: const Color(0xFFFF4500),
      prefix: 'https://www.reddit.com/user/',
      hint: 'reddit.com/user/name',
    ),
    SocialMediaOption(
      id: 'whatsapp',
      name: 'WhatsApp',
      icon: FontAwesomeIcons.whatsapp,
      color: const Color(0xFF25D366),
      prefix: 'https://wa.me/',
      hint: 'e.g. 14155551234',
    ),
    SocialMediaOption(
      id: 'twitter',
      name: 'X (Twitter)',
      icon: FontAwesomeIcons.xTwitter,
      color: Colors.black,
      prefix: 'https://x.com/',
      hint: 'x.com/username',
    ),
    SocialMediaOption(
      id: 'discord',
      name: 'Discord',
      icon: FontAwesomeIcons.discord,
      color: const Color(0xFF5865F2),
      prefix: 'https://discord.gg/',
      hint: 'discord.gg/code',
    ),
    SocialMediaOption(
      id: 'pinterest',
      name: 'Pinterest',
      icon: FontAwesomeIcons.pinterest,
      color: const Color(0xFFE60023),
      prefix: 'https://www.pinterest.com/',
      hint: 'pinterest.com/name',
    ),
    SocialMediaOption(
      id: 'linkedin',
      name: 'LinkedIn',
      icon: FontAwesomeIcons.linkedin,
      color: const Color(0xFF0A66C2),
      prefix: 'https://www.linkedin.com/in/',
      hint: 'in/your-name',
    ),
  ],

  // ------------------------------------------------------
  // 5. 西班牙文 (西/拉美) - 12 個平台
  // 排序依據：使用率從高到低
  // ------------------------------------------------------
  'es_ES': [
    SocialMediaOption(
      id: 'whatsapp',
      name: 'WhatsApp',
      icon: FontAwesomeIcons.whatsapp,
      color: const Color(0xFF25D366),
      prefix: 'https://wa.me/',
      hint: 'ej. 34612345678',
    ),
    SocialMediaOption(
      id: 'instagram',
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      color: const Color(0xFFE4405F),
      prefix: 'https://www.instagram.com/',
      hint: 'instagram.com/nombre',
    ),
    SocialMediaOption(
      id: 'facebook',
      name: 'Facebook',
      icon: FontAwesomeIcons.facebook,
      color: const Color(0xFF1877F2),
      prefix: 'https://www.facebook.com/',
      hint: 'facebook.com/nombre',
    ),
    SocialMediaOption(
      id: 'tiktok',
      name: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      color: Colors.black,
      prefix: 'https://www.tiktok.com/@',
      hint: 'tiktok.com/@nombre',
    ),
    SocialMediaOption(
      id: 'youtube',
      name: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      color: const Color(0xFFFF0000),
      prefix: 'https://www.youtube.com/@',
      hint: 'youtube.com/@canal',
    ),
    SocialMediaOption(
      id: 'threads',
      name: 'Threads',
      icon: FontAwesomeIcons.threads,
      color: Colors.black,
      prefix: 'https://www.threads.net/@',
      hint: 'threads.net/@nombre',
    ),
    SocialMediaOption(
      id: 'twitch',
      name: 'Twitch',
      icon: FontAwesomeIcons.twitch,
      color: const Color(0xFF9146FF),
      prefix: 'https://www.twitch.tv/',
      hint: 'twitch.tv/canal',
    ),
    SocialMediaOption(
      id: 'telegram',
      name: 'Telegram',
      icon: FontAwesomeIcons.telegram,
      color: const Color(0xFF0088CC),
      prefix: 'https://t.me/',
      hint: 't.me/usuario',
    ),
    SocialMediaOption(
      id: 'discord',
      name: 'Discord',
      icon: FontAwesomeIcons.discord,
      color: const Color(0xFF5865F2),
      prefix: 'https://discord.gg/',
      hint: 'discord.gg/código',
    ),
    SocialMediaOption(
      id: 'twitter',
      name: 'X (Twitter)',
      icon: FontAwesomeIcons.xTwitter,
      color: Colors.black,
      prefix: 'https://x.com/',
      hint: 'x.com/usuario',
    ),
    SocialMediaOption(
      id: 'pinterest',
      name: 'Pinterest',
      icon: FontAwesomeIcons.pinterest,
      color: const Color(0xFFE60023),
      prefix: 'https://www.pinterest.com/',
      hint: 'pinterest.com/nombre',
    ),
    SocialMediaOption(
      id: 'linkedin',
      name: 'LinkedIn',
      icon: FontAwesomeIcons.linkedin,
      color: const Color(0xFF0A66C2),
      prefix: 'https://www.linkedin.com/in/',
      hint: 'in/tu-nombre',
    ),
  ],

  // ------------------------------------------------------
  // 6. 葡萄牙文 (巴西) - 13 個平台
  // 排序依據：使用率從高到低
  // ------------------------------------------------------
  'pt_BR': [
    SocialMediaOption(
      id: 'whatsapp',
      name: 'WhatsApp',
      icon: FontAwesomeIcons.whatsapp,
      color: const Color(0xFF25D366),
      prefix: 'https://wa.me/',
      hint: 'ex. 5511912345678',
    ),
    SocialMediaOption(
      id: 'instagram',
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      color: const Color(0xFFE4405F),
      prefix: 'https://www.instagram.com/',
      hint: 'instagram.com/nome',
    ),
    SocialMediaOption(
      id: 'facebook',
      name: 'Facebook',
      icon: FontAwesomeIcons.facebook,
      color: const Color(0xFF1877F2),
      prefix: 'https://www.facebook.com/',
      hint: 'facebook.com/nome',
    ),
    SocialMediaOption(
      id: 'tiktok',
      name: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      color: Colors.black,
      prefix: 'https://www.tiktok.com/@',
      hint: 'tiktok.com/@nome',
    ),
    SocialMediaOption(
      id: 'youtube',
      name: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      color: const Color(0xFFFF0000),
      prefix: 'https://www.youtube.com/@',
      hint: 'youtube.com/@canal',
    ),
    SocialMediaOption(
      id: 'threads',
      name: 'Threads',
      icon: FontAwesomeIcons.threads,
      color: Colors.black,
      prefix: 'https://www.threads.net/@',
      hint: 'threads.net/@nome',
    ),
    SocialMediaOption(
      id: 'kwai',
      name: 'Kwai',
      icon: FontAwesomeIcons.video,
      color: const Color(0xFFFF8F1C),
      prefix: 'https://www.kwai.com/@',
      hint: 'kwai.com/@nome',
    ),
    SocialMediaOption(
      id: 'twitch',
      name: 'Twitch',
      icon: FontAwesomeIcons.twitch,
      color: const Color(0xFF9146FF),
      prefix: 'https://www.twitch.tv/',
      hint: 'twitch.tv/canal',
    ),
    SocialMediaOption(
      id: 'telegram',
      name: 'Telegram',
      icon: FontAwesomeIcons.telegram,
      color: const Color(0xFF0088CC),
      prefix: 'https://t.me/',
      hint: 't.me/usuario',
    ),
    SocialMediaOption(
      id: 'discord',
      name: 'Discord',
      icon: FontAwesomeIcons.discord,
      color: const Color(0xFF5865F2),
      prefix: 'https://discord.gg/',
      hint: 'discord.gg/código',
    ),
    SocialMediaOption(
      id: 'twitter',
      name: 'X (Twitter)',
      icon: FontAwesomeIcons.xTwitter,
      color: Colors.black,
      prefix: 'https://x.com/',
      hint: 'x.com/usuario',
    ),
    SocialMediaOption(
      id: 'pinterest',
      name: 'Pinterest',
      icon: FontAwesomeIcons.pinterest,
      color: const Color(0xFFE60023),
      prefix: 'https://www.pinterest.com/',
      hint: 'pinterest.com/nome',
    ),
    SocialMediaOption(
      id: 'linkedin',
      name: 'LinkedIn',
      icon: FontAwesomeIcons.linkedin,
      color: const Color(0xFF0A66C2),
      prefix: 'https://www.linkedin.com/in/',
      hint: 'in/seu-nome',
    ),
  ],

  // ------------------------------------------------------
  // 7. 越南文 (越南) - 11 個平台
  // 排序依據：使用率從高到低
  // ------------------------------------------------------
  'vi_VN': [
    SocialMediaOption(
      id: 'zalo',
      name: 'Zalo',
      icon: FontAwesomeIcons.commentDots,
      color: const Color(0xFF0068FF),
      prefix: 'https://zalo.me/',
      hint: 'vd. 84912345678',
    ),
    SocialMediaOption(
      id: 'facebook',
      name: 'Facebook',
      icon: FontAwesomeIcons.facebook,
      color: const Color(0xFF1877F2),
      prefix: 'https://www.facebook.com/',
      hint: 'facebook.com/ten',
    ),
    SocialMediaOption(
      id: 'messenger',
      name: 'Messenger',
      icon: FontAwesomeIcons.facebookMessenger,
      color: const Color(0xFF00B2FF),
      prefix: 'https://m.me/',
      hint: 'm.me/ten',
    ),
    SocialMediaOption(
      id: 'youtube',
      name: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      color: const Color(0xFFFF0000),
      prefix: 'https://www.youtube.com/@',
      hint: 'youtube.com/@kenh',
    ),
    SocialMediaOption(
      id: 'tiktok',
      name: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      color: Colors.black,
      prefix: 'https://www.tiktok.com/@',
      hint: 'tiktok.com/@ten',
    ),
    SocialMediaOption(
      id: 'threads',
      name: 'Threads',
      icon: FontAwesomeIcons.threads,
      color: Colors.black,
      prefix: 'https://www.threads.net/@',
      hint: 'threads.net/@ten',
    ),
    SocialMediaOption(
      id: 'instagram',
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      color: const Color(0xFFE4405F),
      prefix: 'https://www.instagram.com/',
      hint: 'instagram.com/ten',
    ),
    SocialMediaOption(
      id: 'telegram',
      name: 'Telegram',
      icon: FontAwesomeIcons.telegram,
      color: const Color(0xFF0088CC),
      prefix: 'https://t.me/',
      hint: 't.me/username',
    ),
    SocialMediaOption(
      id: 'viber',
      name: 'Viber',
      icon: FontAwesomeIcons.viber,
      color: const Color(0xFF7360F2),
      prefix: 'https://viber.click/',
      hint: 'vd. 84912345678',
    ),
    SocialMediaOption(
      id: 'twitter',
      name: 'X (Twitter)',
      icon: FontAwesomeIcons.xTwitter,
      color: Colors.black,
      prefix: 'https://x.com/',
      hint: 'x.com/username',
    ),
    SocialMediaOption(
      id: 'linkedin',
      name: 'LinkedIn',
      icon: FontAwesomeIcons.linkedin,
      color: const Color(0xFF0A66C2),
      prefix: 'https://www.linkedin.com/in/',
      hint: 'in/ten-cua-ban',
    ),
  ],
};

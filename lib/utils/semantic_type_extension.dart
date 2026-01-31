// lib/utils/semantic_type_extension.dart

import 'package:flutter/material.dart';
import '../app_text.dart';
import '../data/models/scan_record.dart';

/// Extension for SemanticType with UI properties
extension SemanticTypeUI on SemanticType {
  /// Get the display color for this type
  Color get color {
    return switch (this) {
      SemanticType.url => Colors.blue,
      SemanticType.email => Colors.orange,
      SemanticType.wifi => Colors.purple,
      SemanticType.isbn => Colors.amber,
      SemanticType.vcard => Colors.teal,
      SemanticType.sms => Colors.pink,
      SemanticType.geo => Colors.indigo,
      SemanticType.text => Colors.grey,
    };
  }

  /// Get the localized label for this type
  String get typeLabel {
    return switch (this) {
      SemanticType.url => AppText.typeUrl,
      SemanticType.email => AppText.typeEmail,
      SemanticType.wifi => AppText.typeWifi,
      SemanticType.isbn => AppText.typeIsbn,
      SemanticType.vcard => AppText.typeVcard,
      SemanticType.sms => AppText.typeSms,
      SemanticType.geo => AppText.typeGeo,
      SemanticType.text => AppText.typeText,
    };
  }

  /// Get the action icon for this type
  IconData get actionIcon {
    return switch (this) {
      SemanticType.url => Icons.open_in_new,
      SemanticType.email => Icons.email_outlined,
      SemanticType.wifi => Icons.wifi,
      SemanticType.isbn => Icons.search,
      SemanticType.vcard => Icons.person_add_outlined,
      SemanticType.sms => Icons.message_outlined,
      SemanticType.geo => Icons.location_on_outlined,
      SemanticType.text => Icons.search,
    };
  }

  /// Get the action label for this type
  String get actionLabel {
    return switch (this) {
      SemanticType.url => AppText.actionOpen,
      SemanticType.email => AppText.actionEmail,
      SemanticType.wifi => AppText.actionConnect,
      SemanticType.isbn => AppText.actionSearch,
      SemanticType.vcard => AppText.actionSave,
      SemanticType.sms => AppText.actionSms,
      SemanticType.geo => AppText.actionOpen,
      SemanticType.text => AppText.actionSearch,
    };
  }
}

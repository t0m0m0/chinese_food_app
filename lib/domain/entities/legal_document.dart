enum LegalDocumentType {
  privacyPolicy,
  termsOfService,
  apiAttribution;

  String get displayName {
    switch (this) {
      case LegalDocumentType.privacyPolicy:
        return 'プライバシーポリシー';
      case LegalDocumentType.termsOfService:
        return '利用規約';
      case LegalDocumentType.apiAttribution:
        return 'API利用規約';
    }
  }
}

class LegalDocument {
  final String id;
  final LegalDocumentType type;
  final String title;
  final String content;
  final String version;
  final DateTime effectiveDate;
  final DateTime lastUpdated;

  LegalDocument({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.version,
    required this.effectiveDate,
    required this.lastUpdated,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }
    if (title.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
  }

  bool get isEffective {
    return DateTime.now().isAfter(effectiveDate) ||
        DateTime.now().isAtSameMomentAs(effectiveDate);
  }
}

/// How a Tajweed rule is used.
enum TajweedRuleKind {
  /// Knowledge examined in theory questions. It is not a rule performed in a
  /// segment, so it never counts toward `ruleDensity`.
  theoretical('theoretical'),

  /// A rule performed in recitation.
  recitation('recitation'),

  /// A recitation rule particular to the narration of Hafs 'an Asim.
  hafsSpecific('hafs_specific');

  const TajweedRuleKind(this.value);

  /// The value stored in the `kind` field of the `tajweed_rules` document.
  final String value;

  /// Returns null when [value] is not a known kind.
  static TajweedRuleKind? fromValue(Object? value) {
    for (final kind in values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}

/// The chapter a Tajweed rule belongs to.
enum TajweedCategory {
  intro('intro', 'مقدمات'),
  makharij('makharij', 'مخارج الحروف'),
  sifat('sifat', 'صفات الحروف'),
  nun('nun_sakinah', 'النون الساكنة والتنوين'),
  mim('mim_sakinah', 'الميم الساكنة'),
  ghunnah('ghunnah', 'الغنة'),
  idgham('idgham', 'الإدغام'),
  lamat('lamat', 'اللامات'),
  tafkhim('tafkhim_tarqiq', 'التفخيم والترقيق'),
  qalqalah('qalqalah', 'القلقلة'),
  madd('madd', 'المدود'),
  hamz('hamz', 'همزة الوصل والقطع'),
  haKinayah('ha_kinayah', 'هاء الكناية'),
  waqfAwakhir('waqf_awakhir', 'الوقف على أواخر الكلم'),
  waqfIbtida('waqf_ibtida', 'الوقف والابتداء'),
  sakt('sakt', 'السكت'),
  iltiqaSakinayn('iltiqa_sakinayn', 'التقاء الساكنين'),
  rasm('rasm', 'الرسم والضبط'),
  hafs('hafs', 'ما يراعى لحفص');

  const TajweedCategory(this.value, this.label);

  /// The value stored in the `category` field of the `tajweed_rules` document.
  final String value;

  final String label;

  /// Returns null when [value] is not a known category.
  static TajweedCategory? fromValue(Object? value) {
    for (final category in values) {
      if (category.value == value) return category;
    }
    return null;
  }
}

/// A Tajweed rule from the `tajweed_rules` collection.
class TajweedRule {
  const TajweedRule({
    required this.id,
    required this.name,
    this.description = '',
    this.category,
    this.kind = TajweedRuleKind.recitation,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;

  /// Null when the document has no known category.
  final TajweedCategory? category;

  final TajweedRuleKind kind;
  final bool isActive;

  /// Whether the rule is performed in recitation, and so may be linked to
  /// segments and recorded as a recitation error.
  bool get isRecitation => kind != TajweedRuleKind.theoretical;

  /// Returns null when the rule has no name.
  ///
  /// A document written before `kind` and `isActive` existed is read as an
  /// active recitation rule.
  static TajweedRule? fromMap(String id, Map<String, dynamic> data) {
    final name = data['name'];
    if (name is! String || name.isEmpty) return null;
    final description = data['description'];
    return TajweedRule(
      id: id,
      name: name,
      description: description is String ? description : '',
      category: TajweedCategory.fromValue(data['category']),
      kind:
          TajweedRuleKind.fromValue(data['kind']) ?? TajweedRuleKind.recitation,
      isActive: data['isActive'] != false,
    );
  }
}

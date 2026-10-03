/// A Tajweed rule from the `tajweed_rules` collection.
class TajweedRule {
  const TajweedRule({required this.id, required this.name});

  final String id;
  final String name;

  /// Returns null when the rule has no name.
  static TajweedRule? fromMap(String id, Map<String, dynamic> data) {
    final name = data['name'];
    if (name is! String || name.isEmpty) return null;
    return TajweedRule(id: id, name: name);
  }
}

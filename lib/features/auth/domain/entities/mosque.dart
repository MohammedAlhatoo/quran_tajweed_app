/// A mosque from the `mosques` collection, as needed for registration.
class Mosque {
  const Mosque({
    required this.id,
    required this.name,
    required this.squareId,
    required this.regionId,
  });

  final String id;
  final String name;
  final String squareId;
  final String regionId;

  /// Returns null when the document is missing its square or region.
  static Mosque? fromMap(String id, Map<String, dynamic> data) {
    final squareId = data['squareId'];
    final regionId = data['regionId'];
    if (squareId is! String || squareId.isEmpty) return null;
    if (regionId is! String || regionId.isEmpty) return null;
    return Mosque(
      id: id,
      name: data['name'] as String? ?? '',
      squareId: squareId,
      regionId: regionId,
    );
  }
}

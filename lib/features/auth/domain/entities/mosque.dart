/// A mosque from the `mosques` collection.
class Mosque {
  const Mosque({
    required this.id,
    required this.name,
    required this.squareId,
    required this.regionId,
    this.address = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String squareId;
  final String regionId;
  final String address;

  /// Only active mosques can be chosen during registration.
  final bool isActive;

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
      address: data['address'] as String? ?? '',
      isActive: data['isActive'] == true,
    );
  }
}

class HospitalPlace {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const HospitalPlace({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory HospitalPlace.fromPlacesJson(Map<String, dynamic> json) {
    final displayName = json['displayName'];
    final location = json['location'];

    return HospitalPlace(
      name: (displayName is Map ? displayName['text'] : null)?.toString() ??
          '이름 없는 병원',
      address: (json['formattedAddress'] ?? '').toString(),
      latitude: (location?['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (location?['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

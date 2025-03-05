class Memory {
  final String id;
  final List<String> photoUrl; // Fotoğraf URL'si
  final double latitude;
  final double longitude;
  final String name;

  Memory({
    required this.id,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.name,
  });
  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'],
      photoUrl: List<String>.from(json['photoUrl'] ?? []),
      latitude: json['latitude'],
      longitude: json['longitude'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'name':name,
    };
  }
}

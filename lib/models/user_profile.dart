class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final double? weight; // kg
  final double? height; // cm
  final double? waist; // bel (cm)
  final double? belly; // göbek (cm)
  final double? arm; // kol (cm)
  final double? leg; // bacak (cm)

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.weight,
    this.height,
    this.waist,
    this.belly,
    this.arm,
    this.leg,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'display_name': displayName,
      'weight': weight,
      'height': height,
      'waist': waist,
      'belly': belly,
      'arm': arm,
      'leg': leg,
    };
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['display_name'],
      weight: _toDouble(map['weight']),
      height: _toDouble(map['height']),
      waist: _toDouble(map['waist']),
      belly: _toDouble(map['belly']),
      arm: _toDouble(map['arm']),
      leg: _toDouble(map['leg']),
    );
  }
}


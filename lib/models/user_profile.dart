class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final double? weight; // kg
  final double? height; // cm

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.weight,
    this.height,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'display_name': displayName,
      'weight': weight,
      'height': height,
    };
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['display_name'],
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
    );
  }
}


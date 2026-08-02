class AppUser {
  final int id;
  final String name;
  final String email;
  final String district;
  final String role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.district,
    required this.role,
  });

  bool get isPresident => role.toLowerCase() == 'president';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'district': district,
        'role': role,
      };

  AppUser copyWith({String? name, String? district, String? role}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      district: district ?? this.district,
      role: role ?? this.role,
    );
  }
}

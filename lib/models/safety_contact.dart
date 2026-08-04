class SafetyContact {
  final int id;
  final String name;
  final String? relationship;
  final String phone;
  final String? email;
  final String? address;

  const SafetyContact({
    required this.id,
    required this.name,
    this.relationship,
    required this.phone,
    this.email,
    this.address,
  });

  factory SafetyContact.fromJson(Map<String, dynamic> json) {
    return SafetyContact(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      relationship: json['relationship']?.toString(),
      phone: (json['phone'] ?? '').toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toRequestJson() => {
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'email': email,
        'address': address,
      };
}
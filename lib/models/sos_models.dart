class SosAlert {
  final int id;
  final int userId;
  final double latitude;
  final double longitude;
  final String status; // active | resolved
  final String? message;
  final String createdTime;
  final String? resolvedTime;

  const SosAlert({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.message,
    required this.createdTime,
    this.resolvedTime,
  });

  bool get isActive => status == 'active';

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    return SosAlert(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse('${json['user_id']}') ?? 0,
      latitude: n(json['latitude']),
      longitude: n(json['longitude']),
      status: (json['status'] ?? 'active').toString(),
      message: json['message']?.toString(),
      createdTime: (json['created_time'] ?? '').toString(),
      resolvedTime: json['resolved_time']?.toString(),
    );
  }
}
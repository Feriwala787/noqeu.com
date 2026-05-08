class Appointment {
  final String id;
  final String shopId;
  final int tokenNumber;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String status;
  final bool isWalkIn;
  final Map<String, dynamic>? shopInfo;
  final Map<String, dynamic>? userInfo;

  const Appointment({
    required this.id,
    required this.shopId,
    required this.tokenNumber,
    required this.slotStart,
    required this.slotEnd,
    required this.status,
    this.isWalkIn = false,
    this.shopInfo,
    this.userInfo,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final shopId = json['shopId'];
    return Appointment(
      id: (json['_id'] ?? json['id']) as String,
      shopId: shopId is Map ? shopId['_id'] as String : shopId as String,
      tokenNumber: json['tokenNumber'] as int? ?? 0,
      slotStart: DateTime.parse(json['slotStart'] as String),
      slotEnd: DateTime.parse(json['slotEnd'] as String),
      status: json['status'] as String,
      isWalkIn: json['isWalkIn'] as bool? ?? false,
      shopInfo: shopId is Map ? shopId as Map<String, dynamic> : null,
      userInfo: json['userId'] is Map ? json['userId'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'shopId': shopId,
        'tokenNumber': tokenNumber,
        'slotStart': slotStart.toIso8601String(),
        'slotEnd': slotEnd.toIso8601String(),
        'status': status,
        'isWalkIn': isWalkIn,
      };
}

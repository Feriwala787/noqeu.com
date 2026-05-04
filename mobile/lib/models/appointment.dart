class Appointment {
  final String id;
  final String shopId;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String status;

  const Appointment({
    required this.id,
    required this.shopId,
    required this.slotStart,
    required this.slotEnd,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'] as String,
      shopId: json['shopId'] as String,
      slotStart: DateTime.parse(json['slotStart'] as String),
      slotEnd: DateTime.parse(json['slotEnd'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'shopId': shopId,
      'slotStart': slotStart.toIso8601String(),
      'slotEnd': slotEnd.toIso8601String(),
      'status': status,
    };
  }
}

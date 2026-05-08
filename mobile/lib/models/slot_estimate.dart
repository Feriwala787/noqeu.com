class SlotEstimate {
  final DateTime expectedStart;
  final DateTime expectedEnd;
  final int waitTimeMinutes;
  final bool acceptingOnline;
  final String? message;
  final int peopleAhead;
  final int seatsInService;
  final DateTime calculatedAt;

  SlotEstimate({
    required this.expectedStart,
    required this.expectedEnd,
    required this.waitTimeMinutes,
    required this.acceptingOnline,
    this.message,
    this.peopleAhead = 0,
    this.seatsInService = 1,
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  factory SlotEstimate.fromJson(Map<String, dynamic> json) {
    return SlotEstimate(
      expectedStart: DateTime.parse(json['expectedStartTime'] as String),
      expectedEnd: DateTime.parse(json['expectedEndTime'] as String),
      waitTimeMinutes: json['waitTimeMinutes'] as int,
      acceptingOnline: json['acceptingOnline'] as bool? ?? true,
      message: json['message'] as String?,
      peopleAhead: json['peopleAhead'] as int? ?? 0,
      seatsInService: json['seatsInService'] as int? ?? 1,
      calculatedAt: json['calculatedAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['calculatedAt'] as String),
    );
  }

  String get confidenceLabel {
    if (waitTimeMinutes <= 30) return 'High';
    if (waitTimeMinutes <= 60) return 'Medium';
    return 'Low';
  }
}

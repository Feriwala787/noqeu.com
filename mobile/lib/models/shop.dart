class Shop {
  final String id;
  final String name;
  final String occupation;
  final int totalSeats;
  final int avgTimePerCustomer;
  final bool isAcceptingOnline;
  final String address;
  final String description;
  final String? qrCodeString;

  const Shop({
    required this.id,
    required this.name,
    required this.occupation,
    required this.totalSeats,
    required this.avgTimePerCustomer,
    required this.isAcceptingOnline,
    this.address = '',
    this.description = '',
    this.qrCodeString,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: (json['_id'] ?? json['id']) as String,
      name: json['name'] as String,
      occupation: json['occupation'] as String? ?? 'General Service',
      totalSeats: json['totalSeats'] as int,
      avgTimePerCustomer: json['avgTimePerCustomer'] as int,
      isAcceptingOnline: json['isAcceptingOnline'] as bool? ?? true,
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      qrCodeString: json['qrCodeString'] as String?,
    );
  }
}

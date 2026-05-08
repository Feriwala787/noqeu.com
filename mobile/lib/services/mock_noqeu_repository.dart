import 'dart:math';
import '../models/appointment.dart';
import '../models/shop.dart';
import '../models/slot_estimate.dart';

class MockNoQeuRepository {
  final _rng = Random();
  final List<Shop> _shops = [
    const Shop(id: 'shop_1', name: 'Fade Zone Studio', occupation: 'Barber', totalSeats: 3, avgTimePerCustomer: 30, isAcceptingOnline: true, address: '12 Main St', description: 'Premium cuts & styling'),
    const Shop(id: 'shop_2', name: 'QuickFix Auto', occupation: 'Mechanic', totalSeats: 2, avgTimePerCustomer: 40, isAcceptingOnline: true, address: '45 Workshop Ave', description: 'Fast & reliable auto repairs'),
    const Shop(id: 'shop_3', name: 'Glow Skin Clinic', occupation: 'Dermatologist', totalSeats: 1, avgTimePerCustomer: 20, isAcceptingOnline: true, address: '8 Health Blvd', description: 'Expert skin care'),
  ];
  final List<Appointment> _appointments = [];

  Future<List<Shop>> getAccessedShops() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _shops;
  }

  Future<Shop> getShop(String shopId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _shops.firstWhere((s) => s.id == shopId);
  }

  Future<Shop> createShop(Map<String, dynamic> data) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final shop = Shop(
      id: 'shop_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] as String,
      occupation: data['occupation'] as String,
      totalSeats: data['totalSeats'] as int,
      avgTimePerCustomer: data['avgTimePerCustomer'] as int,
      isAcceptingOnline: true,
      address: data['address'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
    _shops.add(shop);
    return shop;
  }

  Future<Shop> updateShop(String shopId, Map<String, dynamic> data) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _shops.indexWhere((s) => s.id == shopId);
    final updated = Shop(
      id: shopId,
      name: data['name'] as String? ?? _shops[idx].name,
      occupation: data['occupation'] as String? ?? _shops[idx].occupation,
      totalSeats: data['totalSeats'] as int? ?? _shops[idx].totalSeats,
      avgTimePerCustomer: data['avgTimePerCustomer'] as int? ?? _shops[idx].avgTimePerCustomer,
      isAcceptingOnline: data['isAcceptingOnline'] as bool? ?? _shops[idx].isAcceptingOnline,
      address: data['address'] as String? ?? _shops[idx].address,
      description: data['description'] as String? ?? _shops[idx].description,
    );
    _shops[idx] = updated;
    return updated;
  }

  Future<List<Appointment>> getShopQueue(String shopId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _appointments.where((a) => a.shopId == shopId && a.status == 'Pending').toList();
  }

  Future<Shop> scanShop(String shopId) => getShop(shopId);

  Future<SlotEstimate> getNextSlot(String shopId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final shop = _shops.firstWhere((s) => s.id == shopId);
    final pending = _appointments.where((a) => a.shopId == shopId && a.status == 'Pending').length;
    final groupsAhead = (pending / shop.totalSeats).ceil();
    final wait = groupsAhead * shop.avgTimePerCustomer;
    final start = DateTime.now().add(Duration(minutes: wait));
    final end = start.add(Duration(minutes: shop.avgTimePerCustomer));
    return SlotEstimate(expectedStart: start, expectedEnd: end, waitTimeMinutes: wait, acceptingOnline: shop.isAcceptingOnline, peopleAhead: pending, seatsInService: shop.totalSeats, calculatedAt: DateTime.now());
  }

  Future<Appointment> createBooking(String shopId) async {
    final slot = await getNextSlot(shopId);
    final id = 'apt_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(999)}';
    final appt = Appointment(id: id, shopId: shopId, tokenNumber: _appointments.length + 1, slotStart: slot.expectedStart, slotEnd: slot.expectedEnd, status: 'Pending');
    _appointments.add(appt);
    return appt;
  }

  Future<void> cancelBooking(String appointmentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx >= 0) {
      final a = _appointments[idx];
      _appointments[idx] = Appointment(id: a.id, shopId: a.shopId, tokenNumber: a.tokenNumber, slotStart: a.slotStart, slotEnd: a.slotEnd, status: 'Cancelled');
    }
  }

  Future<Appointment> createOfflineWalkIn(String shopId) => createBooking(shopId);

  Future<void> ownerAction(String appointmentId, String action) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx >= 0) {
      final a = _appointments[idx];
      _appointments[idx] = Appointment(id: a.id, shopId: a.shopId, tokenNumber: a.tokenNumber, slotStart: a.slotStart, slotEnd: a.slotEnd, status: action);
    }
  }

  Future<List<Appointment>> getMyAppointments() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _appointments;
  }
}

import 'dart:math';

import '../models/appointment.dart';
import '../models/shop.dart';
import '../models/slot_estimate.dart';

class MockNoQeuRepository {
  final _rng = Random();
  final List<Shop> _shops = const [
    Shop(
      id: 'shop_1',
      name: 'Fade Zone Studio',
      occupation: 'Barber',
      totalSeats: 3,
      avgTimePerCustomer: 30,
      isAcceptingOnline: true,
    ),
    Shop(
      id: 'shop_2',
      name: 'QuickFix Auto',
      occupation: 'Mechanic',
      totalSeats: 2,
      avgTimePerCustomer: 40,
      isAcceptingOnline: true,
    ),
  ];

  final List<Appointment> _appointments = [];

  Future<List<Shop>> getAccessedShops() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _shops;
  }

  Future<SlotEstimate> getNextSlot(String shopId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final shop = _shops.firstWhere((s) => s.id == shopId);
    final pending = _appointments.where((a) => a.shopId == shopId && a.status == 'Pending').length;
    final groupsAhead = (pending / shop.totalSeats).ceil();
    final wait = groupsAhead * shop.avgTimePerCustomer;
    final start = DateTime.now().add(Duration(minutes: wait));
    final end = start.add(Duration(minutes: shop.avgTimePerCustomer));

    return SlotEstimate(
      expectedStart: start,
      expectedEnd: end,
      waitTimeMinutes: wait,
      acceptingOnline: true,
      peopleAhead: pending,
      seatsInService: shop.totalSeats,
      calculatedAt: DateTime.now(),
    );
  }

  Future<Appointment> createBooking(String shopId) async {
    final slot = await getNextSlot(shopId);
    final id = 'apt_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(999)}';
    final appt = Appointment(
      id: id,
      shopId: shopId,
      slotStart: slot.expectedStart,
      slotEnd: slot.expectedEnd,
      status: 'Pending',
    );
    _appointments.add(appt);
    return appt;
  }

  Future<void> cancelBooking(String appointmentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx >= 0) {
      _appointments[idx] = Appointment(
        id: _appointments[idx].id,
        shopId: _appointments[idx].shopId,
        slotStart: _appointments[idx].slotStart,
        slotEnd: _appointments[idx].slotEnd,
        status: 'Cancelled',
      );
    }
  }

  Future<Appointment> createOfflineWalkIn() async {
    return createBooking(_shops.first.id);
  }

  Future<void> ownerAction(String appointmentId, String action) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx >= 0) {
      final current = _appointments[idx];
      _appointments[idx] = Appointment(
        id: current.id,
        shopId: current.shopId,
        slotStart: current.slotStart,
        slotEnd: current.slotEnd,
        status: action,
      );
    }
  }
}

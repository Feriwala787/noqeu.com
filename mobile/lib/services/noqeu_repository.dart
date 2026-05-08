import '../models/appointment.dart';
import '../models/shop.dart';
import '../models/slot_estimate.dart';
import 'api_client.dart';

class NoQeuRepository {
  NoQeuRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Shop>> getAccessedShops() async {
    final raw = await _apiClient.fetchAccessedShops();
    return raw.map((j) => Shop.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Shop>> getMyShops() async {
    final raw = await _apiClient.fetchMyShops();
    return raw.map((j) => Shop.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<SlotEstimate> getNextSlot(String shopId) async {
    final raw = await _apiClient.fetchNextSlot(shopId);
    return SlotEstimate.fromJson(raw);
  }

  Future<Shop> getShop(String shopId) async {
    final raw = await _apiClient.fetchShop(shopId);
    return Shop.fromJson(raw);
  }

  Future<Shop> createShop(Map<String, dynamic> data) async {
    final raw = await _apiClient.createShop(data);
    return Shop.fromJson(raw);
  }

  Future<Shop> updateShop(String shopId, Map<String, dynamic> data) async {
    final raw = await _apiClient.updateShop(shopId, data);
    return Shop.fromJson(raw);
  }

  Future<List<Appointment>> getShopQueue(String shopId) async {
    final raw = await _apiClient.fetchShopQueue(shopId);
    return raw.map((j) => Appointment.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Shop> scanShop(String shopId) async {
    final raw = await _apiClient.scanShop(shopId);
    return Shop.fromJson(raw);
  }

  Future<Appointment> createBooking(String shopId) async {
    final raw = await _apiClient.bookAppointment(shopId);
    return Appointment.fromJson((raw['appointment'] ?? raw) as Map<String, dynamic>);
  }

  Future<void> cancelBooking(String appointmentId) => _apiClient.cancelAppointment(appointmentId);

  Future<Appointment> createOfflineWalkIn(String shopId) async {
    final raw = await _apiClient.addOfflineWalkIn(shopId);
    return Appointment.fromJson((raw['appointment'] ?? raw) as Map<String, dynamic>);
  }

  Future<void> ownerAction(String appointmentId, String action) => _apiClient.ownerAction(appointmentId, action);

  Future<List<Appointment>> getMyAppointments() async {
    final raw = await _apiClient.fetchMyAppointments();
    return raw.map((j) => Appointment.fromJson(j as Map<String, dynamic>)).toList();
  }
}

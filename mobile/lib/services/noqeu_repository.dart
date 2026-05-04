import '../models/appointment.dart';
import '../models/shop.dart';
import '../models/slot_estimate.dart';
import 'api_client.dart';

class NoQeuRepository {
  NoQeuRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Shop>> getAccessedShops() async {
    final raw = await _apiClient.fetchAccessedShops();
    return raw.map((json) => Shop.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<SlotEstimate> getNextSlot(String shopId) async {
    final raw = await _apiClient.fetchNextSlot(shopId);
    return SlotEstimate.fromJson(raw);
  }

  Future<Appointment> createBooking(String shopId) async {
    final raw = await _apiClient.bookAppointment(shopId);
    final appointmentJson = (raw['appointment'] ?? raw) as Map<String, dynamic>;
    return Appointment.fromJson(appointmentJson);
  }

  Future<void> cancelBooking(String appointmentId) {
    return _apiClient.cancelAppointment(appointmentId);
  }

  Future<Appointment> createOfflineWalkIn() async {
    final raw = await _apiClient.addOfflineWalkIn();
    final appointmentJson = (raw['appointment'] ?? raw) as Map<String, dynamic>;
    return Appointment.fromJson(appointmentJson);
  }

  Future<void> ownerAction(String appointmentId, String action) {
    return _apiClient.ownerAction(appointmentId, action);
  }
}

import '../models/appointment.dart';
import '../models/shop.dart';
import '../models/slot_estimate.dart';
import '../utils/app_config.dart';
import 'mock_noqeu_repository.dart';
import 'noqeu_repository.dart';

class NoQeuService {
  NoQeuService(this._apiRepo, this._mockRepo);

  final NoQeuRepository _apiRepo;
  final MockNoQeuRepository _mockRepo;

  bool get _useMock => AppConfig.useMockApi;

  Future<List<Shop>> getAccessedShops() =>
      _useMock ? _mockRepo.getAccessedShops() : _apiRepo.getAccessedShops();

  Future<List<Shop>> getMyShops() =>
      _useMock ? _mockRepo.getAccessedShops() : _apiRepo.getMyShops();

  Future<SlotEstimate> getNextSlot(String shopId) =>
      _useMock ? _mockRepo.getNextSlot(shopId) : _apiRepo.getNextSlot(shopId);

  Future<Shop> getShop(String shopId) =>
      _useMock ? _mockRepo.getShop(shopId) : _apiRepo.getShop(shopId);

  Future<Shop> createShop(Map<String, dynamic> data) =>
      _useMock ? _mockRepo.createShop(data) : _apiRepo.createShop(data);

  Future<Shop> updateShop(String shopId, Map<String, dynamic> data) =>
      _useMock ? _mockRepo.updateShop(shopId, data) : _apiRepo.updateShop(shopId, data);

  Future<List<Appointment>> getShopQueue(String shopId) =>
      _useMock ? _mockRepo.getShopQueue(shopId) : _apiRepo.getShopQueue(shopId);

  Future<Shop> scanShop(String shopId) =>
      _useMock ? _mockRepo.scanShop(shopId) : _apiRepo.scanShop(shopId);

  Future<Appointment> createBooking(String shopId) =>
      _useMock ? _mockRepo.createBooking(shopId) : _apiRepo.createBooking(shopId);

  Future<void> cancelBooking(String appointmentId) =>
      _useMock ? _mockRepo.cancelBooking(appointmentId) : _apiRepo.cancelBooking(appointmentId);

  Future<Appointment> createOfflineWalkIn(String shopId) =>
      _useMock ? _mockRepo.createOfflineWalkIn(shopId) : _apiRepo.createOfflineWalkIn(shopId);

  Future<void> ownerAction(String appointmentId, String action) =>
      _useMock ? _mockRepo.ownerAction(appointmentId, action) : _apiRepo.ownerAction(appointmentId, action);

  Future<List<Appointment>> getMyAppointments() =>
      _useMock ? _mockRepo.getMyAppointments() : _apiRepo.getMyAppointments();
}

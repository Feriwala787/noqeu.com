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

  Future<SlotEstimate> getNextSlot(String shopId) =>
      _useMock ? _mockRepo.getNextSlot(shopId) : _apiRepo.getNextSlot(shopId);

  Future<Appointment> createBooking(String shopId) =>
      _useMock ? _mockRepo.createBooking(shopId) : _apiRepo.createBooking(shopId);

  Future<void> cancelBooking(String appointmentId) =>
      _useMock ? _mockRepo.cancelBooking(appointmentId) : _apiRepo.cancelBooking(appointmentId);

  Future<Appointment> createOfflineWalkIn() =>
      _useMock ? _mockRepo.createOfflineWalkIn() : _apiRepo.createOfflineWalkIn();

  Future<void> ownerAction(String appointmentId, String action) =>
      _useMock ? _mockRepo.ownerAction(appointmentId, action) : _apiRepo.ownerAction(appointmentId, action);
}

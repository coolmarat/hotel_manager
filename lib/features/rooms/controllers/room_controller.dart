import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/database_events_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../database/models/room.dart';
import '../../../database/repositories/room_repository.dart';
import '../../../database/models/booking.dart'; // Assuming Booking model is defined here

final roomsProvider = StateNotifierProvider<RoomController, AsyncValue<List<Room>>>((ref) {
  final repository = ref.watch(roomRepositoryProvider);
  final controller = RoomController(repository);
  
  // Подписываемся на события базы данных
  final subscription = ref.listen<DatabaseEvent?>(databaseEventProvider, (previous, next) {
    if (next != null) {
      // Перезагружаем комнаты при любом событии базы данных
      controller.loadRooms();
    }
  });
  
  ref.onDispose(() {
    subscription.close();
  });
  
  return controller;
});

final roomProvider = FutureProvider.family<Room?, String>((ref, uuid) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoomByUuid(uuid);
});

class RoomController extends StateNotifier<AsyncValue<List<Room>>> {
  final RoomRepository _repository;
  final _uuid = const Uuid();

  RoomController(this._repository) : super(const AsyncValue.loading()) {
    loadRooms();
  }

  Future<void> loadRooms() async {
    try {
      state = const AsyncValue.loading();
      final rooms = await _repository.getAllRooms();
      state = AsyncValue.data(rooms);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addRoom({
    required String name,
    required String type,
    required int capacity,
    required double basePrice,
    String? description,
  }) async {
    try {
      final room = Room(
        id: 0, // ObjectBox will auto-generate the id
        uuid: _uuid.v4(),
        name: name,
        type: type,
        capacity: capacity,
        status: RoomStatus.available,
        basePrice: basePrice,
        description: description,
      );
      
      await _repository.insertRoom(room);
      await loadRooms();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateRoom(Room room) async {
    try {
      await _repository.updateRoom(room);
      await loadRooms();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateRoomStatus(String uuid, RoomStatus status) async {
    try {
      final room = await _repository.getRoomByUuid(uuid);
      if (room != null) {
        final updatedRoom = room.copyWith(status: status);
        await _repository.updateRoom(updatedRoom);
        await loadRooms();
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteRoom(String uuid) async {
    try {
      await _repository.deleteRoom(uuid);
      await loadRooms();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addBooking(Booking booking) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBooking(booking);
      state = AsyncValue.data(await _repository.getAllRooms());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

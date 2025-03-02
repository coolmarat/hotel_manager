import '../../objectbox.g.dart';
import '../objectbox.dart';
import '../models/room.dart';
import '../models/booking.dart';

class RoomRepository {
  final ObjectBox _objectBox;

  RoomRepository(this._objectBox);

  Future<List<Room>> getAllRooms() async {
    return _objectBox.roomBox.getAll();
  }

  Future<Room?> getRoomByUuid(String uuid) async {
    final query = _objectBox.roomBox.query(Room_.uuid.equals(uuid)).build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  Future<List<Room>> getRoomsByStatus(RoomStatus status) async {
    final query = _objectBox.roomBox.query(Room_.statusIndex.equals(status.index)).build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  Future<void> insertRoom(Room room) async {
    _objectBox.roomBox.put(room);
  }

  Future<void> updateRoom(Room room) async {
    _objectBox.roomBox.put(room);
  }

  Future<void> deleteRoom(String uuid) async {
    final query = _objectBox.roomBox.query(Room_.uuid.equals(uuid)).build();
    try {
      final room = query.findFirst();
      if (room != null) {
        _objectBox.roomBox.remove(room.id);
      }
    } finally {
      query.close();
    }
  }

  Future<void> addBooking(Booking booking) async {
    _objectBox.bookingBox.put(booking);
  }
  
  /// Добавляет несколько комнат в базу данных
  Future<void> addRooms(List<Room> rooms) async {
    _objectBox.roomBox.putMany(rooms);
  }
  
  /// Удаляет все комнаты из базы данных
  Future<void> deleteAllRooms() async {
    _objectBox.roomBox.removeAll();
  }
}

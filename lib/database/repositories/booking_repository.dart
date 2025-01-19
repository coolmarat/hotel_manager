import '../../objectbox.g.dart';
import '../objectbox.dart';
import '../models/booking.dart';

class BookingRepository {
  final ObjectBox _objectBox;

  BookingRepository(this._objectBox);

  Future<List<Booking>> getAllBookings() async {
    return _objectBox.bookingBox.getAll();
  }

  Future<Booking?> getBookingById(String uuid) async {
    final query = _objectBox.bookingBox.query(Booking_.uuid.equals(uuid)).build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  Future<List<Booking>> getBookingsByRoomUuid(String roomUuid) async {
    final box = _objectBox.bookingBox.query()
    ..link(Booking_.room, Room_.uuid.equals(roomUuid));
    
    try {
      final query = box.build();
      return query.find();
    } finally {
      // box.close();
    }
  }

  Future<List<Booking>> getBookingsInPeriod(DateTime start, DateTime end) async {
    final query = _objectBox.bookingBox
        .query(Booking_.checkIn
            .between(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch)
        .or(Booking_.checkOut
            .between(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch)))
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  Future<List<Booking>> getBookingsForRoomInPeriod(
    String roomUuid,
    DateTime start,
    DateTime end,
  ) async {
    final box = _objectBox.bookingBox
        .query(Booking_.checkIn
            .between(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch)
        .or(Booking_.checkOut
            .between(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch)))
        ..link(Booking_.room, Room_.uuid.equals(roomUuid));

    try {
      final query = box.build();
      return query.find();
    } finally {
      // box.close();
    }
  }

  Future<void> insertBooking(Booking booking) async {
    _objectBox.bookingBox.put(booking);
  }

  Future<void> updateBooking(Booking booking) async {
    _objectBox.bookingBox.put(booking);
  }

  Future<void> deleteBooking(String uuid) async {
    final query = _objectBox.bookingBox.query(Booking_.uuid.equals(uuid)).build();
    try {
      final booking = query.findFirst();
      if (booking != null) {
        _objectBox.bookingBox.remove(booking.id);
      }
    } finally {
      query.close();
    }
  }
}

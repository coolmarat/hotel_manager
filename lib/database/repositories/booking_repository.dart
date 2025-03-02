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
    // Получаем все бронирования
    final allBookings = await getAllBookings();
    
    // Фильтруем бронирования, которые пересекаются с указанным периодом
    return allBookings.where((booking) {
      // Бронирование пересекается с периодом, если:
      // 1. Дата заезда находится в периоде
      // 2. Дата выезда находится в периоде
      // 3. Период полностью внутри бронирования (заезд до начала периода, выезд после конца периода)
      
      final checkInInPeriod = booking.checkIn.isAfter(start) && booking.checkIn.isBefore(end);
      final checkOutInPeriod = booking.checkOut.isAfter(start) && booking.checkOut.isBefore(end);
      final periodInsideBooking = booking.checkIn.isBefore(start) && booking.checkOut.isAfter(end);
      
      // Также учитываем случаи, когда даты совпадают
      final checkInEqualsStart = booking.checkIn.year == start.year && 
                                booking.checkIn.month == start.month && 
                                booking.checkIn.day == start.day;
                                
      final checkOutEqualsEnd = booking.checkOut.year == end.year && 
                               booking.checkOut.month == end.month && 
                               booking.checkOut.day == end.day;
      
      return checkInInPeriod || checkOutInPeriod || periodInsideBooking || 
             checkInEqualsStart || checkOutEqualsEnd;
    }).toList();
  }

  Future<List<Booking>> getBookingsForRoomInPeriod(
    String roomUuid,
    DateTime start,
    DateTime end,
  ) async {
    // Получаем все бронирования для комнаты
    final bookings = await getBookingsByRoomUuid(roomUuid);
    
    // Фильтруем бронирования, учитывая время заезда и выезда
    return bookings.where((booking) {
      // Если день выезда существующего бронирования совпадает с днем заезда нового
      // и время выезда (12:00) раньше времени заезда (14:00), то считаем номер доступным
      if (booking.checkOut.year == start.year &&
          booking.checkOut.month == start.month &&
          booking.checkOut.day == start.day &&
          booking.checkOut.hour <= 12 &&
          start.hour >= 14) {
        return false; // Нет пересечения
      }
      
      // Если день заезда существующего бронирования совпадает с днем выезда нового
      // и время заезда (14:00) позже времени выезда (12:00), то считаем номер доступным
      if (booking.checkIn.year == end.year &&
          booking.checkIn.month == end.month &&
          booking.checkIn.day == end.day &&
          booking.checkIn.hour >= 14 &&
          end.hour <= 12) {
        return false; // Нет пересечения
      }
      
      // Проверяем на пересечение периодов
      return start.isBefore(booking.checkOut) && end.isAfter(booking.checkIn);
    }).toList();
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
  
  /// Добавляет несколько бронирований в базу данных
  Future<void> addBookings(List<Booking> bookings) async {
    _objectBox.bookingBox.putMany(bookings);
  }
  
  /// Удаляет все бронирования из базы данных
  Future<void> deleteAllBookings() async {
    _objectBox.bookingBox.removeAll();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../database/models/booking.dart';
import '../../../database/models/room.dart';
import '../models/room_date_status.dart';

final calendarControllerProvider = Provider((ref) {
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  final roomRepository = ref.watch(roomRepositoryProvider);
  return CalendarController(bookingRepository, roomRepository);
});

final roomsForDateProvider = FutureProvider.family<List<RoomWithStatus>, DateTime>((ref, date) async {
  final controller = ref.watch(calendarControllerProvider);
  return controller.getRoomsWithStatusForDate(date);
});

class CalendarController {
  final dynamic bookingRepository;
  final dynamic roomRepository;

  CalendarController(this.bookingRepository, this.roomRepository);

  Future<List<RoomWithStatus>> getRoomsWithStatusForDate(DateTime date) async {
    // Получаем все комнаты
    final rooms = await roomRepository.getAllRooms();
    
    // Создаем начало и конец дня для запроса (полные сутки)
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    // Получаем все бронирования, которые могут пересекаться с выбранной датой
    // Для этого берем более широкий диапазон дат
    final startOfQuery = startOfDay.subtract(const Duration(days: 30));
    final endOfQuery = endOfDay.add(const Duration(days: 30));
    final allBookings = await bookingRepository.getBookingsInPeriod(startOfQuery, endOfQuery);
    
    // Результирующий список комнат с их статусами
    final roomsWithStatus = <RoomWithStatus>[];
    
    for (final room in rooms) {
      // Фильтруем бронирования только для текущей комнаты
      final roomBookings = allBookings.where((booking) => 
        booking.room.target?.uuid == room.uuid).toList();
      
      // Проверяем, есть ли бронирования, которые пересекаются с выбранной датой
      final bookingsForDate = roomBookings.where((booking) => 
        _isDateOverlappingWithBooking(date, booking)).toList();
      
      if (bookingsForDate.isEmpty) {
        // Если нет бронирований на эту дату, комната свободна
        roomsWithStatus.add(RoomWithStatus(
          uuid: room.uuid,
          name: room.name,
          type: room.type,
          status: RoomDateStatus.available,
        ));
      } else {
        // Если есть бронирования, определяем статус
        for (final booking in bookingsForDate) {
          final isCheckInDay = _isSameDay(booking.checkIn, date);
          final isCheckOutDay = _isSameDay(booking.checkOut, date);
          
          RoomDateStatus status;
          
          if (isCheckInDay && isCheckOutDay) {
            // Если в один день и заезд и выезд (теоретически возможно)
            // Считаем как выезд, так как комната будет свободна после 12:00
            status = RoomDateStatus.checkOut;
          } else if (isCheckInDay) {
            status = RoomDateStatus.checkIn;
          } else if (isCheckOutDay) {
            status = RoomDateStatus.checkOut;
          } else {
            // Если дата между заездом и выездом, то комната занята
            status = RoomDateStatus.occupied;
          }
          
          roomsWithStatus.add(RoomWithStatus(
            uuid: room.uuid,
            name: room.name,
            type: room.type,
            status: status,
            guestName: booking.guestName,
            checkIn: booking.checkIn,
            checkOut: booking.checkOut,
          ));
          
          // Для каждой комнаты нам достаточно добавить одно бронирование
          break;
        }
      }
    }
    
    return roomsWithStatus;
  }
  
  bool _isDateOverlappingWithBooking(DateTime date, Booking booking) {
    // Создаем начало и конец дня для проверки
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    // Проверяем пересечение периодов
    // Дата пересекается с бронированием, если:
    // 1. Начало дня раньше конца бронирования И
    // 2. Конец дня позже начала бронирования
    return startOfDay.isBefore(booking.checkOut) && endOfDay.isAfter(booking.checkIn);
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

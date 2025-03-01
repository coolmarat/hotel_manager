import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/database_provider.dart';
import '../../../database/models/booking.dart';
import '../../../database/repositories/booking_repository.dart';

final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getAllBookings();
});

final roomBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, roomId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByRoomUuid(roomId);
});

final bookingControllerProvider = Provider((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return BookingController(repository, ref);
});

class BookingController {
  final BookingRepository _repository;
  final Ref _ref;
  final _uuid = const Uuid();

  BookingController(this._repository, this._ref);

  Future<bool> isRoomAvailable(String roomId, DateTime checkIn, DateTime checkOut) async {
    try {
      // Получаем все бронирования для данной комнаты
      final roomBookings = await _repository.getBookingsByRoomUuid(roomId);
      
      // Проверяем каждое бронирование на пересечение с запрашиваемым периодом
      for (final booking in roomBookings) {
        // Если день выезда существующего бронирования совпадает с днем заезда нового
        // и время выезда (12:00) раньше времени заезда (14:00), то считаем номер доступным
        if (booking.checkOut.year == checkIn.year &&
            booking.checkOut.month == checkIn.month &&
            booking.checkOut.day == checkIn.day &&
            booking.checkOut.hour <= 12 &&
            checkIn.hour >= 14) {
          continue; // Номер доступен в этот день (выезд до заезда)
        }
        
        // Если день заезда существующего бронирования совпадает с днем выезда нового
        // и время заезда (14:00) позже времени выезда (12:00), то считаем номер доступным
        if (booking.checkIn.year == checkOut.year &&
            booking.checkIn.month == checkOut.month &&
            booking.checkIn.day == checkOut.day &&
            booking.checkIn.hour >= 14 &&
            checkOut.hour <= 12) {
          continue; // Номер доступен в этот день (выезд до заезда)
        }
        
        // Проверяем на пересечение периодов
        if (checkIn.isBefore(booking.checkOut) && checkOut.isAfter(booking.checkIn)) {
          return false; // Есть пересечение, номер недоступен
        }
      }
      
      return true; // Нет пересечений, номер доступен
    } catch (e) {
      return false;
    }
  }

  Future<void> addBooking({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String guestName,
    required String guestPhone,
    required double totalPrice,
    required double amountPaid,
    String? notes,
  }) async {
    try {
      // Устанавливаем время заезда на 14:00
      final checkInWithTime = DateTime(
        checkIn.year, 
        checkIn.month, 
        checkIn.day, 
        14, // 14:00 - время заезда
        0
      );
      
      // Устанавливаем время выезда на 12:00
      final checkOutWithTime = DateTime(
        checkOut.year, 
        checkOut.month, 
        checkOut.day, 
        12, // 12:00 - время выезда
        0
      );
      
      // Проверяем доступность номера
      final isAvailable = await isRoomAvailable(roomId, checkInWithTime, checkOutWithTime);
      if (!isAvailable) {
        throw Exception('Room is not available for selected dates');
      }

      // Получаем комнату
      final room = await _ref.read(roomRepositoryProvider).getRoomByUuid(roomId);
      if (room == null) {
        throw Exception('Room not found');
      }

      // Определяем статус оплаты
      PaymentStatus paymentStatus;
      if (amountPaid >= totalPrice) {
        paymentStatus = PaymentStatus.paid;
      } else if (amountPaid > 0) {
        paymentStatus = PaymentStatus.partiallyPaid;
      } else {
        paymentStatus = PaymentStatus.unpaid;
      }

      final booking = Booking(
        id: 0,
        uuid: _uuid.v4(),
        checkIn: checkInWithTime,
        checkOut: checkOutWithTime,
        guestName: guestName,
        guestPhone: guestPhone,
        totalPrice: totalPrice,
        amountPaid: amountPaid,
        paymentStatus: paymentStatus,
        notes: notes,
      );
      
      // Устанавливаем связь с комнатой
      booking.room.target = room;
      
      await _repository.insertBooking(booking);
      // Обновляем данные
      _ref.invalidate(bookingsProvider);
      _ref.invalidate(roomBookingsProvider(roomId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBooking(Booking booking) async {
    try {
      await _repository.updateBooking(booking);
      // Обновляем данные
      _ref.invalidate(bookingsProvider);
      _ref.invalidate(roomBookingsProvider(booking.room.target?.uuid ?? ''));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePayment(String bookingId, double newAmountPaid) async {
    try {
      final bookings = await _repository.getAllBookings();
      final bookingToUpdate = bookings.firstWhere((booking) => booking.uuid == bookingId);
      
      // Сохраняем ссылку на комнату перед обновлением
      final roomTarget = bookingToUpdate.room.target;
      
      // Определяем статус оплаты
      PaymentStatus newStatus;
      if (newAmountPaid >= bookingToUpdate.totalPrice) {
        newStatus = PaymentStatus.paid;
      } else if (newAmountPaid > 0) {
        newStatus = PaymentStatus.partiallyPaid;
      } else {
        newStatus = PaymentStatus.unpaid;
      }
      
      final updatedBooking = bookingToUpdate.copyWith(
        amountPaid: newAmountPaid,
        paymentStatus: newStatus,
      );
      
      // Восстанавливаем связь с комнатой
      updatedBooking.room.target = roomTarget;
      
      // Убедимся, что статус оплаты установлен правильно
      updatedBooking.paymentStatus = newStatus;
      
      await _repository.updateBooking(updatedBooking);
      // Обновляем данные
      _ref.invalidate(bookingsProvider);
      if (roomTarget != null) {
        _ref.invalidate(roomBookingsProvider(roomTarget.uuid));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBooking(String uuid) async {
    try {
      final bookings = await _repository.getAllBookings();
      final bookingToDelete = bookings.firstWhere((booking) => booking.uuid == uuid);
      final roomId = bookingToDelete.room.target?.uuid;
      
      await _repository.deleteBooking(uuid);
      // Обновляем данные
      _ref.invalidate(bookingsProvider);
      if (roomId != null) {
        _ref.invalidate(roomBookingsProvider(roomId));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Booking>> getBookingsForPeriod(DateTime start, DateTime end) async {
    return _repository.getBookingsInPeriod(start, end);
  }
}

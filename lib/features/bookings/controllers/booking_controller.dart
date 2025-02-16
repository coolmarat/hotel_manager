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
      final conflictingBookings = await _repository.getBookingsForRoomInPeriod(
        roomId,
        checkIn,
        checkOut,
      );
      return conflictingBookings.isEmpty;
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
      // Проверяем доступность номера
      final isAvailable = await isRoomAvailable(roomId, checkIn, checkOut);
      if (!isAvailable) {
        throw Exception('Room is not available for selected dates');
      }

      // Получаем комнату
      final room = await _ref.read(roomRepositoryProvider).getRoomByUuid(roomId);
      if (room == null) {
        throw Exception('Room not found');
      }

      final booking = Booking(
        id: 0,
        uuid: _uuid.v4(),
        checkIn: checkIn,
        checkOut: checkOut,
        guestName: guestName,
        guestPhone: guestPhone,
        totalPrice: totalPrice,
        amountPaid: amountPaid,
        paymentStatus: amountPaid >= totalPrice 
          ? PaymentStatus.paid
          : amountPaid > 0 
            ? PaymentStatus.partiallyPaid 
            : PaymentStatus.unpaid,
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
      
      final updatedBooking = bookingToUpdate.copyWith(
        amountPaid: newAmountPaid,
        paymentStatus: newAmountPaid >= bookingToUpdate.totalPrice 
          ? PaymentStatus.paid
          : newAmountPaid > 0 
            ? PaymentStatus.partiallyPaid 
            : PaymentStatus.unpaid,
      );
      
      await _repository.updateBooking(updatedBooking);
      // Обновляем данные
      _ref.invalidate(bookingsProvider);
      _ref.invalidate(roomBookingsProvider(updatedBooking.room.target?.uuid ?? ''));
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/database_provider.dart';
import '../../../database/models/booking.dart';
import '../../../database/repositories/booking_repository.dart';

final bookingsProvider = StateNotifierProvider<BookingController, AsyncValue<List<Booking>>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return BookingController(repository);
});

class BookingController extends StateNotifier<AsyncValue<List<Booking>>> {
  final BookingRepository _repository;
  final _uuid = const Uuid();

  BookingController(this._repository) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    try {
      state = const AsyncValue.loading();
      final bookings = await _repository.getAllBookings();
      state = AsyncValue.data(bookings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

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

      final booking = Booking(
        id: 0, // ObjectBox will auto-generate the id
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
      
      await _repository.insertBooking(booking);
      await loadBookings();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateBooking(Booking booking) async {
    try {
      await _repository.updateBooking(booking);
      await loadBookings();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updatePayment(String bookingId, double newAmountPaid) async {
    try {
      final currentBookings = state.value ?? [];
      final bookingToUpdate = currentBookings.firstWhere((booking) => booking.id == bookingId);
      
      final updatedBooking = bookingToUpdate.copyWith(
        amountPaid: newAmountPaid,
        paymentStatus: newAmountPaid >= bookingToUpdate.totalPrice 
          ? PaymentStatus.paid
          : newAmountPaid > 0 
            ? PaymentStatus.partiallyPaid 
            : PaymentStatus.unpaid,
      );
      
      await _repository.updateBooking(updatedBooking);
      await loadBookings();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteBooking(String uuid) async {
    try {
      await _repository.deleteBooking(uuid);
      await loadBookings();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<Booking>> getBookingsForPeriod(DateTime start, DateTime end) async {
    try {
      return await _repository.getBookingsInPeriod(start, end);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return [];
    }
  }

  Future<List<Booking>> getBookingsForRoom(String roomId) async {
    try {
      return await _repository.getBookingsByRoomUuid(roomId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return [];
    }
  }
}

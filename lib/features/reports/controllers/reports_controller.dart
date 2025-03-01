import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';

class ReportData {
  final DateTime startDate;
  final DateTime endDate;
  final double customPeriodRevenue;
  final int customPeriodBookingsCount;
  final int customPeriodCheckInsCount;
  final int customPeriodCheckOutsCount;

  ReportData({
    required this.startDate,
    required this.endDate,
    required this.customPeriodRevenue,
    required this.customPeriodBookingsCount,
    required this.customPeriodCheckInsCount,
    required this.customPeriodCheckOutsCount,
  });
}

// Provider to store the selected date range
final dateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  return DateTimeRange(start: today, end: tomorrow);
});

// Provider for reports data
final reportsProvider = FutureProvider.autoDispose<ReportData>((ref) async {
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  final dateRange = ref.watch(dateRangeProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 7));
  final monthAgo = DateTime(now.year, now.month - 1, now.day);

  // Получаем все бронирования за разные периоды
  final todayBookings = await bookingRepository.getBookingsInPeriod(today, tomorrow);
  final weeklyBookings = await bookingRepository.getBookingsInPeriod(weekAgo, tomorrow);
  final monthlyBookings = await bookingRepository.getBookingsInPeriod(monthAgo, tomorrow);
  final customPeriodBookings = await bookingRepository.getBookingsInPeriod(
    dateRange.start, 
    dateRange.end.add(const Duration(days: 1)), // Include the end date
  );

  // Считаем выручку
  final dailyRevenue = todayBookings.fold<double>(
    0,
    (sum, booking) => sum + booking.amountPaid,
  );

  final weeklyRevenue = weeklyBookings.fold<double>(
    0,
    (sum, booking) => sum + booking.amountPaid,
  );

  final monthlyRevenue = monthlyBookings.fold<double>(
    0,
    (sum, booking) => sum + booking.amountPaid,
  );
  
  final customPeriodRevenue = customPeriodBookings.fold<double>(
    0,
    (sum, booking) => sum + booking.amountPaid,
  );

  // Считаем количество заездов и выездов сегодня
  final checkInsToday = todayBookings.where((booking) => 
    booking.checkIn.year == today.year &&
    booking.checkIn.month == today.month &&
    booking.checkIn.day == today.day
  ).length;

  final checkOutsToday = todayBookings.where((booking) => 
    booking.checkOut.year == today.year &&
    booking.checkOut.month == today.month &&
    booking.checkOut.day == today.day
  ).length;
  
  // Считаем количество заездов и выездов в выбранный период
  final customPeriodCheckInsCount = customPeriodBookings.where((booking) {
    final checkInDate = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
    return checkInDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) && 
           checkInDate.isBefore(dateRange.end.add(const Duration(days: 1)));
  }).length;
  
  final customPeriodCheckOutsCount = customPeriodBookings.where((booking) {
    final checkOutDate = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);
    return checkOutDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) && 
           checkOutDate.isBefore(dateRange.end.add(const Duration(days: 1)));
  }).length;

  return ReportData(
    startDate: dateRange.start,
    endDate: dateRange.end,
    customPeriodRevenue: customPeriodRevenue,
    customPeriodBookingsCount: customPeriodBookings.length,
    customPeriodCheckInsCount: customPeriodCheckInsCount,
    customPeriodCheckOutsCount: customPeriodCheckOutsCount,
  );
});

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});
}

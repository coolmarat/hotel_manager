import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../database/models/room.dart';

class ReportData {
  final double occupancyRate;
  final double dailyRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final int totalBookings;
  final int checkInsToday;
  final int checkOutsToday;

  ReportData({
    required this.occupancyRate,
    required this.dailyRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.totalBookings,
    required this.checkInsToday,
    required this.checkOutsToday,
  });
}

final reportsProvider = FutureProvider.autoDispose<ReportData>((ref) async {
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  final roomRepository = ref.watch(roomRepositoryProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 7));
  final monthAgo = DateTime(now.year, now.month - 1, now.day);

  // Получаем все комнаты
  final rooms = await roomRepository.getAllRooms();
  final totalRooms = rooms.length;

  // Получаем все бронирования за разные периоды
  final todayBookings = await bookingRepository.getBookingsInPeriod(today, tomorrow);
  final weeklyBookings = await bookingRepository.getBookingsInPeriod(weekAgo, tomorrow);
  final monthlyBookings = await bookingRepository.getBookingsInPeriod(monthAgo, tomorrow);

  // Считаем занятые комнаты
  final occupiedRooms = rooms.where((room) => room.status == RoomStatus.occupied).length;
  final occupancyRate = totalRooms > 0 ? occupiedRooms / totalRooms : 0.0;

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

  return ReportData(
    occupancyRate: occupancyRate,
    dailyRevenue: dailyRevenue,
    weeklyRevenue: weeklyRevenue,
    monthlyRevenue: monthlyRevenue,
    totalBookings: todayBookings.length,
    checkInsToday: checkInsToday,
    checkOutsToday: checkOutsToday,
  );
});

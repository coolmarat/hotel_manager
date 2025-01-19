import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/strings.dart';
import '../controllers/reports_controller.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () {
              // TODO: Implement date range picker
            },
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: ${error.toString()}'),
        ),
        data: (report) => ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      Strings.occupancyRate,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: report.occupancyRate,
                      backgroundColor: Colors.grey[200],
                      minHeight: 10,
                    ),
                    const SizedBox(height: 8),
                    Text('${(report.occupancyRate * 100).toStringAsFixed(1)}% комнат заняты'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      Strings.revenue,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRevenueItem(Strings.daily, formatCurrency(report.dailyRevenue)),
                        _buildRevenueItem(Strings.weekly, formatCurrency(report.weeklyRevenue)),
                        _buildRevenueItem(Strings.monthly, formatCurrency(report.monthlyRevenue)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      Strings.bookingsOverview,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBookingStatItem(Strings.totalBookings, report.totalBookings.toString()),
                    const Divider(),
                    _buildBookingStatItem(Strings.checkInsToday, report.checkInsToday.toString()),
                    const Divider(),
                    _buildBookingStatItem(Strings.checkOutsToday, report.checkOutsToday.toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(String label, String amount) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '\₽',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

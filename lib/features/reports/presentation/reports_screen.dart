import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/strings.dart';
import '../controllers/reports_controller.dart' as rep_con;
import 'package:intl/intl.dart';

// Alias for Flutter's DateTimeRange to avoid conflict with our custom class
typedef MaterialDateTimeRange = material.DateTimeRange;

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(rep_con.reportsProvider);
    final dateRange = ref.watch(rep_con.dateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context, ref),
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
            // Date range indicator
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          Strings.selectedPeriod,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showDateRangePicker(context, ref),
                          child: const Text(Strings.changePeriod),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDate(report.startDate)} - ${_formatDate(report.endDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${Strings.totalRevenueInPeriod} ${formatCurrency(report.customPeriodRevenue)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      Strings.periodStatistics,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBookingStatItem(Strings.totalBookingsInPeriod, report.customPeriodBookingsCount.toString()),
                    _buildBookingStatItem(Strings.checkInsInPeriod, report.customPeriodCheckInsCount.toString()),
                    _buildBookingStatItem(Strings.checkOutsInPeriod, report.customPeriodCheckOutsCount.toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final currentRange = ref.read(rep_con.dateRangeProvider);
    final now = DateTime.now();
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: MaterialDateTimeRange(
        start: currentRange.start,
        end: currentRange.end,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
      locale: const Locale('ru', 'RU'),
      cancelText: Strings.cancel,
      confirmText: Strings.save,
      saveText: Strings.save,
      helpText: Strings.selectedPeriod,
    );
    
    if (pickedDateRange != null) {
      ref.read(rep_con.dateRangeProvider.notifier).state = rep_con.DateTimeRange(
        start: pickedDateRange.start,
        end: pickedDateRange.end,
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
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

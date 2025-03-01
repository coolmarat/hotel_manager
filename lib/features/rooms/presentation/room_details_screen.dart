import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/strings.dart';
import '../../../database/models/booking.dart';
import '../../../database/models/room.dart';
import '../../bookings/controllers/booking_controller.dart';
import '../../bookings/presentation/payment_dialog.dart';
import '../controllers/room_controller.dart';
import 'book_room_screen.dart';

class RoomDetailsScreen extends ConsumerWidget {
  final Room room;

  const RoomDetailsScreen({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Комната ${room.name}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookRoomScreen(roomUuid: room.uuid),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Информация о комнате',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Тип: ${room.type}'),
                    Text('Вместимость: ${room.capacity} чел.'),
                    Text('Базовая цена: ${room.basePrice} руб.'),
                    if (room.description != null)
                      Text('Описание: ${room.description}'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Бронирования',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ref.watch(bookingsProvider).when(
              data: (bookings) {
                final roomBookings = bookings.where((booking) {
                  // Assuming booking has a relation 'room' with a 'uuid' field
                  return booking.room.target?.uuid == room.uuid;
                }).toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: roomBookings.length,
                  itemBuilder: (context, index) {
                    final booking = roomBookings[index];
                    return BookingCard(booking: booking);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingCard extends ConsumerWidget {
  final Booking booking;

  const BookingCard({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    // Получаем локализованный статус оплаты
    final paymentStatus = Strings.paymentStatuses[booking.paymentStatus.name] ?? booking.paymentStatus.name;
    
    return Card(
      child: InkWell(
        onTap: () => _showBookingOptions(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${dateFormat.format(booking.checkIn)} - ${dateFormat.format(booking.checkOut)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteDialog(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Гость: ${booking.guestName}'),
              Text('Телефон: ${booking.guestPhone}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${Strings.totalPrice}: ${booking.totalPrice}'),
                  Text(
                    paymentStatus,
                    style: TextStyle(
                      color: booking.paymentStatus == PaymentStatus.paid
                          ? Colors.green
                          : booking.paymentStatus == PaymentStatus.partiallyPaid
                              ? Colors.orange
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (booking.amountPaid > 0)
                Text('${Strings.amountPaid}: ${booking.amountPaid}'),
              if (booking.notes != null && booking.notes!.isNotEmpty)
                Text('Заметки: ${booking.notes}'),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.phone),
            title: Text(Strings.callGuest),
            onTap: () {
              Navigator.pop(context);
              _callGuest(context, booking.guestPhone);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: Text(Strings.addPayment),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => PaymentDialog(booking: booking),
              ).then((value) {
                if (value == true) {
                  // Обновляем данные после изменения оплаты
                  ref.invalidate(bookingsProvider);
                  if (booking.room.target != null) {
                    ref.invalidate(roomProvider(booking.room.target!.uuid));
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _callGuest(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      // Если не можем позвонить, копируем номер в буфер обмена
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Номер телефона скопирован в буфер обмена')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить бронирование?'),
          content: const Text('Это действие нельзя отменить'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ОТМЕНА'),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(bookingControllerProvider).deleteBooking(booking.uuid);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('УДАЛИТЬ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

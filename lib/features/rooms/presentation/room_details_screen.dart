import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotel_manager/database/models/room.dart';
import 'package:hotel_manager/database/models/booking.dart';
import 'package:intl/intl.dart';
import 'book_room_screen.dart';

class RoomDetailsScreen extends StatelessWidget {
  final Room room;

  const RoomDetailsScreen({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: room.bookings.length,
              itemBuilder: (context, index) {
                final booking = room.bookings[index];
                return BookingCard(booking: booking);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final Booking booking;

  const BookingCard({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return Card(
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: booking.guestPhone));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Номер телефона скопирован'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dateFormat.format(booking.checkIn)} - ${dateFormat.format(booking.checkOut)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Гость: ${booking.guestName}'),
              Text('Телефон: ${booking.guestPhone}'),
              Text('Статус оплаты: ${booking.paymentStatus.name}'),
              if (booking.notes != null && booking.notes!.isNotEmpty)
                Text('Заметки: ${booking.notes}'),
            ],
          ),
        ),
      ),
    );
  }
}

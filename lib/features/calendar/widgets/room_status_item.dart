import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/room_date_status.dart';
import '../../rooms/presentation/book_room_screen.dart';

class RoomStatusItem extends StatelessWidget {
  final RoomWithStatus room;
  
  const RoomStatusItem({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          // Если комната свободна, переходим на экран бронирования
          if (room.status == RoomDateStatus.available) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BookRoomScreen(
                  roomUuid: room.uuid,
                  initialCheckIn: DateTime.now(), // Используем текущую дату как начальную
                ),
              ),
            );
          }
        },
        child: ListTile(
          title: Row(
            children: [
              Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildStatusChip(),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Тип: ${room.type}'),
              if (room.guestName != null) Text('Гость: ${room.guestName}'),
              if (room.checkIn != null && room.status != RoomDateStatus.available)
                Text('Заезд: ${DateFormat('dd.MM.yyyy HH:mm').format(room.checkIn!)}'),
              if (room.checkOut != null && room.status != RoomDateStatus.available)
                Text('Выезд: ${DateFormat('dd.MM.yyyy HH:mm').format(room.checkOut!)}'),
            ],
          ),
          leading: _buildStatusIndicator(),
        ),
      ),
    );
  }
  
  Widget _buildStatusIndicator() {
    IconData icon;
    Color color;
    
    switch (room.status) {
      case RoomDateStatus.available:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case RoomDateStatus.occupied:
        icon = Icons.hotel;
        color = Colors.red;
        break;
      case RoomDateStatus.checkIn:
        icon = Icons.login;
        color = Colors.blue;
        break;
      case RoomDateStatus.checkOut:
        icon = Icons.logout;
        color = Colors.orange;
        break;
    }
    
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }
  
  Widget _buildStatusChip() {
    String label;
    Color color;
    
    switch (room.status) {
      case RoomDateStatus.available:
        label = 'Свободен';
        color = Colors.green;
        break;
      case RoomDateStatus.occupied:
        label = 'Занят';
        color = Colors.red;
        break;
      case RoomDateStatus.checkIn:
        label = 'Заезд';
        color = Colors.blue;
        break;
      case RoomDateStatus.checkOut:
        label = 'Выезд';
        color = Colors.orange;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../core/localization/strings.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/room_status_item.dart';
import '../models/room_date_status.dart';
import '../../rooms/presentation/book_room_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<CalendarFormat, String> _availableFormats = const {
    CalendarFormat.month: 'Месяц',
    CalendarFormat.twoWeeks: '2 недели',
    CalendarFormat.week: 'Неделя',
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU', null);
    // Устанавливаем текущий день как выбранный по умолчанию
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    // Получаем список комнат с их статусами для выбранного дня
    final roomsForDate = _selectedDay != null
        ? ref.watch(roomsForDateProvider(_selectedDay!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.calendar),
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ru_RU',
            availableCalendarFormats: _availableFormats,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          if (_selectedDay != null) _buildDateHeader(),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Выберите дату для просмотра статусов номеров'))
                : roomsForDate!.when(
                    data: (rooms) => _buildRoomsList(rooms),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('Ошибка загрузки: $error'),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Если выбрана комната со статусом "свободна", переходим на экран бронирования
          if (_selectedDay != null) {
            final roomsAsync = ref.read(roomsForDateProvider(_selectedDay!));
            roomsAsync.whenData((rooms) {
              // Находим первую свободную комнату
              final availableRoom = rooms.firstWhere(
                (room) => room.status == RoomDateStatus.available,
                orElse: () => RoomWithStatus(
                  uuid: '',
                  name: '',
                  type: '',
                  status: RoomDateStatus.available,
                ),
              );
              
              if (availableRoom.uuid.isNotEmpty) {
                // Переходим на экран бронирования с предустановленной датой
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BookRoomScreen(
                      roomUuid: availableRoom.uuid,
                      initialCheckIn: _selectedDay,
                    ),
                  ),
                );
              } else {
                // Если нет свободных комнат, показываем сообщение
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Нет свободных комнат на выбранную дату'),
                  ),
                );
              }
            });
          } else {
            // Если дата не выбрана, показываем сообщение
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Пожалуйста, выберите дату'),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.calendar_today),
          const SizedBox(width: 8),
          Text(
            'Статусы номеров на ${_formatDate(_selectedDay!)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Widget _buildRoomsList(List<RoomWithStatus> rooms) {
    if (rooms.isEmpty) {
      return const Center(child: Text('Нет данных о номерах на выбранную дату'));
    }

    // Сортируем комнаты: сначала свободные, затем остальные по статусу
    final sortedRooms = List<RoomWithStatus>.from(rooms);
    sortedRooms.sort((a, b) {
      // Сначала сортируем по статусу (свободные первыми)
      if (a.status == RoomDateStatus.available && b.status != RoomDateStatus.available) {
        return -1;
      }
      if (a.status != RoomDateStatus.available && b.status == RoomDateStatus.available) {
        return 1;
      }
      
      // Затем сортируем по другим статусам
      if (a.status != b.status) {
        return a.status.index - b.status.index;
      }
      
      // Если статусы одинаковые, сортируем по имени
      return a.name.compareTo(b.name);
    });

    return ListView.builder(
      itemCount: sortedRooms.length,
      itemBuilder: (context, index) {
        return RoomStatusItem(room: sortedRooms[index]);
      },
    );
  }
}

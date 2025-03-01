import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../database/models/room.dart';
import '../../../database/models/booking.dart';
import '../../../database/models/client.dart';
import '../../../database/repositories/client_repository.dart';
import '../../../core/providers/database_provider.dart';
import '../../bookings/controllers/booking_controller.dart';
import '../../bookings/presentation/payment_dialog.dart';
import '../../clients/presentation/contact_search_screen.dart';
import '../controllers/room_controller.dart';
import '../../../core/localization/strings.dart';

class BookRoomScreen extends ConsumerStatefulWidget {
  final String roomUuid;

  const BookRoomScreen({
    super.key,
    required this.roomUuid,
  });

  @override
  ConsumerState<BookRoomScreen> createState() => _BookRoomScreenState();
}

class _BookRoomScreenState extends ConsumerState<BookRoomScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isDateAvailable(DateTime day, List<Booking> bookings) {
    // Проверяем, есть ли пересечения с существующими бронированиями
    for (final booking in bookings) {
      // Если день равен дню выезда существующего бронирования,
      // считаем его доступным (выезд в 12:00, заезд в 14:00)
      if (day.year == booking.checkOut.year && 
          day.month == booking.checkOut.month && 
          day.day == booking.checkOut.day) {
        continue; // День выезда считается свободным для нового бронирования
      }
      
      // Если день равен дню заезда существующего бронирования,
      // считаем его доступным для выезда нового бронирования
      if (day.year == booking.checkIn.year && 
          day.month == booking.checkIn.month && 
          day.day == booking.checkIn.day) {
        continue; // День заезда считается свободным для выезда нового бронирования
      }
      
      // Проверяем, находится ли день в диапазоне бронирования
      if (day.isAfter(booking.checkIn.subtract(const Duration(days: 1))) &&
          day.isBefore(booking.checkOut)) {
        return false;
      }
    }
    return true;
  }

  bool _isValidRange(DateTime start, DateTime end, List<Booking> bookings) {
    var current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (!_isDateAvailable(current, bookings)) {
        return false;
      }
      current = current.add(const Duration(days: 1));
    }
    return true;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay, List<Booking> bookings) {
    setState(() {
      _errorMessage = null;
      
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Начинаем новый выбор периода
        if (!_isDateAvailable(selectedDay, bookings)) {
          _errorMessage = 'Выбранная дата недоступна';
          return;
        }
        _startDate = selectedDay;
        _endDate = null;
      } else {
        // Выбираем конечную дату
        if (selectedDay.isBefore(_startDate!)) {
          _errorMessage = 'Дата выезда не может быть раньше даты заезда';
          return;
        }
        
        if (!_isValidRange(_startDate!, selectedDay, bookings)) {
          _errorMessage = 'В выбранном периоде есть занятые даты';
          return;
        }
        
        _endDate = selectedDay;
      }
    });
  }

  Future<void> _callGuest(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      // Если не можем позвонить, копируем номер в буфер обмена
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Номер телефона скопирован в буфер обмена')),
        );
      }
    }
  }

  void _showBookingOptions(Booking booking) {
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
              _callGuest(booking.guestPhone);
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
                  ref.invalidate(roomProvider(widget.roomUuid));
                }
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomUuid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новое бронирование'),
      ),
      body: roomAsync.when(
        data: (room) {
          if (room == null) {
            return const Center(
              child: Text('Комната не найдена'),
            );
          }
          
          final bookings = room.bookings;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Список существующих бронирований
                  if (bookings.isNotEmpty) ...[
                    const Text(
                      'Существующие бронирования:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...bookings.map((booking) {
                      final checkInDate = '${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}';
                      final checkOutDate = '${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}';
                      final paymentStatus = Strings.paymentStatuses[booking.paymentStatus.name] ?? booking.paymentStatus.name;
                      
                      return Card(
                        child: InkWell(
                          onTap: () => _showBookingOptions(booking),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.guestName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('$checkInDate - $checkOutDate'),
                                Text('${Strings.guestPhone}: ${booking.guestPhone}'),
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
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],
                  
                  Card(
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: DateTime.now(),
                      selectedDayPredicate: (day) {
                        return _startDate?.isAtSameMomentAs(day) == true ||
                               _endDate?.isAtSameMomentAs(day) == true;
                      },
                      rangeStartDay: _startDate,
                      rangeEndDay: _endDate,
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Месяц',
                      },
                      enabledDayPredicate: (day) {
                        return _isDateAvailable(day, bookings);
                      },
                      onDaySelected: (selectedDay, focusedDay) =>
                          _onDaySelected(selectedDay, focusedDay, bookings),
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_startDate != null && _endDate != null) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Имя гостя',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            final result = await Navigator.push<Client>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ContactSearchScreen(),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _nameController.text = result.name;
                                _phoneController.text = result.phone;
                              });
                            }
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите имя гостя';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите телефон';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Заметки',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Сохраняем или находим клиента
                            final clientRepo = ref.read(clientRepositoryProvider);
                            final client = clientRepo.createOrFind(
                              _nameController.text,
                              _phoneController.text,
                              notes: _notesController.text.isEmpty ? null : _notesController.text,
                            );

                            // Создаем бронирование
                            await ref.read(bookingControllerProvider).addBooking(
                              roomId: room.uuid,
                              checkIn: _startDate!,
                              checkOut: _endDate!,
                              guestName: _nameController.text,
                              guestPhone: _phoneController.text,
                              totalPrice: room.basePrice * _endDate!.difference(_startDate!).inDays,
                              amountPaid: 0,
                              notes: _notesController.text.isEmpty ? null : _notesController.text,
                            );
                            
                            // Обновляем данные комнаты
                            ref.invalidate(roomProvider(widget.roomUuid));
                            
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Забронировать'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }
}

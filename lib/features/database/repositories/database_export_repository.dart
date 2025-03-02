import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hotel_manager/database/models/booking.dart';
import 'package:hotel_manager/database/models/client.dart';
import 'package:hotel_manager/database/models/room.dart';
import 'package:hotel_manager/database/objectbox.dart';
import 'package:hotel_manager/database/repositories/booking_repository.dart';
import 'package:hotel_manager/database/repositories/client_repository.dart';
import 'package:hotel_manager/database/repositories/room_repository.dart';
import 'package:hotel_manager/features/database/models/database_export.dart';

/// Репозиторий для экспорта и импорта базы данных
class DatabaseExportRepository {
  final RoomRepository _roomRepository;
  final BookingRepository _bookingRepository;
  final ClientRepository _clientRepository;
  final ObjectBox _objectBox;
  
  static const String currentVersion = '1.0.0';

  DatabaseExportRepository({
    required RoomRepository roomRepository,
    required BookingRepository bookingRepository,
    required ClientRepository clientRepository,
    required ObjectBox objectBox,
  })  : _roomRepository = roomRepository,
        _bookingRepository = bookingRepository,
        _clientRepository = clientRepository,
        _objectBox = objectBox;

  /// Экспортирует все данные из базы данных в формат JSON
  Future<DatabaseExport> exportDatabase() async {
    try {
      // Получаем все данные из базы
      final rooms = await _roomRepository.getAllRooms();
      final bookings = await _bookingRepository.getAllBookings();
      final clients = await _clientRepository.getAllClients();

      // Преобразуем данные в экспортный формат
      final roomExports = rooms.map((room) => RoomExport(
            uuid: room.uuid,
            name: room.name,
            type: room.type,
            capacity: room.capacity,
            basePrice: room.basePrice,
            description: room.description,
            statusIndex: room.statusIndex,
          )).toList();

      final bookingExports = bookings.map((booking) => BookingExport(
            uuid: booking.uuid,
            checkIn: booking.checkIn.toIso8601String(),
            checkOut: booking.checkOut.toIso8601String(),
            guestName: booking.guestName,
            guestPhone: booking.guestPhone,
            totalPrice: booking.totalPrice,
            amountPaid: booking.amountPaid,
            notes: booking.notes,
            paymentStatusIndex: booking.paymentStatusIndex,
            roomUuid: booking.room.target?.uuid ?? '',
          )).toList();

      final clientExports = clients.map((client) => ClientExport(
            name: client.name,
            phone: client.phone,
            notes: client.notes,
          )).toList();

      // Создаем объект экспорта
      final databaseExport = DatabaseExport(
        version: currentVersion,
        exportDate: DateTime.now(),
        rooms: roomExports,
        bookings: bookingExports,
        clients: clientExports,
      );

      return databaseExport;
    } catch (e) {
      debugPrint('Ошибка при экспорте базы данных: $e');
      rethrow;
    }
  }

  /// Сохраняет экспортированные данные в файл
  Future<String?> saveExportFile(DatabaseExport databaseExport) async {
    try {
      // Преобразуем данные в JSON
      final jsonData = jsonEncode(databaseExport.toJson());

      // Выбираем путь для сохранения файла
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить экспорт базы данных',
        fileName: 'hotel_manager_export_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile == null) {
        // Пользователь отменил сохранение
        return null;
      }

      // Сохраняем данные в файл
      final file = File(outputFile);
      await file.writeAsString(jsonData);

      return outputFile;
    } catch (e) {
      debugPrint('Ошибка при сохранении файла экспорта: $e');
      rethrow;
    }
  }

  /// Импортирует данные из выбранного файла
  Future<bool> importFromFile() async {
    try {
      // Выбираем файл для импорта
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        // Пользователь отменил выбор файла
        return false;
      }

      final file = File(result.files.single.path!);
      final jsonData = await file.readAsString();

      return await importFromJson(jsonData);
    } catch (e) {
      debugPrint('Ошибка при импорте из файла: $e');
      return false;
    }
  }

  /// Импортирует данные из JSON строки
  Future<bool> importFromJson(String jsonData) async {
    try {
      // Парсим JSON
      final Map<String, dynamic> jsonMap = jsonDecode(jsonData);
      final databaseExport = DatabaseExport.fromJson(jsonMap);

      // Очищаем текущую базу данных
      await clearAllData();

      // Импортируем комнаты
      final rooms = databaseExport.rooms.map((roomExport) => Room(
            id: 0,
            uuid: roomExport.uuid,
            name: roomExport.name,
            type: roomExport.type,
            capacity: roomExport.capacity,
            basePrice: roomExport.basePrice,
            description: roomExport.description,
            status: RoomStatus.values[roomExport.statusIndex],
          )).toList();

      await _roomRepository.addRooms(rooms);

      // Импортируем клиентов
      final clients = databaseExport.clients.map((clientExport) => Client(
            id: 0,
            name: clientExport.name,
            phone: clientExport.phone,
            notes: clientExport.notes,
          )).toList();

      await _clientRepository.addClients(clients);

      // Импортируем бронирования
      final bookings = <Booking>[];

      for (final bookingExport in databaseExport.bookings) {
        // Находим комнату и клиента по UUID
        final room = await _roomRepository.getRoomByUuid(bookingExport.roomUuid);
        
        // Находим клиента по телефону
        final client = await _clientRepository.getClientByPhone(bookingExport.guestPhone);

        if (room != null) {
          final booking = Booking(
            id: 0,
            uuid: bookingExport.uuid,
            checkIn: DateTime.parse(bookingExport.checkIn),
            checkOut: DateTime.parse(bookingExport.checkOut),
            guestName: bookingExport.guestName,
            guestPhone: bookingExport.guestPhone,
            totalPrice: bookingExport.totalPrice,
            amountPaid: bookingExport.amountPaid,
            notes: bookingExport.notes,
            paymentStatus: PaymentStatus.values[bookingExport.paymentStatusIndex],
          );

          // Устанавливаем связи
          booking.room.target = room;

          bookings.add(booking);
        }
      }

      await _bookingRepository.addBookings(bookings);

      return true;
    } catch (e) {
      debugPrint('Ошибка при импорте из JSON: $e');
      return false;
    }
  }

  /// Очищает все данные в базе данных
  Future<bool> clearAllData() async {
    try {
      // Удаляем все бронирования
      await _bookingRepository.deleteAllBookings();

      // Удаляем всех клиентов
      await _clientRepository.deleteAllClients();

      // Удаляем все комнаты
      await _roomRepository.deleteAllRooms();

      return true;
    } catch (e) {
      debugPrint('Ошибка при очистке базы данных: $e');
      return false;
    }
  }

  /// Очищает все данные и восстанавливает начальные данные
  Future<bool> resetToInitialData() async {
    try {
      // Очищаем базу данных
      await clearAllData();
      
      // Добавляем начальные данные
      await _objectBox.addInitialData();
      
      return true;
    } catch (e) {
      debugPrint('Ошибка при сбросе базы данных: $e');
      return false;
    }
  }
}

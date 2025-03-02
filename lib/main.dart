import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_manager/database/repositories/booking_repository.dart';
import 'package:hotel_manager/database/repositories/client_repository.dart';
import 'package:hotel_manager/database/repositories/room_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/providers/database_provider.dart';
import 'database/objectbox.dart';
import 'features/home/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get the application documents directory
  final appDocDir = await getApplicationDocumentsDirectory();
  // Create a directory for our database
  final dbDirectory = path.join(appDocDir.path, 'objectbox');
  
  // Create the directory if it doesn't exist
  await Directory(dbDirectory).create(recursive: true);

  // Initialize ObjectBox
  final objectBox = await ObjectBox.create();

  runApp(
    ProviderScope(
      overrides: [
        roomRepositoryProvider.overrideWithValue(RoomRepository(objectBox)),
        bookingRepositoryProvider.overrideWithValue(BookingRepository(objectBox)),
        clientRepositoryProvider.overrideWithValue(ClientRepository(objectBox.store)),
        objectBoxProvider.overrideWithValue(objectBox),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Гостиница',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
    );
  }
}

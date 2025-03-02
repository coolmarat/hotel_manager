import 'package:flutter/material.dart';
import 'package:hotel_manager/core/localization/strings.dart';
import 'package:hotel_manager/features/calendar/presentation/calendar_screen.dart';
import 'package:hotel_manager/features/reports/presentation/reports_screen.dart';
import 'package:hotel_manager/features/rooms/presentation/rooms_screen.dart';
import 'package:hotel_manager/features/database/presentation/database_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    RoomsScreen(),
    CalendarScreen(),
    ReportsScreen(),
    DatabaseManagementScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.hotel),
      label: Strings.rooms,
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today),
      label: 'Календарь',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart),
      label: Strings.reports,
    ),
    NavigationDestination(
      icon: Icon(Icons.storage),
      label: 'База данных',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: _destinations,
      ),
    );
  }
}

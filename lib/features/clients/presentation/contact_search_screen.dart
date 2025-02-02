import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/repositories/client_repository.dart';
import '../../../database/models/client.dart';
import '../../../core/providers/database_provider.dart';

class ContactSearchScreen extends ConsumerStatefulWidget {
  const ContactSearchScreen({super.key});

  @override
  ConsumerState<ContactSearchScreen> createState() => _ContactSearchScreenState();
}

class _ContactSearchScreenState extends ConsumerState<ContactSearchScreen> {
  final _searchController = TextEditingController();
  List<Client> _filteredClients = [];
  late ClientRepository _clientRepository;

  @override
  void initState() {
    super.initState();
    _clientRepository = ref.read(clientRepositoryProvider);
    _updateSearch('');
  }

  void _updateSearch(String query) {
    setState(() {
      _filteredClients = _clientRepository.searchClients(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск контактов'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Поиск по имени или телефону',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _updateSearch,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredClients.length,
              itemBuilder: (context, index) {
                final client = _filteredClients[index];
                return ListTile(
                  title: Text(client.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.phone),
                      if (client.notes != null && client.notes!.isNotEmpty)
                        Text(
                          client.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context, client);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

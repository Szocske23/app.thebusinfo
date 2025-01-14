import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;


class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  _TicketsPageState createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final _storage = const FlutterSecureStorage();
  late Future<List<Map<String, dynamic>>> _ticketsFuture;

  Future<List<Map<String, dynamic>>> _fetchTickets() async {
    final accessToken = await _storage.read(key: 'access-token');
    final client = await _storage.read(key: 'client');
    final uid = await _storage.read(key: 'uid');
    final authorization = await _storage.read(key: 'authorization');

    if (accessToken == null || client == null || uid == null) {
      throw Exception('Missing authentication tokens.');
    }

    // Make API call to fetch tickets
    final response = await http.get(
      Uri.parse('https://api.thebus.info/v1/tickets'),
      headers: {
        'Authorization': 'Bearer $authorization',
        'client': client,
        'uid': uid,
        'access-token': accessToken,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch tickets: ${response.body}');
    }
  }

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _fetchTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Bilete',
                      style:  TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),),

      ),
      backgroundColor: Colors.black,
      body:
       FutureBuilder<List<Map<String, dynamic>>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No tickets found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final tickets = snapshot.data!;
          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return TicketCard(ticket: ticket);
            },
          );
        },
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const TicketCard({required this.ticket, Key? key}) : super(key: key);
  

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(25.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('La: ${ticket['end_stop_id']}', style: const TextStyle(color: Colors.white, fontSize: 20,fontWeight: FontWeight.bold,)),
            Text('De la: ${ticket['start_stop_id']}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Pe ruta: ${ticket['route_id']}', style: const TextStyle(color: Colors.white)),
            Text('Distance: ${ticket['distance']} km', style: const TextStyle(color: Colors.white)),
            Text('Price: ${ticket['price']} RON', style: const TextStyle(color: Colors.white)),
            Text('VAT: ${ticket['vat']} RON', style: const TextStyle(color: Colors.white)),
            Text('Pe data: ${DateTime.parse(ticket['sold_at'])}', style: const TextStyle(color: Colors.white)),

            
            
          ],
        ),
      ),
    );
  }
}
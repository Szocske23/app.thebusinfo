import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

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
        title: const Text(
          'Bilete',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: Container(
        // Add gradient background here
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
              colors: [
                Color.fromARGB(16, 0, 0, 0),
                Color.fromARGB(80, 27, 27, 27),
                Color(0x10000000),
              ],
              focal: FractionalOffset.bottomLeft,
              radius: 2,
              stops: [0.0, 0.5, 1.0],
              focalRadius: 0.2),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
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
        color: Colors.black,
        borderRadius: BorderRadius.circular(25.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${ticket['uid']}',
                      textAlign: TextAlign.end, // Align text to the left
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                        '${DateTime.parse(ticket['sold_at']).day}.${DateTime.parse(ticket['sold_at']).month}.${DateTime.parse(ticket['sold_at']).year}  ${DateTime.parse(ticket['sold_at']).hour}:${DateTime.parse(ticket['sold_at']).minute}',
                        style: const TextStyle(color: Colors.white12)),
                  ],
                )),
            const SizedBox(height: 15),
            SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ticket['start_stop_name']}',
                    textAlign: TextAlign.start, // Align text to the right
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFE2861D),
                          thickness: 1,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text('${ticket['service_name']}',
                          style: const TextStyle(
                              color: Color(0xFFE2861D),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(
                        width: 5,
                      ),
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFE2861D),
                          thickness: 1,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(5.0),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2861D),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x20e2861d),
                                spreadRadius: 2,
                                blurRadius: 20,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.busSimple,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
                  Text(
                    '${ticket['end_stop_name']}',
                    textAlign: TextAlign.start, // Align text to the left
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(
              color: Colors.white,
              thickness: 1,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text('Distance: ${ticket['distance']} km',
                style: const TextStyle(color: Colors.white)),
            Text('Price: ${ticket['price']} RON',
                style: const TextStyle(color: Colors.white)),
            Text('VAT: ${ticket['vat']} RON',
                style: const TextStyle(color: Colors.white)),
                  ],
                ),
                SizedBox(
              child: QrImageView(
                data: ticket['qr_code'],
                version: QrVersions.auto,
                size: 140.0,
                gapless: true,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Color(0xFFE2861D),
                ),
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFFE2861D),
                ),
                
              ),
            ),
              ],
            ),
            const SizedBox(height: 10),
            
          ]
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:barcode/barcode.dart';

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
      backgroundColor: Color(0xFF0A131F),
      body: 
      Stack(
        children: [
        //   Positioned.fill(
        //   child: Image.asset(
        //     'assets/bg_gradient.png', // Replace with your image path
        //     fit: BoxFit.cover, // Ensures the image covers the screen
        //   ),
        // ),
          Positioned(
            top: 80,
            left: 10,
            right: 10,
            bottom: 100, // Ensure the ListView doesn't overflow
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
                  padding: const EdgeInsets.only(bottom: 0),
                  reverse: true, // Makes the list start from the bottom
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return TicketCard(
                      ticket: ticket,
                      isLatest:
                          index == 0, // First item (latest) gets full details
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate back to the previous screen
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 10),
                    height: 60,
                    width: 60,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                      color: Colors.black,
                    ),
                    child: const Center(
                      child: Icon(
                        FontAwesomeIcons.chevronLeft,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    height: 60,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                      color: Colors.black,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Bilete",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool isLatest; // Determines if this is the latest ticket

  const TicketCard({required this.ticket, required this.isLatest, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final segments = ticket['segments_details'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(25.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: getColorFromHex(ticket['service_color'] ?? '#0000FF'),
                    ),
                    child: Text(
                      ticket['route_name'] ?? 'Unknown Route',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  Text(
                    '${ticket['price'] ?? '0.0'} RON',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...segments.map((segment) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            segment['start_stop_name'] ?? 'Unknown Start Stop',
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Departure: ${segment['departure'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                      const Icon(
                        FontAwesomeIcons.play,
                        size: 18,
                        color: Colors.white,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            segment['end_stop_name'] ?? 'Unknown End Stop',
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Arrival: ${segment['arrival'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }).toList(),
            if (isLatest) const SizedBox(height: 10),
            if (isLatest)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket['uid'] ?? 'Unknown UID',
                    style: const TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            if (isLatest)
              const Divider(
                color: Colors.white54,
                thickness: 1,
              ),
            if (isLatest) const SizedBox(height: 10),
            if (isLatest)
              GestureDetector(
                onTap: () {
                  // Show bottom sheet with enlarged QR code
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    backgroundColor: Colors.white,
                    builder: (context) => Center(
                      child: BarcodeWidgetModal(
                        data: ticket['qr_code'] ?? '',
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                      color: Colors.white,
                    ),
                    child: BarcodeWidget(
                      data: ticket['qr_code'] ?? '',
                    ),
                  ),
                ),
              ),
            if (isLatest) const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

class BarcodeWidget extends StatelessWidget {
  final String data;

  const BarcodeWidget({required this.data, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final barcode = Barcode.pdf417(
      moduleHeight: 2,
      securityLevel: Pdf417SecurityLevel.level1,
    );
    final svgString =
        barcode.toSvg(data, height: 100, width: 350, color: Colors.black.value);

    return SvgPicture.string(svgString, fit: BoxFit.contain);
  }
}

class BarcodeWidgetModal extends StatelessWidget {
  final String data;

  const BarcodeWidgetModal({required this.data, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final barcode = Barcode.aztec();
    final svgString = barcode.toSvg(
      data,
      color: Colors.black.value,
      height: MediaQuery.of(context).size.width * 0.8,
    );

    return SvgPicture.string(svgString, fit: BoxFit.contain);
  }
}






Color getColorFromHex(String hexColor) {
  try {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      return Color(int.parse("0xFF$hexColor"));
    }
    return Colors.blue;
  } catch (e) {
    return Colors.blue;
  }
}
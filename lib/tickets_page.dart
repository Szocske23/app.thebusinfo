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
      backgroundColor: Colors.white24,
      body: Stack(
        children: [
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Bilete",
                            style: const TextStyle(
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(25.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 5),
          SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      
                      'Valid pe: ${DateTime.parse(ticket['service_start_time']).day}.${DateTime.parse(ticket['service_start_time']).month}.${DateTime.parse(ticket['service_start_time']).year}',
                      
                      style: const TextStyle(color: Colors.white12)),
                ],
              )),
          const SizedBox(height: 10),
          SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue,
                      ),
                      child: Text(
                        ticket['route_name'],
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            ticket['start_stop_name'],
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                          const Icon(
                            FontAwesomeIcons.play,
                            size: 16,
                            color: Colors.white,
                          ),
                          Text(
                            ticket['end_stop_name'],
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Cumpara la: ${DateTime.parse(ticket['sold_at']).day}.${DateTime.parse(ticket['sold_at']).month}.${DateTime.parse(ticket['sold_at']).year} ${DateTime.parse(ticket['sold_at']).hour + 2}:${DateTime.parse(ticket['sold_at']).minute}',
                    style: const TextStyle(color: Colors.grey),
                  )
                ],
              ),
              Text('Pret: ${ticket['price']} RON',
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
          if (isLatest)
            const Divider(
              color: Colors.white10,
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
                      data: ticket['qr_code'],
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
                    data: ticket['qr_code'],
                  ),
                ),
              ),
            ),
          if (isLatest) const SizedBox(height: 5),
        ]),
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


Color hexStringToColor(String hexColor) {
  // Add opacity value if necessary or ensure it's a proper 6-character hex code
  final buffer = StringBuffer();
  if (hexColor.length == 6) {
    buffer.write('FF'); // Default to full opacity
  }
  buffer.write(hexColor);
  return Color(int.parse(buffer.toString(), radix: 16));
}

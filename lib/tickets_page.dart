import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:barcode/barcode.dart';
import 'package:intl/intl.dart';

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
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(14, 197, 197, 255),
            spreadRadius: 2,
            blurRadius: 20,
            offset: Offset(0, 0),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            
            // Header row with route and price
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${ticket['uid']}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  Text(
                    '${ticket['price'] ?? '0.0'} RON',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Main content row with dynamic segments
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  // Left side - departure
                  // Column(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Text(
                  //       extractTimeFromDate(ticket['sold_at']),
                  //       style: const TextStyle(
                  //         color: Colors.white,
                  //         fontSize: 14,
                  //       ),
                  //     ),
                  //     Text(
                  //       formatShortDate(ticket['sold_at']),
                  //       style: const TextStyle(
                  //         color: Colors.white54,
                  //         fontSize: 12,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  
                  const SizedBox(width: 10),
                  
                  // Dynamic segments in a row
                  Expanded(
                    child: Row(
                      children: [
                        for (int i = 0; i < segments.length; i++) ...[
                          // Add each segment
                          Expanded(
                            child: buildSegmentColumn(segments[i]),
                          ),
                          
                          // Add connector between segments if not the last one
                          if (i < segments.length - 1)
                            const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  
                  // Right side - VAT info
                  // Column(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     const Text(
                  //       'VAT',
                  //       style: TextStyle(
                  //         color: Colors.white54,
                  //         fontSize: 14,
                  //       ),
                  //     ),
                  //     Text(
                  //       '${ticket['vat'] ?? '0.0'} RON',
                  //       style: const TextStyle(
                  //         color: Colors.white,
                  //         fontSize: 14,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
            
            
            
            // Additional information section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                        'Sold at: ${formatFullDateTime(ticket['sold_at'])}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
              ],
            ),
            
            // QR code section for latest ticket
            if (isLatest) const SizedBox(height: 10),
            if (isLatest)
              const Divider(
                color: Colors.white54,
                thickness: 1,
              ),
            if (isLatest) const SizedBox(height: 10),
            if (isLatest && ticket['qr_code'] != null)
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
  
  // Build a single segment column with route name, divider, and duration
  Widget buildSegmentColumn(Map segment) {
  final routeColor = getColorFromHex(segment['route_color'] ?? '#0000FF');
  
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Route name
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          segment['route_name'] ?? 'Unknown Route',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ),
      
      // Color-coded divider
      Divider(
        color: routeColor,
        thickness: 2,
      ),
      
      // Start and end stops
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                segment['start_stop_name'],
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(
                FontAwesomeIcons.caretRight,
                color: Colors.white54,
                size: 12,
              ),
            ),
            Expanded(
              child: Text(
                segment['end_stop_name'],
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
  
  // Helper method to extract just the time from a datetime string
  String extractTimeFromDate(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '--:--';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '--:--';
    }
  }
  
  // Helper method to format date as "dd MMM" (e.g., "02 MAR")
  String formatShortDate(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '-- ---';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM').format(dateTime).toUpperCase();
    } catch (e) {
      return '-- ---';
    }
  }
  
  // Helper method for full date time formatting
  String formatFullDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }
  
  // Helper function to convert hex string to Color
  Color getColorFromHex(String hexColor) {
    // Add # if not present
    hexColor = hexColor.replaceAll('#', '');
    
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    
    return Color(int.parse(hexColor, radix: 16));
  }
  
  // Helper to get minimum of two integers
  int min(int a, int b) {
    return a < b ? a : b;
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
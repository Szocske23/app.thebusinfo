import 'dart:io'; // Import to check platform
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RoutePlannerPage extends StatefulWidget {
  final double? userLat;
  final double? userLon;
  final String? destinationName;
  final double? destinationLat;
  final double? destinationLon;

  RoutePlannerPage({
    this.userLat,
    this.userLon,
    this.destinationName,
    this.destinationLat,
    this.destinationLon,
  });

  @override
  _RoutePlannerPageState createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends State<RoutePlannerPage> {
  // Add any variables or methods related to route planning here
  DateTime selectedDateTime = DateTime.now();
  List<dynamic>? routes;
  bool isLoading = false; // Track loading state
  bool noRoutes = false; // Track if no routes are available

  @override
  void initState() {
    super.initState();
    _checkAndFetchRoute();
  }

  void _checkAndFetchRoute() {
    if (widget.userLat != null &&
        widget.userLon != null &&
        widget.destinationLat != null &&
        widget.destinationLon != null) {
      _fetchRoute();
    }
  }

  Future<void> _fetchRoute() async {
    setState(() {
      isLoading = true; // Show progress indicator
    });

    final String date = DateFormat('yyyy-MM-dd').format(selectedDateTime);

    // Make the API request
    final Uri url = Uri.parse(
      'https://api.thebus.info/v1/find-route?start_lat=${widget.userLat}&start_lon=${widget.userLon}&end_lat=${widget.destinationLat}&end_lon=${widget.destinationLon}&date=$date',
    );

    try {
      final response = await http.get(url);

      setState(() {
        isLoading = false; // Hide progress indicator once done
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          routes = data['routes']; // Store routes data
          noRoutes = false; // Reset noRoutes flag
          print(routes);
        });
      } else if (response.statusCode == 404) {
        // Handle 404 response (No service for that day)
        setState(() {
          routes = []; // No routes available
          noRoutes = true;
        });
        print("No service available for the selected date.");
      } else {
        // Handle other error codes
        throw Exception("Failed to load routes: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Hide progress indicator on error
      });
      print("Error fetching routes: $e");
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    if (Platform.isIOS) {
      // iOS Cupertino Picker
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 380,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 300,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: selectedDateTime,
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      selectedDateTime = newDateTime;
                    });
                  },
                ),
              ),
              CupertinoButton(
                child: Text("Done"),
                onPressed: () {
                  Navigator.pop(context);
                  _checkAndFetchRoute();
                },
              ),
            ],
          ),
        ),
      );
    } else {
      // Android Material Picker
      DateTime now = DateTime.now();

      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDateTime,
        firstDate: now,
        lastDate: DateTime(2100),
      );

      if (pickedDate == null) return;

      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );

      if (pickedTime == null) return;

      setState(() {
        selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 4, 4, 8),
      body: Stack(
        children: [
          //   Positioned.fill(
          //   child: Image.asset(
          //     'assets/bg_gradient.png', // Replace with your image path
          //     fit: BoxFit.cover, // Ensures the image covers the screen
          //   ),
          // ),
          if (routes == null && isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                color: Colors.white,
              ),
            ),
          if (noRoutes)
            const Center(
              child: Text(
                "Nu avem rute disponibile pentru această dată.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          if (routes != null && isLoading == false)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.transparent,
                height: 1000,
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: routes!.length,
                  itemBuilder: (context, index) {
                    final route = routes![index];

                    return route['transfers'] == 0
                        ? Container(
                            height: 80,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(14, 197, 197, 255),
                                  spreadRadius: 2,
                                  blurRadius: 20,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      route['departure_time'],
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          route["route"],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      color: Colors.blue,
                                      thickness: 2,
                                    )
                                  ],
                                )),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      route['arrival_time'],
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      route['price'] + 'Ron',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : Container(
                            height: 140,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(14, 197, 197, 255),
                                  spreadRadius: 2,
                                  blurRadius: 20,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 80,
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            route['first_leg']
                                                ['departure_time'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                route['first_leg']['route'],
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(
                                            color: Colors.blue,
                                            thickness: 2,
                                          )
                                        ],
                                      )),
                                      if (route['walk_distance'] > 0)
                                        const SizedBox(width: 10),
                                      if (route['walk_distance'] > 0)
                                        const SizedBox(
                                            width: 30,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                        FontAwesomeIcons
                                                            .personWalkingLuggage,
                                                        color: Colors.white70,
                                                        size: 18),
                                                  ],
                                                ),
                                                Divider(
                                                  color: Colors.grey,
                                                  thickness: 2,
                                                )
                                              ],
                                            )),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                route['second_leg']['route'],
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(
                                            color: Colors.blue,
                                            thickness: 2,
                                          )
                                        ],
                                      )),
                                      const SizedBox(width: 10),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            route['second_leg']['arrival_time'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Pret',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            route['first_leg']['price'] + 'Ron',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  color: Colors.white24,
                                  thickness: 1,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Column(
                                      children: [
                                        if (route['transfer_type'] ==
                                            'same_stop')
                                          const Text(
                                            'Schimbare la aceeași stație',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 14,
                                            ),
                                          ),
                                        if (route['transfer_type'] ==
                                            'same_stop')
                                          Text(
                                            route['transfer_stop'],
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 14,
                                            ),
                                          ),
                                        if (route['transfer_type'] == 'walk')
                                          Text(
                                            'Mers pe jos ${(route['walk_distance'] * 1000).toInt()}m',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 14,
                                            ),
                                          ),
                                        if (route['transfer_type'] == 'walk')
                                          Text(
                                            'intre statile ${route['first_leg']['end_stop']['name']} si ${route['second_leg']['start_stop']['name']}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ))
                                  ],
                                )
                              ],
                            ),
                          ); // or any other widget for routes with transfers
                  },
                ),
              ),
            ),
          Positioned(
            bottom: 100,
            left: 18,
            right: 18,
            child: Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(14, 197, 197, 255),
                    spreadRadius: 1,
                    blurRadius: 20,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "De la:",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.locationArrow,
                            color: Colors.white,
                          ),
                          Text(
                            "Locatia mea",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(
                    color: Colors.white10,
                    thickness: 1,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Pana la:",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.destinationName ?? "Destinație necunoscută",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            FontAwesomeIcons.mapPin,
                            color: Colors.white,
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
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
                  child: GestureDetector(
                    onTap: () => _selectDateTime(context),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(25)),
                        color: Colors.black,
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            FontAwesomeIcons.solidCalendar,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat("yyyy-MM-dd HH:mm")
                                .format(selectedDateTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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

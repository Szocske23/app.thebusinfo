import 'dart:convert';
import 'package:app_thebusinfo/route_planner_page.dart';
import 'package:app_thebusinfo/stop_details_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PoiDetailsPage extends StatefulWidget {
  final String poiUid;
  final String sessionToken;

  const PoiDetailsPage({Key? key, required this.poiUid, required this.sessionToken}) : super(key: key);
  

  @override
  _PoiDetailsPageState createState() => _PoiDetailsPageState();
}

class _PoiDetailsPageState extends State<PoiDetailsPage> {
  String? name;
  String? address;
  double? latitude;
  double? longitude;
  bool isLoading = true;
  String? errorMessage;
    List<Map<String, dynamic>> closestStops = [];

  @override
  void initState() {
    super.initState();
    fetchPoiDetails();
  }

  Future<void> _getClosestStops(longitude , latitude) async {
    

    // Correctly append query parameters to the URL
    final url = Uri.parse(
        'https://api.thebus.info/v1/stops/closest_stops?latitude=${latitude}&longitude=${longitude}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> responseData = json.decode(response.body);
        setState(() {
          closestStops = responseData.map((stop) {
            return {
              "id": stop["id"],
              "name": stop["name"],
              "city": stop["city"],
              "latitude": double.parse(stop["latitude"]),
              "longitude": double.parse(stop["longitude"]),
              "distance": stop["distance"], // Distance provided by the API
              "routes": stop["routes"] ?? [] // Map the routes correctly
            };
          }).toList();
        });
      } else {
        _showError('Failed to fetch closest stops: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching closest stops: $e');
    }
  }

  Future<void> fetchPoiDetails() async {
    final url = Uri.parse(
        'https://api.mapbox.com/search/searchbox/v1/retrieve/${widget.poiUid}?access_token=pk.eyJ1Ijoic3pvY3NrZTIzIiwiYSI6ImNtNGJkcGM5eDAybmwydnM0czQzZWk2dHkifQ.nQ4-b333bYND3Ra-912sog&session_token=${widget.sessionToken}');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['features'] != null && (data['features'] as List).isNotEmpty) {
          final feature = data['features'][0]; // Taking the first feature

          setState(() {
            name = feature['properties']['name'];
            address = feature['properties']['full_address'];

            if (feature['geometry']['coordinates'] is List) {
              longitude = feature['geometry']['coordinates'][0]?.toDouble();
              latitude = feature['geometry']['coordinates'][1]?.toDouble();
            }

            isLoading = false;
            _getClosestStops(longitude ,latitude );
          });
        } else {
          setState(() {
            errorMessage = "No POI details found.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Error: ${response.statusCode}, ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loader while loading
          : Stack(
              children: [
                MapWidget(
                  styleUri:
                      "mapbox://styles/szocske23/cm4brvrj900pb01r1eq8z9spy",
                  
                  cameraOptions: CameraOptions(
                    center: Point(
                      coordinates: Position(longitude!, latitude!),
                    ),
                    zoom: 15.4,
                    pitch: 28,
                    padding:
                        MbxEdgeInsets(top: 0, left: 0, bottom: 250, right: 0),
                  ),
                ),
                Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 90,
                child: PageView.builder(
                  itemCount: closestStops.length,
                  controller: PageController(viewportFraction: 0.88),
                  itemBuilder: (context, index) {
                    final stop = closestStops[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: _buildStopView(context, stop),
                    );
                  },
                ),
              ),
            ),
                // Stop name
            //     Positioned(
            //       bottom: 100,
            //       left: 20,
            //       right: 20,
            //       child: Container(
            // height: 90,
            
            // decoration: BoxDecoration(
            //   borderRadius: BorderRadius.circular(25),
            //   color: Colors.black,
            // ),
            // child: Text(address!)
            // ),),
                Positioned(
            top: 120,
            right: 0,
            child: GestureDetector(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  RoutePlannerPage(
                    userLat: 46.721737025815315, //test location
                    userLon: 25.594678321650797, // test location
                    destinationName: name,
                    destinationLat: latitude,
                    destinationLon: longitude,
                  )),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(25),
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
                      FontAwesomeIcons.route,
                      size: 25,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // Add spacing between sections
                      Row(
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
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25)),
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              height: 60,
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25)),
                                color: Colors.black,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "$name",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.fade
                                      ),
                                      overflow: TextOverflow.fade
                                    ),
                                  ],
                                ),
                              ),
                              
                            ),
                            
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

Widget _buildStopView(BuildContext context, Map<String, dynamic> stop) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StopDetailsPage(stopId: stop['id']),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20e2861d),
            spreadRadius: 2,
            blurRadius: 20,
            offset: Offset(0, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 15, top: 15, right: 20, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(
                  '${stop["name"]} - ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${stop["city"]}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
              Text(
                '${(stop["distance"] * 1000).toStringAsFixed(0)} m',
                // ignore: avoid_print

                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (stop["routes"] != null && stop["routes"].isNotEmpty)
            Row(
              children: [
                Container(
                  height: 28,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomRight: Radius.circular(4),
                      bottomLeft: Radius.circular(10),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: stop["routes"].map<Widget>((route) {
                      print(stop);
                      return Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.5,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue, // Fixed color for routes
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          route["name"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            )
          else
            const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  'No routes available',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
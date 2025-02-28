import 'dart:convert';
import 'package:app_thebusinfo/route_planner_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PoiDetailsPage extends StatefulWidget {
  final String poiUid;
  final String sessionToken;

  const PoiDetailsPage(
      {Key? key, required this.poiUid, required this.sessionToken})
      : super(key: key);

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
  PointAnnotationManager? pointAnnotationManager;

  @override
  void initState() {
    super.initState();
    fetchPoiDetails();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    // Create a point annotation manager
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    
    // Create a point annotation options
    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(coordinates: Position(longitude!, latitude!)),
      iconSize: 1.3,
      iconImage: "mapbox-cross" // You need to add a marker image to your assets
    );
    
    // Add the point annotation to the map
    await pointAnnotationManager?.create(pointAnnotationOptions);
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
                    zoom: 16.4,
                    pitch: 60,
                    padding:
                        MbxEdgeInsets(top: 0, left: 0, bottom: 250, right: 0),
                        
                  ),
                  onMapCreated: (MapboxMap mapboxMap) {
                    _onMapCreated(mapboxMap);
                  },
                ),
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    height: 90,
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
                      padding: const EdgeInsets.only(
                          left: 15, top: 15, right: 20, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Text(
                                  "$name",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (address != null)
                            Text(
                              "$address",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
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
                            child: GestureDetector(
                              onTap: () {
                                // Navigate back to the previous screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RoutePlannerPage(
                                            userLat:
                                                46.721737025815315, //test location
                                            userLon:
                                                25.594678321650797, // test location
                                            destinationName: name,
                                            destinationLat: latitude,
                                            destinationLon: longitude,
                                          )),
                                );
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                height: 60,
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25)),
                                  color: Colors.black,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text("Take me there !",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              overflow: TextOverflow.fade),
                                          overflow: TextOverflow.fade),
                                    ],
                                  ),
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



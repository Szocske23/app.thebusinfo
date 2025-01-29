import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;

class ServiceDetails extends StatefulWidget {
  final int serviceId;
  final int stopId;

  const ServiceDetails(
      {Key? key, required this.serviceId, required this.stopId})
      : super(key: key);

  @override
  _ServiceDetailsState createState() => _ServiceDetailsState();
}

class _ServiceDetailsState extends State<ServiceDetails> {
  MapboxMap? mapboxMap;
  late bool isLoading;
  late List stops;
  late String polyLine;
  late String serviceName;
  late String serviceDescription;
  

  @override
  void initState() {
    super.initState();
    isLoading = true;
    stops = [];
    polyLine = '';
    serviceName = '';
    serviceDescription = '';
   
    fetchStopDetails();
  }

  Future<void> fetchStopDetails() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.thebus.info/v1/services/detailed?service_id=${widget.serviceId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          serviceName = data['service']['name'];
          serviceDescription = data['service']['description'];
          stops = data['stops'];
          polyLine = data['service']['geojson'];
          isLoading = false;
          
        });
        print('Service Details: $data'); // Log response for debugging
      } else {
        throw Exception(
            'Failed to load stop details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching stop details: $e'); // Log error for debugging
      throw Exception('Failed to fetch stop details');
    }
  }

  Future<void> _addRouteLines() async {
    try {
      if (polyLine.isNotEmpty) {
        // Decode the polyline and get coordinates, center, and zoom
        var decodedData = decodePolylineWithCenterAndZoom(polyLine);
        if (decodedData.isNotEmpty) {
          List<List<double>> decodedPoints = decodedData[0]['coordinates'];
          double centerLat = decodedData[0]['center'][0];
          double centerLng = decodedData[0]['center'][1];
          double zoom = decodedData[0]['zoom'];

          // Convert decoded points to the format required by Mapbox
          List<List<double>> routeCoordinates = decodedPoints;

          // Prepare GeoJSON for the route lines
          final routesGeoJson = {
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "geometry": {
                  "type": "LineString",
                  "coordinates": routeCoordinates,
                },
                "properties": {
                  "name": serviceName,
                  "description": serviceDescription,
                },
              },
            ],
          };
          print(routesGeoJson);

          final stopsGeoJson = {
            "type": "FeatureCollection",
            "features": stops.map((stop) {
              return {
                "type": "Feature",
                "geometry": {
                  "type": "Point",
                  "coordinates": [
                    double.parse(stop['longitude']).toStringAsFixed(6),
                    double.parse(stop['latitude']).toStringAsFixed(6)
                  ],
                },
                "properties": {
                  "name": stop['stop_name'],
                },
              };
            }).toList(),
          };

          // Add GeoJSON source for the route lines
          await mapboxMap?.style.addSource(GeoJsonSource(
            id: 'route-line-source',
            data: json.encode(routesGeoJson),
          ));

          await mapboxMap?.style.addSource(GeoJsonSource(
            id: 'stop-route-source', // Source ID
            data: json.encode(stopsGeoJson),
          ));

          // Add a layer for the route lines
          await mapboxMap?.style.addLayer(LineLayer(
            id: 'route-line-layer',
            sourceId: 'route-line-source',
            lineColor: const Color(0xFFE2861D).value,
            lineWidth: 4,
            lineColorExpression: [2, 2],
            lineEmissiveStrength: 1,
            lineOpacity: 1,
          ));

          await mapboxMap?.style.addLayer(CircleLayer(
            id: 'stop-layer',
            sourceId: 'stop-route-source',
            circleColor: const Color(0xFFE2861D).value,
            circleRadius: 5,
          ));

          // Set camera position (center and zoom)
          print(zoom);
          await mapboxMap?.flyTo(
            CameraOptions(
              center: Point(
                coordinates: Position(centerLng, centerLat),
              ),
              zoom: zoom,
            ),
            MapAnimationOptions(duration: 500),
          );

          print('Route line added successfully');
        } else {
          print('No coordinates decoded from polyline');
        }
      } else {
        print('No routes found in the response');
      }
    } catch (e) {
      _showError('Error adding route lines: $e');
    }
  }

  List<Map<String, dynamic>> decodePolylineWithCenterAndZoom(String encoded) {
    List<List<double>> coordinates = [];
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      // Decode latitude
      while (true) {
        if (index >= encoded.length) {
          print('Invalid polyline format: Latitude decoding failed');
          return [];
        }
        int b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
        if (b < 0x20) break;
      }
      int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;

      // Decode longitude
      while (true) {
        if (index >= encoded.length) {
          print('Invalid polyline format: Longitude decoding failed');
          return [];
        }
        int b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
        if (b < 0x20) break;
      }
      int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      // Convert to actual latitude/longitude and store coordinates
      double latDecoded = lat / 1e6;
      double lngDecoded = lng / 1e6;

      coordinates.add([lngDecoded, latDecoded]);

      // Update bounding box
      minLat = min(minLat, latDecoded);
      maxLat = max(maxLat, latDecoded);
      minLng = min(minLng, lngDecoded);
      maxLng = max(maxLng, lngDecoded);
    }

    // Calculate center of the polyline (average of the bounding box)
    double centerLat = (minLat + maxLat) / 2;
    double centerLng = (minLng + maxLng) / 2;

    // Calculate zoom level based on the bounding box size
    double zoom = calculateZoomLevel(minLat, maxLat, minLng, maxLng);

    // Return the decoded coordinates, center, and zoom as a map
    return [
      {
        'coordinates': coordinates,
        'center': [centerLat, centerLng],
        'zoom': zoom
      }
    ];
  }

  double calculateZoomLevel(
      double minLat, double maxLat, double minLng, double maxLng) {
    double latDiff = maxLat - minLat;
    double lonDiff = maxLng - minLng;

    // Calculate the larger difference between latitude and longitude
    double maxDiff = max(latDiff, lonDiff);

    // Apply a logarithmic scale to the maxDiff for more precision
    // Reduce the scaling factor (making the zoom less intense) to show more area
    double zoom =
        8 - log(maxDiff) / log(2); // Adjust 16 to be less zoomed in by default

    // Ensure the zoom is within a valid range (e.g., between 10 and 16)
    zoom =
        zoom.clamp(6.0, 16.0); // Increase the minimum zoom for a better display

    // Round the zoom level to two decimals for precision
    return double.parse(zoom.toStringAsFixed(2));
  }

  

  

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    if (!isLoading) {
      await _addRouteLines();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$serviceName", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loader while loading
          : Stack(
              children: [
                MapWidget(
                  styleUri:
                      "mapbox://styles/szocske23/cm4brvrj900pb01r1eq8z9spy",
                  onMapCreated: (MapboxMap controller) {
                    mapboxMap = controller;
                    _onMapCreated(controller);
                  },
                  cameraOptions: CameraOptions(
                    center: Point(
                      coordinates: Position(
                        24.9668, // Default longitude
                        45.9432,
                      ),
                    ),
                    zoom: 6,
                    pitch: 0,
                    padding:
                        MbxEdgeInsets(top: 0, left: 0, bottom: 460, right: 0),
                  ),
                ),

                // Overlay content

                Positioned(
                  bottom: 350,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 90,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                       Radius.circular(25),
                        
                      ),
                      color: Colors.black,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                      serviceName ,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                        Text(
                          serviceDescription ,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                      ],
                    )
                    
                    
                  ),
                ),
                
             
              ],
            ),
    );
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

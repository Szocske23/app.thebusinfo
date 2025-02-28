import 'dart:async';
import 'dart:convert';
import 'package:app_thebusinfo/poi_details_page.dart';
import 'package:app_thebusinfo/route_planner_page.dart';
import 'package:app_thebusinfo/settings_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'stop_details_page.dart';
import 'tickets_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'signin_page.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<bool> validateToken() async {
  final tokens = await AuthStorage.getTokens();

  if (tokens['access-token'] == null ||
      tokens['client'] == null ||
      tokens['uid'] == null ||
      tokens['authorization'] == null) {
    return false;
  }

  final response = await http.get(
    Uri.parse('https://api.thebus.info/auth/validate_token'),
    headers: {
      'Authorization': 'Bearer ${tokens['authorization']}',
      'access-token': tokens['access-token']!,
      'client': tokens['client']!,
      'uid': tokens['uid']!,
    },
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveTokens({
    required String accessToken,
    required String client,
    required String uid,
    required String authorization,
  }) async {
    await _storage.write(key: 'access-token', value: accessToken);
    await _storage.write(key: 'client', value: client);
    await _storage.write(key: 'uid', value: uid);
    await _storage.write(key: 'authorization', value: authorization);
  }

  static Future<Map<String, String?>> getTokens() async {
    final accessToken = await _storage.read(key: 'access-token');
    final client = await _storage.read(key: 'client');
    final uid = await _storage.read(key: 'uid');
    final authorization = await _storage.read(key: 'authorization');
    return {
      'access-token': accessToken,
      'client': client,
      'uid': uid,
      'authorization': authorization,
    };
  }

  static Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}



class _HomeScreenState extends State<HomeScreen> {
  late MapboxMap mapboxMap;
  final Location location = Location();
  final _storage = const FlutterSecureStorage();

  // ignore: unused_field
  LocationData? _currentLocation;
  PointAnnotationManager? pointAnnotationManager;
  List<Map<String, dynamic>> stops = [];
  List<Map<String, dynamic>> closestStops = [];
  Timer? debounceTimer;
  PointAnnotation? locationIndicator; // Custom location marker
  String mapboxSessionToken =
      const Uuid().v4(); // Generate and store a session token

  List<Map<String, dynamic>> searchStops = [];
  List<Map<String, dynamic>> searchCityes = [];
  List<Map<String, dynamic>> searchPois = [];
  TextEditingController searchController = TextEditingController();
  String appVersion = "Loading...";
  String appBuildNumber = "Loading...";

  static const String stopsApiUrl = 'https://api.thebus.info/v1/stops';

  bool isCameraUpdated = false;
  @override
  void dispose() {
    debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchAppInfo();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // Retrieve tokens from secure storage
      final accessToken = await _storage.read(key: 'access-token');
      final uid = await _storage.read(key: 'uid');
      final client = await _storage.read(key: 'client');
      final authorization = await _storage.read(key: 'authorization');

      if (accessToken == null || uid == null || client == null) {
        _showSnackBar(context, 'Missing authentication tokens.');
        return;
      }

      // Make the sign-out API call
      final response = await http.delete(
        Uri.parse('https://api.thebus.info/auth/sign_out'),
        headers: {
          'Authorization': 'Bearer $authorization',
          'access-token': accessToken,
          'client': client,
          'uid': uid,
        },
      );

      if (response.statusCode == 200) {
        // Navigate to login or welcome page on successful sign-out
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _showSnackBar(context, 'Failed to sign out. Please try again.');
      }
    } catch (e) {
      _showSnackBar(context, 'An error occurred: $e');
    }
  }
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    await _initializeLocationTracking();
    await _fetchStops();

    // await _addStopsAsLayer();
    await _addStopClusters();
  }

  late Uint8List imageData;

  Future<void> _fetchStops() async {
    try {
      final response = await http.get(Uri.parse(stopsApiUrl));
      if (response.statusCode == 200) {
        List<dynamic> responseData = json.decode(response.body);
        setState(() {
          stops = responseData.map((stop) {
            return {
              "id": stop["id"],
              "name": stop["name"],
              "latitude": double.parse(stop["latitude"]),
              "longitude": double.parse(stop["longitude"]),
              "route_id": stop["route_id"],
            };
          }).toList();
        });
      } else {
        _showError('Failed to fetch stops: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching stops: $e');
    }
  }

  

  Future<void> _getClosestStopsFromAPI(LocationData currentLocation) async {
    if (currentLocation.latitude == null || currentLocation.longitude == null) {
      _showError('Invalid location data.');
      return;
    }

    // Correctly append query parameters to the URL
    final url = Uri.parse(
        'https://api.thebus.info/v1/stops/closest_stops?latitude=${currentLocation.latitude}&longitude=${currentLocation.longitude}');

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

  Future<void> _addStopClusters() async {
    final Brightness brightnessValue =
        MediaQuery.of(context).platformBrightness;
    bool isDark = brightnessValue == Brightness.dark;
    try {
      // Prepare GeoJSON data for stops
      final stopsGeoJson = {
        "type": "FeatureCollection",
        "features": stops.map((stop) {
          return {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [stop['longitude'], stop['latitude']],
            },
            "properties": {
              "name": stop['name'],
            },
          };
        }).toList(),
      };

      // Add GeoJSON source with clustering enabled
      await mapboxMap.style.addSource(GeoJsonSource(
        id: 'stop-cluster-source', // Source ID
        data: json.encode(stopsGeoJson),
        cluster: true,
        clusterRadius: 40, // Radius for clustering
        clusterMaxZoom: 14.6, // Maximum zoom to cluster points
        tolerance: 0.0, // Tolerance for clustering
      ));

      // Add a layer for clusters
      await mapboxMap.style.addLayer(SymbolLayer(
        id: 'cluster-layer',
        sourceId: 'stop-cluster-source',
        filter: ['has', 'point_count'],
        iconImage: "bus-cluster",
        iconSize: 0.12,
        textField: '{point_count}',
        textOffset: [0.0, 0.0],
        textSize: 16,
        textMaxWidth: 20,
        iconAllowOverlap: true,
        textColor: const Color(0xFFE2861D).value,
      ));

      // Add a layer for individual points (non-clustered)
      await mapboxMap.style.addLayer(SymbolLayer(
        id: 'stop-layer',
        sourceId: 'stop-cluster-source',
        filter: [
          '!',
          ['has', 'point_count']
        ],
        iconImage: "bus-stop",
        iconAnchor: IconAnchor.BOTTOM,
        iconSize: 0.08,
        textField: '{name}',
        textOffset: [0.0, 1.2],
        textColor: isDark
            ? const Color(0xFFFFFFFF).value
            : const Color(0xFF000000).value,
        textSize: 10,
        iconKeepUpright: true,
        iconAllowOverlap: true,
      ));
    } catch (e) {
      _showError('Error adding stop clusters: $e');
    }
  }

  Future<void> _initializeLocationTracking() async {
    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) return;
    }

    if (await location.hasPermission() == PermissionStatus.denied) {
      if (await location.requestPermission() != PermissionStatus.granted) {
        return;
      }
    }

    location.onLocationChanged.listen((LocationData currentLocation) {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(seconds: 0), () async {
        _currentLocation = currentLocation;
        await _getClosestStopsFromAPI(currentLocation);
        if (!isCameraUpdated) {
          _updateCamera(currentLocation);
          isCameraUpdated =
              true; // Set the flag to true after updating the camera
        }
      });
    });
  }

  Future<void> fetchSearchResults(String query) async {
    if (query.length < 3) {
      searchStops = [];
      searchCityes = [];
      searchPois = [];
      return;
    }

    try {
      final response = await http.get(Uri.https(
        'api.thebus.info',
        '/v1/search',
        {
          'query': query,
          'mapbox_session_token': mapboxSessionToken
        }, // Include session token
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          searchStops = List<Map<String, dynamic>>.from(data['stops']);
          print(searchStops);
          searchCityes = List<Map<String, dynamic>>.from(data['cities']);
          print(searchCityes);
          searchPois = List<Map<String, dynamic>>.from(data['pois']);
          print(searchPois);
        });
      }
    } catch (e) {
      print(e);
      _showError('Search failed: $e');
    }
  }

  Future<void> _updateCamera(LocationData locationData) async {
    if (locationData.latitude != null && locationData.longitude != null) {
      mapboxMap.location.updateSettings(LocationComponentSettings(
          puckBearingEnabled: true,
          showAccuracyRing: true,
          accuracyRingBorderColor: Color.fromARGB(255, 0, 21, 255).value,
          accuracyRingColor: const Color.fromARGB(100, 255, 235, 59).value,
          puckBearing: PuckBearing.HEADING,
          locationPuck: LocationPuck(
              locationPuck3D: LocationPuck3D(
            modelCastShadows: true,
            modelScale: [18, 18, 18],
            modelRotation: [0, 0, -108],
            modelReceiveShadows: true,
            modelEmissiveStrength: 4,
            modelUri:
                "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Embedded/Duck.gltf",
          ))));
      mapboxMap.flyTo(
        CameraOptions(
            center: Point(
              coordinates:
                  Position(locationData.longitude!, locationData.latitude!),
            ),
            zoom: 16,
            pitch: 34,
            padding: MbxEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
      appBuildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
                center: Point(
                  coordinates: Position(
                    24.9668, // Default longitude
                    45.9432, // Default latitude
                  ),
                ),
                zoom: 5,
                padding: MbxEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)),
            styleUri: "mapbox://styles/szocske23/cm4brvrj900pb01r1eq8z9spy",
            textureView: true,
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            top: 50,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // Show bottom sheet instead of navigating to a new page
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: false,
                  showDragHandle: true,
                  backgroundColor: Color(0xFF0A131F),
                  isDismissible: true,
                  scrollControlDisabledMaxHeightRatio: 0.8,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(45)),
                                ),
                  builder: (context) => _buildSettingsBottomSheet(
                      context, appVersion, appBuildNumber,  _signOut), // Pass the function here),
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
                      FontAwesomeIcons.gear,
                      size: 25,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
              bottom: 20,
              left: 0,
              right: 70,
              child: Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    height: 60,
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
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.mapLocationDot,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Cauta destinatie...',
                              border: InputBorder.none,
                            ),
                            onChanged: fetchSearchResults,
                            keyboardType: TextInputType.text,
                            keyboardAppearance: Brightness.dark,
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (searchStops.isNotEmpty ||
                                searchCityes.isNotEmpty ||
                                searchPois.isNotEmpty) {
                              // Clear the search results
                              setState(() {
                                searchStops.clear();
                                searchCityes.clear();
                                searchPois.clear();
                                searchController.clear();
                              });
                            } else {
                              // Add logic for submitting the search if needed
                              print('Search icon pressed');
                            }
                          },
                          icon: Icon(
                            (searchStops.isNotEmpty ||
                                    searchCityes.isNotEmpty ||
                                    searchPois.isNotEmpty)
                                ? Icons
                                    .close // X icon when search results exist
                                : FontAwesomeIcons
                                    .magnifyingGlass, // Search icon when no results
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ))),
          Positioned(
            bottom: 20,
            right: 0,
            child: GestureDetector(
              onTap: () async {
                final isValid = await validateToken();

                if (isValid) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TicketsPage()),
                  );
                } else {
                  // Redirect to Sign In or Register page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                  );
                }
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
                      FontAwesomeIcons.qrcode,
                      size: 25,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (searchStops.isNotEmpty ||
              searchCityes.isNotEmpty ||
              searchPois.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              // Adjust the height as needed to fit all cards
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (searchStops.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: PageView.builder(
                          itemCount: searchStops.length,
                          controller: PageController(viewportFraction: 0.9),
                          itemBuilder: (context, index) {
                            final stop = searchStops[index];
                            return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 7),
                                child: _buildSearchCard(
                                    stop, 'Stop', context, mapboxSessionToken));
                          },
                        ),
                      ),
                    if (searchCityes.isNotEmpty) const SizedBox(height: 10),
                    if (searchCityes.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: PageView.builder(
                          itemCount: searchCityes.length,
                          controller: PageController(viewportFraction: 0.9),
                          itemBuilder: (context, index) {
                            final city = searchCityes[index];
                            return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 7),
                                child: _buildSearchCard(
                                    city, 'City', context, mapboxSessionToken));
                          },
                        ),
                      ),
                    if (searchPois.isNotEmpty) const SizedBox(height: 10),
                    if (searchPois.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: PageView.builder(
                          itemCount: searchPois.length,
                          controller: PageController(viewportFraction: 0.9),
                          itemBuilder: (context, index) {
                            final poi = searchPois[index];

                            return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 7),
                                child: _buildSearchCard(
                                    poi, 'POI', context, mapboxSessionToken));
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (searchStops.isEmpty && searchCityes.isEmpty && searchPois.isEmpty)
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
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.88 -
                    110, // Adjusted for padding  // Ensures Row has a bounded width
                child: Row(
                  children: [
                    Text(
                      '${stop["name"]} - ', // Stop name always fully visible
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment
                            .centerLeft, // Ensures proper fading effect
                        child: Text(
                          '${stop["city"]}', // City fades if too long
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

Color hexStringToColor(String hexColor) {
  // Add opacity value if necessary or ensure it's a proper 6-character hex code
  final buffer = StringBuffer();
  if (hexColor.length == 6) {
    buffer.write('FF'); // Default to full opacity
  }
  buffer.write(hexColor);
  return Color(int.parse(buffer.toString(), radix: 16));
}

Widget _buildSearchCard(dynamic item, String type, BuildContext context,
    String mapboxSessionToken) {
  return GestureDetector(
    onTap: () {
      if (type == 'Stop') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StopDetailsPage(stopId: item['id']),
          ),
        );
      }
      if (type == 'POI') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PoiDetailsPage(
                sessionToken: mapboxSessionToken, poiUid: item['id']),
          ),
        );
      }
      ;
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
                if (type == 'Stop')
                  const Icon(
                    FontAwesomeIcons.busSimple,
                    color: Colors.white,
                    size: 20,
                  ),
                if (type == 'Stop')
                  const SizedBox(
                    width: 6,
                  ),
                Text(
                  '${item["name"]}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.fade,
                ),
                if (type == 'Stop')
                  Text(
                    ' - ${item["city"]}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      overflow: TextOverflow.ellipsis,
                    ),
                    overflow: TextOverflow.fade,
                  ),
              ]),
              if (type == 'POI')
                const Icon(
                  FontAwesomeIcons.mapLocationDot,
                  color: Colors.white,
                  size: 25,
                ),
              if (type == 'City')
                const Icon(
                  FontAwesomeIcons.city,
                  color: Colors.white,
                  size: 25,
                )
            ],
          ),
          const SizedBox(height: 8),
          if (type == 'POI')
            Text(
              item["address"],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          if (type == 'City')
            Text(
              item["zipcode"],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          if (type == 'Stop')
            if (item["routes"] != null && item["routes"].isNotEmpty)
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
                      children: item["routes"].map<Widget>((route) {
                        print(item);
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
                            route['name'],
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
  // child: Container(
  //   width: 150, // Adjust size based on your design
  //   decoration: BoxDecoration(
  //     borderRadius: BorderRadius.circular(25),
  //     color: Colors.black,
  //   ),
  //   child: ElevatedButton(
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: Colors.transparent,
  //       padding: const EdgeInsets.all(10),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(15),
  //       ),
  //     ),
  //     onPressed: () {

  //       print('$type card pressed: ${item['name']}');
  //     },
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Text(
  //           item['name'] ?? 'Unknown $type',
  //           style: const TextStyle(color: Colors.white),
  //         ),
  //         if (type == 'POI')
  //           Text(
  //             item['address'] ?? 'No address available',
  //             style: const TextStyle(color: Colors.white),
  //           ),
  //       ],
  //     ),
  //   ),
  // ),
}

Widget _buildSettingsBottomSheet(
    BuildContext context, String appVersion, String appBuildNumber,Future<void> Function(BuildContext) onSignOut,) {
  
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A131F),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [


            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 170,
                  width: 170,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(padding: const EdgeInsets.all(10),
                  child:  ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child:
                  const Image(image: AssetImage('assets/lightView.png',
                  ),
                  )
                  ),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  height: 170,
                  width: 170,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.white70,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(padding: const EdgeInsets.all(10),
                  child:  ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child:
                  const Image(image: AssetImage('assets/darkView.png',
                  ),
                  )
                  ),
                  ),
                ),

              ],
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                
              },
              child: Container(
               height: 60,
               width: MediaQuery.of(context).size.width - 40,
               decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(25),
                  ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.signOutAlt,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'IDK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                
              },
              child: Container(
               height: 60,
               width: MediaQuery.of(context).size.width - 40,
               decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(25),
                  ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.signOutAlt,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'IDK2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
            await onSignOut(context); // Call the passed sign-out function
          },
              child: Container(
               height: 60,
               width: MediaQuery.of(context).size.width - 40,
               decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(25),
                  ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.signOutAlt,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ),
            
            Expanded(child: Text('expanded')),
            // Drag handle
            
            // Settings title
            
            // Version info
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Version $appVersion (Build $appBuildNumber)",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "© 2025 Prosoft.plus",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20,)
          ],
        ),
      );
    }
 
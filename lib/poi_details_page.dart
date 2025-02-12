import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PoiDetailsPage extends StatefulWidget {
  final String poiUid;
  final String sessionToken;

  const PoiDetailsPage({Key? key, required this.poiUid, required this.sessionToken}) : super(key: key);

  @override
  _PoiDetailsPageState createState() => _PoiDetailsPageState();
}

class _PoiDetailsPageState extends State<PoiDetailsPage> {
  String? responseText;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPoiDetails();
  }

  Future<void> fetchPoiDetails() async {
    final url = Uri.parse(
        'https://api.mapbox.com/search/searchbox/v1/retrieve/${widget.poiUid}?access_token=pk.eyJ1Ijoic3pvY3NrZTIzIiwiYSI6ImNtNGJkcGM5eDAybmwydnM0czQzZWk2dHkifQ.nQ4-b333bYND3Ra-912sog&session_token=${widget.sessionToken}');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          responseText = jsonEncode(jsonDecode(response.body));
          isLoading = false;
        });
      } else {
        setState(() {
          responseText = 'Error: ${response.statusCode}, ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        responseText = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POI Details'),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Text(
                    responseText ?? 'No data',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'routes_screen.dart'; // Import the RoutesScreen


class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (Placeholder for Map or other content)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200], // Placeholder for map background
            child: Center(
              child: Text(
                'Map will appear here.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Custom Floating Bar
          Positioned(
            bottom: 6,
            left: 6,
            right: 6,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white, // Semi-transparent
                  borderRadius: BorderRadius.circular(38),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.solidMap, color: Colors.black, size: 20,),
                      onPressed: () {
                        // Action for Home button
                      },
                    ),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.busSimple, color: Colors.black, size: 20,),
                      onPressed: () {
                         // Navigate to Routes screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RoutesScreen()),
                        );
                      },
                    ),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.ticket, color: Colors.black, size: 20,),
                      onPressed: () {
                        // Action for Bus Routes button
                      },
                    ),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.solidUser, color: Colors.black, size: 20,),
                      onPressed: () {
                        // Action for Profile button
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
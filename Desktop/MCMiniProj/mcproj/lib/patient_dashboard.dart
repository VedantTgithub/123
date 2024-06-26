import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sensors/sensors.dart'; // Import the sensors package
import 'DetailsPage.dart';
import 'DietPage.dart';
import 'FormPage.dart';
import 'UploadPage.dart';
import 'LoginPage.dart';

class PatientDashboard extends StatefulWidget {
  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _formData = [];
  double _tiltThreshold = 20.0; // Set the tilt angle threshold

  @override
  void initState() {
    super.initState();
    // Fetch form data from Firestore when the widget initializes
    _fetchFormData();
    // Start listening to accelerometer data
    accelerometerEvents.listen((AccelerometerEvent event) {
      // Check if the phone is tilted beyond the threshold
      if (event.z.abs() > _tiltThreshold) {
        // Display pop-up message
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Stop tilting!'),
              content: Text('Please do not tilt your device too much.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  void _fetchFormData() async {
    // Get the current user's UID
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Fetch form data from Firestore
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(uid)
        .collection('data')
        .get();

    // Store form data in the _formData list
    setState(() {
      _formData = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _logout(); // Call logout function on button press
            },
          ),
        ],
      ),
      body: ListView(
        children: _formData.map((data) {
          return _buildCard(data);
        }).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        elevation: 8,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              // No need to navigate if already on the PatientDashboard
              break;
            case 1:
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => FormPage(),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                        reverseCurve: Curves.easeInOut,
                      )),
                      child: child,
                    );
                  },
                  transitionDuration: Duration(milliseconds: 500),
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ImageUploadPage()),
              ).then((value) => setState(() {
                    _currentIndex = 0;
                  }));
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DietPage()),
              ).then((value) => setState(() {
                    _currentIndex = 0;
                  }));
              break;
          }
        },
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Form',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_upload),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Diet Page',
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsPage(data: data),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: ${data['date']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Blood Pressure: ${data['blood_pressure']}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Heart Rate: ${data['heart_rate']}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Body Temperature: ${data['body_temperature']}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Glucose Level: ${data['glucose_level']}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'BMI: ${data['bmi']}',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              LoginPage()), // Navigate to LoginPage after logout
    );
  }
}

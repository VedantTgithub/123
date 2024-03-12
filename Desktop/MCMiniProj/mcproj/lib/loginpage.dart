import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registration.dart';
import 'patient_dashboard.dart'; // Import the patient dashboard page
import 'doctor_dashboard.dart'; // Import the doctor dashboard page
import 'package:local_auth/local_auth.dart'; // Import local_auth package

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication _localAuth =
      LocalAuthentication(); // Create an instance of LocalAuthentication

  @override
  void initState() {
    super.initState();
    _authenticate(); // Call biometric authentication when the page loads
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason:
            'Authenticate to access the app', // Reason for authentication
      );
    } catch (e) {
      print('Error authenticating: $e');
    }

    if (authenticated) {
      // Biometric authentication successful, proceed to login
      _login();
    } else {
      // Biometric authentication failed
      // You can choose to handle this case as per your requirement
      print('Biometric authentication failed');
    }
  }

  void _login() async {
    try {
      UserCredential authResult = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = authResult.user;

      if (user != null) {
        // Retrieve user role from Firestore
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(user.uid)
            .get();
        String role = userDoc['role'];

        // Redirect based on the user's role
        switch (role) {
          case 'Patient':
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration:
                    Duration(milliseconds: 1000), // Increased duration
                pageBuilder: (_, __, ___) => RotationTransition(
                  turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: __,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: PatientDashboard(), // Your patient dashboard widget
                ),
              ),
            );
            break;
          case 'Doctor':
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration:
                    Duration(milliseconds: 1000), // Increased duration
                pageBuilder: (_, __, ___) => RotationTransition(
                  turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: __,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: DoctorDashboard(), // Your doctor dashboard widget
                ),
              ),
            );
            break;
          default:
            // Handle unknown role
            _showErrorDialog(
                'Role Error', 'Invalid role. Please contact support.');
        }
      }
    } catch (e) {
      print('Login error: $e');
      // Handle login errors
      _showErrorDialog(
          'Login Error', 'Invalid email or password. Please try again.');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the alert dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Navigate to the registration page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationPage(),
                  ),
                );
              },
              child: Text('Not registered? Register now'),
            ),
          ],
        ),
      ),
    );
  }
}

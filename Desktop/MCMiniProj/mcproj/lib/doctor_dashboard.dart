import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDashboard extends StatefulWidget {
  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  List<Map<String, dynamic>> _patientData = [];

  @override
  void initState() {
    super.initState();
    // Fetch patient data from Firestore when the widget initializes
    _fetchPatientData();
  }

  void _fetchPatientData() async {
    // Fetch patient data from Firestore
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .where('role', isEqualTo: 'Patient')
        .get();

    // Store patient data in the _patientData list
    setState(() {
      _patientData = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Dashboard'),
      ),
      body: ListView(
        children: _patientData.map((patient) {
          return _buildPatientCard(patient);
        }).toList(),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return GestureDetector(
      onTap: () {
        // Navigate to PatientDetailsPage when a patient's card is clicked
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailsPage(patient: patient),
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
                'Patient Name: ${patient['name']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Email: ${patient['email']}',
                style: TextStyle(fontSize: 16),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PatientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailsPage({Key? key, required this.patient}) : super(key: key);

  @override
  _PatientDetailsPageState createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  List<Map<String, dynamic>> _formData = [];

  @override
  void initState() {
    super.initState();
    // Fetch form data for the selected patient from Firestore
    _fetchFormData();
  }

  void _fetchFormData() async {
    // Get the UID of the selected patient
    String uid = widget.patient['uid'];

    // Fetch form data for the selected patient from Firestore
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
        title: Text('Patient Details'),
      ),
      body: ListView(
        children: _formData.map((data) {
          return _buildCard(data);
        }).toList(),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data) {
    return Card(
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
    );
  }
}

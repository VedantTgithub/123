import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormPage extends StatefulWidget {
  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _dateController = TextEditingController();
  TextEditingController _bloodPressureController = TextEditingController();
  TextEditingController _heartRateController = TextEditingController();
  TextEditingController _bodyTemperatureController = TextEditingController();
  TextEditingController _glucoseLevelController = TextEditingController();
  TextEditingController _bmiController = TextEditingController();

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Form is valid, proceed with saving data to Firestore
      try {
        // Get the current user's UID
        String uid = FirebaseAuth.instance.currentUser!.uid;

        // Save form data to Firestore
        await _firestore.collection('users').doc(uid).collection('data').add({
          'date': _dateController.text,
          'blood_pressure': _bloodPressureController.text,
          'heart_rate': _heartRateController.text,
          'body_temperature': _bodyTemperatureController.text,
          'glucose_level': _glucoseLevelController.text,
          'bmi': _bmiController.text,
        });

        // Show success message or navigate to a different page
      } catch (e) {
        // Handle errors
        print('Error saving form data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Data Form'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Health Data:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Date is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _bloodPressureController,
                decoration: InputDecoration(
                  labelText: 'Blood Pressure',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Blood Pressure is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _heartRateController,
                decoration: InputDecoration(
                  labelText: 'Heart Rate',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Heart Rate is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _bodyTemperatureController,
                decoration: InputDecoration(
                  labelText: 'Body Temperature (Fahrenheit)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Body Temperature is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _glucoseLevelController,
                decoration: InputDecoration(
                  labelText: 'Glucose Level',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Glucose Level is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _bmiController,
                decoration: InputDecoration(
                  labelText: 'BMI',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'BMI is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

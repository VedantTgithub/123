import 'package:flutter/material.dart';

class DietPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diet Page'),
      ),
      body: Center(
        child: Text(
          'Welcome to Diet Page!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
// Import the Inventory Dashboard page (still needed for navigation after login)
// ignore: unused_import
import 'login.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // You might want to define a consistent color scheme or theme here
        // useMaterial3: true, // Consider enabling Material 3 for modern design
      ),
      // Start the application with the SplashScreen
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false, // Hide the debug banner
    );
  }
}

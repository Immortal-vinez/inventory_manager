import 'package:flutter/material.dart';
import 'login.dart';

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
      // Start the application with the OfflineLoginPage
      // The login page will then navigate to the InventoryDashboard upon successful authentication.
      home: const OfflineLoginPage(),
      debugShowCheckedModeBanner: false, // Hide the debug banner
    );
  }
}

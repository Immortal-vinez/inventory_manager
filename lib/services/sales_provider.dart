import 'package:flutter/material.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Page')),
      body: const Center(
        child: Text(
          'Welcome to the Sales Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

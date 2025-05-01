import 'package:flutter/material.dart';
import 'inventory_dashboard.dart';
import 'sales_summary.dart';

class SalePage extends StatefulWidget {
  final List<Map<String, dynamic>> inventoryItems;
  final List<Map<String, dynamic>> initialInventory;
  final void Function(int index, int soldQuantity) onSale;

  const SalePage({
    super.key,
    required this.inventoryItems,
    required this.initialInventory,
    required this.onSale,
  });

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  int _currentNavIndex = 1; // 0=Dashboard,1=Sale,2=Summary
  int? _selectedIndex;
  final TextEditingController _quantityController = TextEditingController();

  void _performSale() {
    if (_selectedIndex == null || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an item and enter quantity'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final available = widget.inventoryItems[_selectedIndex!]['quantity'] as int;
    if (qty <= 0 || qty > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            qty <= 0
                ? 'Enter a quantity greater than zero'
                : 'Cannot sell more than available ($available)',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    widget.onSale(_selectedIndex!, qty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sold $qty of ${widget.inventoryItems[_selectedIndex!]['name']}',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {
      _selectedIndex = null;
      _quantityController.clear();
    });
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InventoryDashboard()),
        );
        break;
      case 1:
        // Already on Sale
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => SalesSummaryPage(
                  inventoryItems: widget.inventoryItems,
                  salesRecords: [], // Pass actual sales records here
                ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record a Sale'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Select Item',
                border: OutlineInputBorder(),
              ),
              value: _selectedIndex,
              items:
                  widget.inventoryItems
                      .asMap()
                      .entries
                      .map(
                        (entry) => DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(
                            '${entry.value['name']} (Qty: ${entry.value['quantity']})',
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedIndex = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity to Sell',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sell),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _performSale,
              icon: const Icon(Icons.check),
              label: const Text('Confirm Sale'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Inventory Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.inventoryItems.length,
                itemBuilder: (context, index) {
                  final item = widget.inventoryItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(item['name']),
                      subtitle: Text('Qty available: ${item['quantity']}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Sale'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Summary',
          ),
        ],
      ),
    );
  }
}

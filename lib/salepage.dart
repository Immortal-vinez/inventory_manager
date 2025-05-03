import 'package:flutter/material.dart';
import 'inventory_dashboard.dart';
import 'sales_summary.dart';
import 'dart:async';

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
  int _currentNavIndex = 1;
  int? _selectedIndex;
  final TextEditingController _quantityController = TextEditingController();

  int _runningTotal = 0;
  final int _reorderThreshold = 5; // Example threshold
  Timer? _autoSaveTimer;
  Map<String, dynamic>? _savedDraft;

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _quantityController.addListener(_updateRunningTotal);
  }

  void _loadDraft() {
    if (_savedDraft != null) {
      _selectedIndex = _savedDraft!['index'];
      _quantityController.text = _savedDraft!['quantity'].toString();
    }
  }

  void _updateRunningTotal() {
    if (_selectedIndex != null) {
      final price = widget.inventoryItems[_selectedIndex!]['price'] ?? 0;
      final qty = int.tryParse(_quantityController.text) ?? 0;
      setState(() => _runningTotal = price * qty);
    } else {
      setState(() => _runningTotal = 0);
    }
    _saveDraftTemporarily();
  }

  void _saveDraftTemporarily() {
    _savedDraft = {
      'index': _selectedIndex,
      'quantity': int.tryParse(_quantityController.text) ?? 0,
    };
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), () {
      // Could add persistent local storage here.
    });
  }

  void _clearDraft() {
    _savedDraft = null;
    _quantityController.clear();
    setState(() => _selectedIndex = null);
  }

  void _performSale() {
    if (_selectedIndex == null || _quantityController.text.isEmpty) {
      _showError('Please select an item and enter quantity');
      return;
    }

    final qty = int.tryParse(_quantityController.text) ?? 0;
    final item = widget.inventoryItems[_selectedIndex!];
    final available = item['quantity'] as int;

    if (qty <= 0) {
      _showError('Enter a quantity greater than zero');
      return;
    }

    if (qty > available) {
      _showError('Cannot sell more than available ($available)');
      return;
    }

    widget.onSale(_selectedIndex!, qty);

    final newQty = available - qty;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sold $qty of ${item['name']}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    if (newQty < _reorderThreshold) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ ${item['name']} stock is below reorder threshold ($_reorderThreshold)',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    _clearDraft();
  }

  void _cancelSale() {
    final previousDraft = _savedDraft;
    _clearDraft();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sale cancelled'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (previousDraft != null) {
              setState(() {
                _selectedIndex = previousDraft['index'];
                _quantityController.text = previousDraft['quantity'].toString();
              });
            }
          },
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
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
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => SalesSummaryPage(
                  inventoryItems: widget.inventoryItems,
                  salesRecords: [],
                ),
          ),
        );
        break;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
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
                  widget.inventoryItems.asMap().entries.map((entry) {
                    final item = entry.value;
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text('${item['name']} (Qty: ${item['quantity']})'),
                    );
                  }).toList(),
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
            const SizedBox(height: 12),
            Text(
              'Subtotal: K$_runningTotal',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _performSale,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Sale'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _cancelSale,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Current Inventory Overview',
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

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'sales_summary.dart';
import 'salepage.dart';
import 'module/database_helper.dart';

class InventoryDashboard extends StatefulWidget {
  const InventoryDashboard({super.key});

  @override
  State<InventoryDashboard> createState() => _InventoryDashboardState();
}

class _InventoryDashboardState extends State<InventoryDashboard> {
  final List<Map<String, dynamic>> _inventoryItems = [];
  final List<Map<String, dynamic>> _salesRecords = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final items = await DatabaseHelper.instance.getItems();
    final records = await DatabaseHelper.instance.getSalesRecords();
    if (!mounted) return;
    setState(() {
      _inventoryItems
        ..clear()
        ..addAll(items);
      _salesRecords
        ..clear()
        ..addAll(records);
    });
  }

  void _showFullScreenForm({int? editIndex}) {
    final isEditing = editIndex != null;
    final item =
        isEditing ? Map.of(_inventoryItems[editIndex]) : <String, dynamic>{};
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'category': TextEditingController(text: item['category'] ?? ''),
      'name': TextEditingController(text: item['name'] ?? ''),
      'brand': TextEditingController(text: item['brand'] ?? ''),
      'color': TextEditingController(text: item['color'] ?? ''),
      'quantity': TextEditingController(
        text: item['quantity']?.toString() ?? '',
      ),
      'price': TextEditingController(text: item['price']?.toString() ?? ''),
      'imageUrl': TextEditingController(text: item['imageUrl'] ?? ''),
    };

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder:
          (_) => AlertDialog(
            title: Text(isEditing ? 'Edit Item' : 'Add Item'),
            content: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...['category', 'name', 'brand', 'color'].map((field) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextFormField(
                            controller: controllers[field],
                            decoration: InputDecoration(
                              labelText:
                                  field[0].toUpperCase() + field.substring(1),
                              border: const OutlineInputBorder(),
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                          ),
                        );
                      }),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: TextFormField(
                                controller: controllers['quantity'],
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Required'
                                            : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: TextFormField(
                                controller: controllers['price'],
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Required'
                                            : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TextFormField(
                          controller: controllers['imageUrl'],
                          decoration: const InputDecoration(
                            labelText: 'Image URL (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Removed the full-width button here
                    ],
                  ),
                ),
              ),
            ),
            // Added actions row for buttons
            actions: [
              // Cancel Button
              TextButton(
                onPressed: () {
                  // Dispose controllers to prevent memory leaks
                  for (var c in controllers.values) {
                    c.dispose();
                  }
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('Cancel'),
              ),
              // Add/Update Button
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final newItem = {
                    'category': controllers['category']!.text,
                    'name': controllers['name']!.text,
                    'brand': controllers['brand']!.text,
                    'color': controllers['color']!.text,
                    'quantity': int.parse(controllers['quantity']!.text),
                    'price': double.parse(controllers['price']!.text),
                    'imageUrl':
                        controllers['imageUrl']!.text.isNotEmpty
                            ? controllers['imageUrl']!.text
                            : 'https://via.placeholder.com/150', // Placeholder if empty
                  };

                  if (isEditing) {
                    // Update existing item
                    await DatabaseHelper.instance.updateItem(
                      _inventoryItems[editIndex]['id'],
                      newItem,
                    );
                  } else {
                    // Insert new item
                    final id = await DatabaseHelper.instance.insertItem(
                      newItem,
                    );
                    newItem['id'] =
                        id; // Add the generated ID to the local item map
                  }

                  // Dispose controllers before navigating
                  for (var c in controllers.values) {
                    c.dispose();
                  }

                  if (!mounted) return; // Check if widget is still mounted

                  Navigator.of(context).pop(); // Close the dialog

                  // Refresh data and show confirmation
                  await _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Item updated' : 'Item added'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(isEditing ? 'Update Item' : 'Add Item'),
              ),
            ],
          ),
    );
  }

  void _deleteItem(int index) async {
    // Show a confirmation dialog before deleting
    final bool confirm =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text(
                'Are you sure you want to delete "${_inventoryItems[index]['name']}"?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pop(false), // Return false on Cancel
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pop(true), // Return true on Delete
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed

    if (confirm) {
      final id = _inventoryItems[index]['id'];
      await DatabaseHelper.instance.deleteItem(id);
      if (!mounted) return;
      await _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToSalesSummary() {
    // Navigate to Sales Summary, passing current data
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SalesSummaryPage(
              inventoryItems: _inventoryItems,
              salesRecords: _salesRecords,
            ),
      ),
    );
  }

  void _navigateToSalesPage() {
    // Navigate to Sales Page, passing current data and providing a sale callback
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SalePage(
              inventoryItems: _inventoryItems,
              initialInventory: List.from(_inventoryItems), // Pass a copy
              onSale: (index, qty) async {
                // Logic to handle a sale:
                // 1. Check if enough stock is available
                if (_inventoryItems[index]['quantity'] < qty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not enough stock'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                // 2. Update inventory quantity in the database
                await DatabaseHelper.instance.updateItem(
                  _inventoryItems[index]['id'],
                  {'quantity': _inventoryItems[index]['quantity'] - qty},
                );
                // 3. Insert a sales record into the database
                await DatabaseHelper.instance.insertSalesRecord({
                  'name': _inventoryItems[index]['name'],
                  'quantity': qty,
                  'price': _inventoryItems[index]['price'],
                  'timestamp':
                      DateTime.now().toIso8601String(), // Record sale time
                });
                // 4. Refresh local state and show confirmation
                if (!mounted) return;
                await _refreshData(); // Refresh both inventory and sales data
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sold $qty of ${_inventoryItems[index]['name']}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          // Navigation buttons in AppBar
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Sales Summary',
            onPressed: _navigateToSalesSummary,
          ),
          // Current page icon (Inventory)
          IconButton(
            icon: const Icon(Icons.inventory),
            tooltip: 'Inventory',
            onPressed: () {}, // No action needed for the current page
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: 'Make Sale',
            onPressed: _navigateToSalesPage,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _inventoryItems.isEmpty
                ? const Center(child: Text('No items in inventory'))
                : RefreshIndicator(
                  onRefresh: _refreshData, // Pull to refresh functionality
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 items per row
                          childAspectRatio:
                              3 / 4, // Aspect ratio of each item card
                          crossAxisSpacing:
                              16, // Horizontal space between items
                          mainAxisSpacing: 16, // Vertical space between items
                        ),
                    itemCount: _inventoryItems.length,
                    itemBuilder: (context, index) {
                      final item = _inventoryItems[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 3, // Image takes 3/5 of the card height
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  item['imageUrl'],
                                  fit: BoxFit.cover,
                                  // Error builder for broken images
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex:
                                  2, // Text details take 2/5 of the card height
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16, // Increased font size
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4), // Added spacing
                                    Text(
                                      'Qty: ${item['quantity']}',
                                      style: const TextStyle(fontSize: 14),
                                    ), // Styled text
                                    Text(
                                      'Price: \$${item['price'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                      ),
                                    ), // Styled text
                                    const Spacer(), // Pushes buttons to the bottom
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Edit Button
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          tooltip: 'Edit Item',
                                          onPressed:
                                              () => _showFullScreenForm(
                                                editIndex: index,
                                              ),
                                        ),
                                        // Delete Button
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          tooltip: 'Delete Item',
                                          color:
                                              Colors.red, // Styled delete icon
                                          onPressed: () => _deleteItem(index),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFullScreenForm(), // Show form to add new item
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Note: The SalesSummaryPage and SalePage widgets are defined in their own files
// (sales_summary.dart and salepage.dart) as per the import statements.
// The DatabaseHelper is assumed to be implemented in module/database_helper.dart.

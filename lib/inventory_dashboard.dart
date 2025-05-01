import 'package:flutter/material.dart';
import 'sales_summary.dart'; // Import the SalesSummaryPage
import 'salepage.dart'; // Import the SalesPage

// InventoryDashboard widget serves as the main screen for managing inventory.
class InventoryDashboard extends StatefulWidget {
  const InventoryDashboard({super.key});

  @override
  State<InventoryDashboard> createState() => _InventoryDashboardState();
}

class _InventoryDashboardState extends State<InventoryDashboard> {
  // List to hold the current inventory items. Each item is a Map.
  final List<Map<String, dynamic>> _inventoryItems = [];
  // List to hold the sales records. Each record is a Map.
  final List<Map<String, dynamic>> _salesRecords = []; // Add sales records here

  // Function to show a full-screen form for adding or editing inventory items.
  void _showFullScreenForm({int? editIndex}) {
    // Determine if we are editing an existing item or adding a new one.
    final isEditing = editIndex != null;
    // Get the item data if editing, otherwise start with an empty map.
    final Map<String, dynamic> item =
        isEditing ? _inventoryItems[editIndex] : {};
    // GlobalKey for the Form widget to handle validation.
    final formKey = GlobalKey<FormState>();
    // Controllers for the text fields in the form, initialized with existing data if editing.
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

    // Show a dialog which contains the form.
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder:
          (_) => AlertDialog(
            title: Text(isEditing ? 'Edit Item' : 'Add Item'),
            // Wrap content in SingleChildScrollView to prevent overflow on small screens.
            content: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: formKey, // Assign the form key
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Make column take minimum space
                    children: [
                      // Generate TextFormFields for text-based fields.
                      ...['category', 'name', 'brand', 'color'].map((field) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextFormField(
                            controller: controllers[field],
                            decoration: InputDecoration(
                              labelText:
                                  field[0].toUpperCase() +
                                  field.substring(1), // Capitalize first letter
                              border: const OutlineInputBorder(),
                            ),
                            // Basic validation: field cannot be empty.
                            validator:
                                (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                          ),
                        );
                      }),
                      // Row for Quantity and Price fields.
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
                                keyboardType:
                                    TextInputType.number, // Only allow numbers
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Required'
                                            : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12), // Spacing between fields
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: TextFormField(
                                controller: controllers['price'],
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    TextInputType.number, // Only allow numbers
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
                      // TextFormField for Image URL.
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TextFormField(
                          controller: controllers['imageUrl'],
                          decoration: const InputDecoration(
                            labelText: 'Image URL (optional)',
                            border: OutlineInputBorder(),
                          ),
                          // No validator here as it's optional
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Button to submit the form (Add or Update item).
                      SizedBox(
                        width: double.infinity, // Make button full width
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate the form.
                            if (formKey.currentState!.validate()) {
                              // Update the state to add or modify the item.
                              setState(() {
                                final newItem = {
                                  'category': controllers['category']!.text,
                                  'name': controllers['name']!.text,
                                  'brand': controllers['brand']!.text,
                                  'color': controllers['color']!.text,
                                  'quantity': int.parse(
                                    controllers['quantity']!.text,
                                  ), // Parse quantity as int
                                  'price': double.parse(
                                    controllers['price']!.text,
                                  ), // Parse price as double
                                  // Use provided image URL or a placeholder if empty.
                                  'imageUrl':
                                      controllers['imageUrl']!.text.isNotEmpty
                                          ? controllers['imageUrl']!.text
                                          : 'https://via.placeholder.com/150',
                                };
                                if (isEditing) {
                                  // Update existing item.
                                  _inventoryItems[editIndex] = newItem;
                                } else {
                                  // Add new item to the list.
                                  _inventoryItems.add(newItem);
                                }
                              });
                              // Close the dialog.
                              Navigator.of(context).pop();
                              // Show a success snackbar.
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing ? 'Item updated' : 'Item added',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Text(isEditing ? 'Update Item' : 'Add Item'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // Function to delete an item from the inventory.
  void _deleteItem(int index) {
    // Update the state to remove the item at the given index.
    setState(() => _inventoryItems.removeAt(index));
    // Show a deletion confirmation snackbar.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item deleted'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Function to navigate to the Sales Summary page.
  void _navigateToSalesSummary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SalesSummaryPage(
              // Pass the current inventory items and sales records to the summary page.
              inventoryItems: _inventoryItems,
              salesRecords: _salesRecords,
            ),
      ),
    );
  }

  // Function to navigate to the Sales Page.
  void _navigateToSalesPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SalePage(
              // Pass the current inventory items.
              inventoryItems: _inventoryItems,
              // Pass a copy of the current inventory items as the initial state for the SalePage.
              initialInventory: List.from(_inventoryItems), // Pass a copy
              // Pass the callback function to handle sales.
              onSale: (index, qty) {
                // Update the state in the InventoryDashboard when a sale occurs.
                setState(() {
                  final item = _inventoryItems[index];
                  // Decrease the quantity of the sold item.
                  item['quantity'] -= qty;
                  // Add a new record to the sales records list.
                  _salesRecords.add({
                    'name': item['name'],
                    'quantity': qty,
                    'price': item['price'],
                    'timestamp': DateTime.now(), // Add a timestamp for the sale
                  });
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar for the Inventory Dashboard.
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          // Button to navigate to Sales Summary.
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _navigateToSalesSummary,
          ),
          // Button for Inventory (current page).
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () {}, // Do nothing as we are on this page
          ),
          // Button to navigate to Sales Page.
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: _navigateToSalesPage,
          ),
        ],
      ),
      // Body of the Inventory Dashboard.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Display a message if inventory is empty, otherwise display the GridView.
        child:
            _inventoryItems.isEmpty
                ? const Center(child: Text('No items in inventory'))
                : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items per row
                    childAspectRatio: 3 / 4, // Aspect ratio of each grid item
                    crossAxisSpacing: 16, // Horizontal spacing
                    mainAxisSpacing: 16, // Vertical spacing
                  ),
                  itemCount: _inventoryItems.length,
                  itemBuilder: (context, index) {
                    final item = _inventoryItems[index];
                    return Card(
                      elevation: 3, // Card shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Rounded corners
                      ),
                      child: Column(
                        children: [
                          // Expanded widget for the image.
                          Expanded(
                            flex: 3, // Takes 3/5 of the column space
                            child: ClipRRect(
                              // Clip image to card's rounded corners
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                item['imageUrl'],
                                fit: BoxFit.cover, // Cover the available space
                                // Add an error builder for broken image URLs
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Expanded widget for item details and actions.
                          Expanded(
                            flex: 2, // Takes 2/5 of the column space
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Item name.
                                  Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1, // Prevent text wrapping
                                    overflow:
                                        TextOverflow
                                            .ellipsis, // Show ellipsis if text is too long
                                  ),
                                  // Item quantity.
                                  Text('Qty: ${item['quantity']}'),
                                  const Spacer(), // Pushes the action row to the bottom
                                  // Row for Edit and Delete buttons.
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .end, // Align buttons to the right
                                    children: [
                                      // Edit button.
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed:
                                            () => _showFullScreenForm(
                                              editIndex: index,
                                            ), // Open form for editing
                                      ),
                                      // Delete button.
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed:
                                            () => _deleteItem(
                                              index,
                                            ), // Delete the item
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
      // Floating action button to add a new item.
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => _showFullScreenForm(), // Open form for adding a new item
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

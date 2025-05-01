import 'package:flutter/material.dart';
import 'inventory_dashboard.dart'; // Import the InventoryDashboard
import 'salepage.dart'; // Import the SalesPage

// SalesSummaryPage widget displays a summary of sales and current inventory value.
class SalesSummaryPage extends StatefulWidget {
  // List of current inventory items with their details.
  final List<Map<String, dynamic>> inventoryItems;
  // List of recorded sales transactions.
  final List<Map<String, dynamic>> salesRecords;

  const SalesSummaryPage({
    super.key,
    required this.inventoryItems, // Requires the current inventory list
    required this.salesRecords, // Requires the list of sales records
  });

  @override
  // ignore: library_private_types_in_public_api
  _SalesSummaryPageState createState() => _SalesSummaryPageState();
}

class _SalesSummaryPageState extends State<SalesSummaryPage> {
  // Current index for the bottom navigation bar (2 indicates the Summary tab).
  int _currentNavIndex = 2; // 0=Inventory, 1=Sale, 2=Summary

  // Calculates the total revenue from all sales records.
  double get totalRevenue {
    // Use fold to iterate through salesRecords and sum up price * quantity for each record.
    return widget.salesRecords.fold(0.0, (sum, record) {
      // Ensure price and quantity are treated as numbers.
      final price = (record['price'] as num?)?.toDouble() ?? 0.0;
      final qty = (record['quantity'] as num?)?.toInt() ?? 0;
      return sum + price * qty;
    });
  }

  // Calculates the potential return from the current inventory (value of remaining stock).
  double get expectedReturn {
    // Use fold to iterate through current inventoryItems and sum up price * quantity for each item.
    return widget.inventoryItems.fold(0.0, (sum, item) {
      // Ensure price and quantity are treated as numbers.
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      return sum + price * qty;
    });
  }

  // Calculates the total quantity sold for each item name.
  Map<String, int> get _soldQuantities {
    final map = <String, int>{};
    // Iterate through sales records.
    for (var record in widget.salesRecords) {
      final name = record['name'] as String?;
      final qty = (record['quantity'] as num?)?.toInt() ?? 0;
      // If name is not null, add the quantity to the map, summing up quantities for the same item.
      if (name != null) {
        map[name] = (map[name] ?? 0) + qty;
      }
    }
    return map;
  }

  // Gets a list of items sorted by the quantity sold in descending order (most sold first).
  List<MapEntry<String, int>> get mostSoldItems {
    // Get entries from the _soldQuantities map.
    final entries = _soldQuantities.entries.toList();
    // Sort the entries based on the value (quantity sold).
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  // Handles navigation when a bottom navigation bar item is tapped.
  void _onNavTap(int index) {
    // If the tapped index is the current index, do nothing.
    if (index == _currentNavIndex) return;

    // Update the current navigation index.
    setState(() => _currentNavIndex = index);

    // Navigate to the corresponding page using pushReplacement
    // to replace the current page in the navigation stack.
    switch (index) {
      case 0: // Navigate to Inventory Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InventoryDashboard()),
        );
        break;
      case 1: // Navigate to Sale page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => SalePage(
                  // Pass the current inventory items to the SalePage.
                  inventoryItems: widget.inventoryItems,
                  // Pass a copy of the current inventory items as the initial state for the SalePage.
                  initialInventory: List.from(widget.inventoryItems),
                  // Provide an empty onSale callback here, as sales should primarily be handled
                  // and recorded in the InventoryDashboard state.
                  onSale: (idx, qty) {
                    // This callback is intentionally left empty when navigating from Sales Summary
                    // to prevent state changes in the InventoryDashboard from this navigation path.
                    // If you need sales from this page to update the main state, you would need
                    // to pass a function that updates the state in the parent widget (InventoryDashboard).
                  },
                ),
          ),
        );
        break;
      case 2: // Stay on Sales Summary page
        // Already here, do nothing.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar for the Sales Summary page.
      appBar: AppBar(
        title: const Text('Sales Summary'),
        backgroundColor: Colors.blue,
      ),
      // Body of the Sales Summary page.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Wrap content in SingleChildScrollView to prevent overflow.
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row to display Total Revenue and Expected Return stat cards.
              Row(
                children: [
                  _buildStatCard(
                    title: 'Total Revenue',
                    value: 'ZMW ${totalRevenue.toStringAsFixed(2)}',
                  ), // Format as currency
                  const SizedBox(width: 16), // Spacing
                  _buildStatCard(
                    title: 'Expected Return',
                    value: 'ZMW ${expectedReturn.toStringAsFixed(2)}',
                  ), // Format as currency
                ],
              ),
              const SizedBox(height: 16), // Spacing
              // Header for Current Inventory section.
              const Text(
                'Current Inventory',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8), // Spacing
              // GridView to display current inventory items.
              GridView.builder(
                shrinkWrap: true, // Make GridView take minimum space
                physics:
                    const NeverScrollableScrollPhysics(), // Disable GridView scrolling (handled by SingleChildScrollView)
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 items per row
                  childAspectRatio: 3 / 2, // Aspect ratio
                  crossAxisSpacing: 8, // Horizontal spacing
                  mainAxisSpacing: 8, // Vertical spacing
                ),
                itemCount: widget.inventoryItems.length,
                itemBuilder: (ctx, idx) {
                  final item = widget.inventoryItems[idx];
                  return Card(
                    elevation: 2, // Card shadow
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item name.
                          Text(
                            item['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(), // Pushes quantity to the bottom
                          // Item quantity.
                          Text('Qty: ${item['quantity']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16), // Spacing
              // Header for Top Selling Items section.
              const Text(
                'Top Selling Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8), // Spacing
              // ListView to display top selling items.
              ListView.builder(
                shrinkWrap: true, // Make ListView take minimum space
                physics:
                    const NeverScrollableScrollPhysics(), // Disable ListView scrolling
                itemCount: mostSoldItems.length,
                itemBuilder: (ctx, idx) {
                  final entry = mostSoldItems[idx];
                  return ListTile(
                    // Display quantity sold in a CircleAvatar.
                    leading: CircleAvatar(child: Text(entry.value.toString())),
                    // Display item name.
                    title: Text(entry.key),
                    // Display a subtitle indicating units sold.
                    subtitle: const Text('Units sold'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      // Bottom navigation bar for switching between pages.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap, // Call _onNavTap when a tab is tapped
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

  // Helper method to build a stat card for displaying summary information.
  Widget _buildStatCard({required String title, required String value}) {
    return Expanded(
      child: Card(
        color: Colors.blue.shade50, // Light blue background
        elevation: 2, // Card shadow
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title of the stat card.
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8), // Spacing
              // Value of the stat.
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

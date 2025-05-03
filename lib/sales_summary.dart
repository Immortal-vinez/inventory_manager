// lib/sales_summary.dart

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
// Removed: import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Removed: import 'package:timezone/data/latest_all.dart' as tz;
// Removed: import 'package:timezone/timezone.dart' as tz;

import 'inventory_dashboard.dart';
import 'salepage.dart';

class SalesSummaryPage extends StatefulWidget {
  final List<Map<String, dynamic>> inventoryItems;
  final List<Map<String, dynamic>> salesRecords;

  const SalesSummaryPage({
    super.key,
    required this.inventoryItems,
    required this.salesRecords,
  });

  @override
  State<SalesSummaryPage> createState() => _SalesSummaryPageState();
}

class _SalesSummaryPageState extends State<SalesSummaryPage> {
  int _currentNavIndex = 2; // 0=Inv,1=Sale,2=Summary

  // Time formatting
  final DateFormat _dayFormat = DateFormat('EEEE, MMM d');

  // Removed: Notifications related fields and methods
  // final _notifications = FlutterLocalNotificationsPlugin();
  // Day _reminderDay = Day.monday;
  // TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  // bool _reminderEnabled = false;
  // final List<_NotificationRecord> _history = [];
  // Future<void> _initNotification() async { ... }
  // Future<void> _scheduleUserReminder() async { ... }

  @override
  void initState() {
    super.initState();
    // Removed: _initNotification();
  }

  // --- Summary getters ---

  double get totalRevenue => widget.salesRecords.fold<double>(
    0,
    (sum, rec) =>
        sum +
        ((rec['price'] as num?)?.toDouble() ?? 0) *
            ((rec['quantity'] as num?)?.toInt() ?? 0),
  );

  double get expectedReturn => widget.inventoryItems.fold<double>(
    0,
    (sum, it) =>
        sum +
        ((it['price'] as num?)?.toDouble() ?? 0) *
            ((it['quantity'] as num?)?.toInt() ?? 0),
  );

  double get grossProfit {
    final cogs = widget.salesRecords.fold<double>(0, (sum, rec) {
      final name = rec['name'] as String?;
      final qty = (rec['quantity'] as num?)?.toInt() ?? 0;
      // Find the corresponding item in inventory to get cost price
      final item = widget.inventoryItems.firstWhere(
        (it) => it['name'] == name,
        // Provide a default if item not found in inventory (cost is 0)
        orElse: () => {'costPrice': 0.0, 'name': name},
      );
      final cost = (item['costPrice'] as num?)?.toDouble() ?? 0;
      return sum + cost * qty;
    });
    return totalRevenue - cogs;
  }

  Map<String, double> get dailySales {
    final map = <String, double>{};
    for (var rec in widget.salesRecords) {
      final ts = rec['timestamp'] as String? ?? '';
      // Attempt to parse the timestamp string
      final date = DateTime.tryParse(ts);
      if (date != null) {
        final day = _dayFormat.format(date);
        final price = (rec['price'] as num?)?.toDouble() ?? 0;
        final qty = (rec['quantity'] as num?)?.toInt() ?? 0;
        map[day] = (map[day] ?? 0) + price * qty;
      }
      // Handle cases where timestamp is missing or invalid by skipping the record
    }
    // Sort by date if necessary, but keys are strings of formatted dates.
    // To sort correctly, you might need to store date objects or sort entries.
    // For simplicity here, we'll just return the map.
    return map;
  }

  Map<String, int> get _soldQuantities {
    final m = <String, int>{};
    for (var rec in widget.salesRecords) {
      final name = rec['name'] as String? ?? '';
      final qty = (rec['quantity'] as num?)?.toInt() ?? 0;
      if (name.isNotEmpty && qty > 0) {
        // Ensure item name and quantity are valid
        m[name] = (m[name] ?? 0) + qty;
      }
    }
    return m;
  }

  List<MapEntry<String, int>> get mostSoldItems {
    final entries =
        _soldQuantities.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  BarChartData _buildBarChartData() {
    // Take top 5 items, or fewer if less than 5 sold items
    final soldMapEntries = mostSoldItems.take(5).toList();
    final names = soldMapEntries.map((e) => e.key).toList();

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < soldMapEntries.length; i++) {
      final entry = soldMapEntries[i];
      final name = entry.key;
      final sold = entry.value.toDouble();

      // Find corresponding inventory item quantity
      final invItem = widget.inventoryItems.firstWhere(
        (it) => it['name'] == name,
        orElse: () => {'quantity': 0, 'name': name}, // Default if not found
      );
      final inv = (invItem['quantity'] as num?)?.toInt().toDouble() ?? 0.0;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sold,
              width: 8,
              color: Colors.blue,
              borderRadius: BorderRadius.zero, // Example styling
            ),
            BarChartRodData(
              toY: inv,
              width: 8,
              color: Colors.grey,
              borderRadius: BorderRadius.zero, // Example styling
            ),
          ],
          // Optional: Add a bar stack or groups for multiple bars if needed
        ),
      );
    }

    // Calculate max Y value for the chart
    double maxY = 0;
    for (var group in groups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxY) {
          maxY = rod.toY;
        }
      }
    }
    // Add some padding to the max Y value
    maxY = maxY * 1.2;

    return BarChartData(
      barGroups: groups,
      titlesData: FlTitlesData(
        show: true, // Ensure titles are shown
        bottomTitles: AxisTitles(
          axisNameWidget: const Text(
            'Item Name',
            style: TextStyle(fontSize: 12),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx >= 0 && idx < names.length) {
                // Use RotatedBox if names are long and might overlap
                return Text(names[idx], style: const TextStyle(fontSize: 10));
              }
              return const Text('');
            },
            reservedSize: 20, // Increase if names are long
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: const Text(
            'Quantity',
            style: TextStyle(fontSize: 12),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30, // Space for labels
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
      ), // Show horizontal grid lines
      borderData: FlBorderData(show: false), // Remove border lines
      maxY: maxY, // Set calculated max Y
      minY: 0,
      barTouchData: BarTouchData(enabled: false), // Disable touch feedback
    );
  }

  // --- CSV / PDF export ---

  Future<void> _exportToCSV() async {
    final rows = [
      ['Date', 'Name', 'Qty', 'Price'], // CSV Header
      ...widget.salesRecords.map(
        (r) => [
          (r['timestamp'] as String?)?.split('T').first ?? '', // Date part
          r['name'] as String? ?? '', // Item name
          (r['quantity'] as num?)?.toInt().toString() ??
              '0', // Quantity as String
          (r['price'] as num?)?.toDouble().toStringAsFixed(2) ??
              '0.00', // Price as String
        ],
      ),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sales_report.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV exported to ${file.path}')));
    } catch (e) {
      print('Error exporting CSV: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export CSV: $e')));
    }
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build:
            (ctx) => [
              pw.Header(level: 0, child: pw.Text('Sales Report')),
              pw.SizedBox(height: 20), // Add some space
              // Table of sales records
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: ['Date', 'Name', 'Qty', 'Price'],
                data:
                    widget.salesRecords
                        .map(
                          (r) => [
                            (r['timestamp'] as String?)?.split('T').first ?? '',
                            r['name'] as String? ?? '',
                            (r['quantity'] as num?)?.toInt().toString() ?? '0',
                            (r['price'] as num?)?.toDouble().toStringAsFixed(
                                  2,
                                ) ??
                                '0.00',
                          ],
                        )
                        .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
              ),
              pw.Divider(),
              pw.SizedBox(height: 10), // Add some space
              // Summary Statistics
              pw.Text(
                'Summary:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Total Revenue: ${totalRevenue.toStringAsFixed(2)}'),
              pw.Text('Gross Profit: ${grossProfit.toStringAsFixed(2)}'),
              // You could add Inventory Value here too if desired
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated on ${DateFormat.yMd().add_jm().format(DateTime.now())}',
              ),
            ],
      ),
    );
    try {
      // Use Printing.layoutPdf to show preview and print/share options
      await Printing.layoutPdf(onLayout: (fmt) => pdf.save());
    } catch (e) {
      print('Error generating or printing PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    }
  }

  // --- Navigation ---

  void _onNavTap(int idx) {
    if (idx == _currentNavIndex) return;
    // No setState here because pushReplacement will build a new page
    // setState(() => _currentNavIndex = idx); // Remove this setState

    switch (idx) {
      case 0:
        // Navigate to Inventory, replacing the current page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InventoryDashboard()),
        ); // Assuming InventoryDashboard needs no args or fetches its own
        break;
      case 1:
        // Navigate to Sale, replacing the current page
        // NOTE: Passing the current lists might not reflect real-time changes
        // if state is managed elsewhere.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => SalePage(
                  inventoryItems:
                      widget.inventoryItems, // Pass existing inventory
                  initialInventory: List.from(
                    widget.inventoryItems,
                  ), // Pass a copy if needed
                  onSale: (i, q) {
                    // This callback was empty in the original code.
                    // If sales impact state outside this page, handle it here
                    // or use a shared state management solution.
                  },
                ),
          ),
        );
        break;
      case 2:
        // Tapped Summary - update index and stay on this page
        setState(() => _currentNavIndex = idx);
        break;
      // Removed case 3 for Alerts
      default:
        // Should not happen with fixed items, but good practice
        setState(() => _currentNavIndex = idx);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the view based on the current navigation index
    // Removed the conditional check for index 3
    final currentView = _buildSummaryView();

    return Scaffold(
      appBar: AppBar(title: const Text('Sales Summary')),
      // Always show the summary view now
      body: currentView,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed, // Use fixed for 4+ items
        selectedItemColor: Theme.of(context).primaryColor, // Optional styling
        unselectedItemColor: Colors.grey[600], // Optional styling
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
          // Removed: BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export buttons
          Row(
            children: [
              Expanded(
                // Use Expanded to help buttons fit
                child: ElevatedButton.icon(
                  onPressed: _exportToCSV,
                  icon: const Icon(Icons.download),
                  label: const Text('CSV'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                // Use Expanded
                child: ElevatedButton.icon(
                  onPressed: _exportToPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats
          Row(
            children: [
              _buildStatCard('Revenue', totalRevenue),
              const SizedBox(width: 8),
              _buildStatCard('Inventory Value', expectedReturn),
              const SizedBox(width: 8),
              _buildStatCard('Gross Profit', grossProfit),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Daily Sales',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Check if daily sales is empty
          dailySales.isEmpty
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No sales data available.'),
              )
              : ListView.builder(
                shrinkWrap: true, // Use shrinkWrap in SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling for this list
                itemCount: dailySales.length,
                itemBuilder: (ctx, index) {
                  final entry = dailySales.entries.elementAt(index);
                  return ListTile(
                    title: Text(entry.key),
                    trailing: Text(entry.value.toStringAsFixed(2)),
                  );
                },
              ),
          const SizedBox(height: 24),
          const Text(
            'Top Selling (Quantity)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Check if most sold items is empty
          mostSoldItems.isEmpty
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No sales data available to determine top items.'),
              )
              : ListView.builder(
                shrinkWrap: true, // Use shrinkWrap
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling
                itemCount: mostSoldItems.length,
                itemBuilder: (ctx, index) {
                  final entry = mostSoldItems[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(entry.value.toString())),
                    title: Text(entry.key),
                  );
                },
              ),
          const SizedBox(height: 24),
          const Text(
            'Top 5 Sales vs Inventory',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Check if there are items to chart
          mostSoldItems.take(5).isEmpty
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Not enough data to show chart.'),
              )
              : SizedBox(
                height: 250, // Increased height for chart readability
                child: BarChart(_buildBarChartData()),
              ),
          const SizedBox(height: 50), // Add padding at the bottom
        ],
      ),
    );
  }

  // Removed: _buildNotificationsView() { ... }

  Widget _buildStatCard(String title, double value) {
    return Expanded(
      child: Card(
        color: Colors.blue.shade50,
        elevation: 2, // Add a little shadow
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ), // Style value
            ],
          ),
        ),
      ),
    );
  }
}

// Removed: _NotificationRecord class
// Removed: Day enum and extension

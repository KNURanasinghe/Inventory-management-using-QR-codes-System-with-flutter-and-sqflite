import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qrapp/Components/add_item_from.dart';
import 'package:qrapp/Config/database_helper.dart';
import 'package:qrapp/Screens/qr_scan.dart';

class DataShowPage extends StatefulWidget {
  const DataShowPage({super.key});

  @override
  State<DataShowPage> createState() => _DataShowPageState();
}

class _DataShowPageState extends State<DataShowPage> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final dbHelper = DatabaseHelper.instance;
    final items = await dbHelper.fetchAllItems();

    setState(() {
      _items = items;
    });
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemForm(
        onItemAdded: () {
          _loadItems();
        },
      ),
    );
  }



  Future<void> _navigateToQrScanPage() async {
    // Navigate to the QR Scan page and wait for it to close
    final bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScan(),
      ),
    );

    // Reload items if updates occurred
    if (shouldRefresh == true) {
      _loadItems();
    }
  }

    void _showQrCodeDialog(String qrCodePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(qrCodePath), height: 200, width: 200),
            const SizedBox(height: 20),
            const Text('This is the QR code for the item.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Inventory Items",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: [
            Row(
              children: [
                IconButton(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(
                    Icons.add_box,
                    color: Colors.blue,
                    size: 27,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                IconButton(
                    onPressed: _navigateToQrScanPage,
                    icon: const Icon(Icons.qr_code_scanner))
              ],
            )
          ],
        ),
        body: _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return GestureDetector(
                    onTap: (){
                      _showQrCodeDialog(item['qr_code_path']);
                    },
                    child: ListTile(
                      title: Text(item['name']),
                      subtitle: Text(
                          'code: ${item['code']} -quantity: ${item['quantity']}'),
                      trailing: IconButton(
                        onPressed: () async {
                          await DatabaseHelper.instance
                              .removeItem(item['code']);
                          _loadItems();
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }));
  }
}

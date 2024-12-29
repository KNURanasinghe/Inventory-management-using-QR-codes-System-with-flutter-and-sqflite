import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrapp/Config/database_helper.dart';

class QrScan extends StatefulWidget {
  const QrScan({super.key});

  @override
  State<QrScan> createState() => _QrScanState();
}

class _QrScanState extends State<QrScan> {
  Map<String, dynamic>? _item;

  Future<void> _fetchItemByCode(String code) async {
    final dbHelper = DatabaseHelper.instance;
    final item = await dbHelper.fetchItemByCode(code);
    setState(() {
      _item = item;
    });
  }

  Future<void> _updateItemQuantityInDb(String code, int quantity) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.updateItemQuantity(code, quantity);
  }

  void _showItemDialog(String code) async {
    await _fetchItemByCode(code);

    if (_item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item not found in database!')),
      );
      return;
    }

    int temporaryQuantity = _item?['quantity'] ?? 0; // Initialize temporary quantity

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text("Update Item: ${_item?['name']}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Code: ${_item?['code']}'),
                  const SizedBox(height: 10),
                  Text('Current Quantity: $temporaryQuantity'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            temporaryQuantity += 1;
                          });
                        },
                        child: const Text('Increase'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            if (temporaryQuantity > 0) {
                              temporaryQuantity -= 1;
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Quantity cannot be less than zero!')),
                              );
                            }
                          });
                        },
                        child: const Text('Decrease'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    _updateItemQuantityInDb(code, temporaryQuantity);
                    // Close dialog
                    Navigator.of(context).pop(true); // Notify to refresh
                  },
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog without saving
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Scan QR Code",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 27),
        ),
      ),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates
        ),
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue ?? "";
          _showItemDialog(code);
        },
      ),
    );
  }
}

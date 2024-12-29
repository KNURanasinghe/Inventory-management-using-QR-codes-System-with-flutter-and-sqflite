import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../config/database_helper.dart';

class AddItemForm extends StatefulWidget {
  final Function onItemAdded;
  const AddItemForm({super.key, required this.onItemAdded});

  @override
  State<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _qrKey = GlobalKey();

  String? name;
  String? code;
  int? quantity;


  bool _isAdded = false;

  Future<void> _downloadQRCode() async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception("Storage permission is required to save QR code");
        }
      }

      // Get the boundary of the QR code widget
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("QR Code widget is not rendered yet.");
      }

      // Capture the QR code as an image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to generate image data");
      }

      // Get the directory
      final Directory directory = await getApplicationDocumentsDirectory();

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = "${directory.path}/QR_${code ?? 'code'}_$timestamp.png";
      final file = File(filePath);

      // Write the file
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Show success message
      if (!context.mounted) return;
      print("QR code saved to: $filePath");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("QR code saved to: $filePath"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print("Failed to save QR code: ${e.toString()}");
      // Show error message
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save QR code: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isAdded ? 'QR Code Generated' : 'Add New Item'),
      content: _isAdded
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Item added successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _qrKey,
                  child: PrettyQr(
                    data: code!,
                    size: 200,
                    errorCorrectLevel: QrErrorCorrectLevel.M,
                  ),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Item Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an item name';
                        }
                        return null;
                      },
                      onSaved: (value) => name = value,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Item Code'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an item code';
                        }
                        return null;
                      },
                      onSaved: (value) => code = value,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Please enter a valid quantity';
                        }
                        return null;
                      },
                      onSaved: (value) => quantity = int.tryParse(value!),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        if (_isAdded)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('Close'),
          ),
        if (_isAdded)
          ElevatedButton(
            onPressed: _downloadQRCode,
            child: const Text('Download QR'),
          ),
        if (!_isAdded) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                // Add the item to the database
                await DatabaseHelper.instance
                    .addItem(name!, code!, quantity!);

                // Notify the parent widget about the new item
                widget.onItemAdded();

                // Show the QR code after adding the item
                setState(() {
                  _isAdded = true;
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../config/database_helper.dart';

class AddItemForm extends StatefulWidget {
  final Function onItemAdded;
  final String qrPath;
  const AddItemForm({super.key, required this.onItemAdded, required this.qrPath});

  @override
  State<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? code;
  int? quantity;

  bool _isAdded = false;

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
                PrettyQr(
                  data: code!,
                  size: 200,
                  errorCorrectLevel: QrErrorCorrectLevel.M,
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
              Navigator.of(context).pop(); // Close dialog after showing QR
            },
            child: const Text('Close'),
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

                // Add the item to the database.
                await DatabaseHelper.instance.addItem(
                  name!,
                  code!,
                  quantity!,
                );

                // Notify the parent widget about the new item.
                widget.onItemAdded();

                // Show the QR code after adding the item.
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

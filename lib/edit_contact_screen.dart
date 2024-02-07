// edit_contact_screen.dart

import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';

class EditContactScreen extends StatefulWidget {
  final CallLogEntry callLogEntry;

  EditContactScreen({
    required this.callLogEntry,
  });

  @override
  _EditContactScreenState createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.callLogEntry.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Contact Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Contact Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveChanges();
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    // Implement logic to save the edited contact information
    widget.callLogEntry.name = _nameController.text;

    // Return the modified entry to the calling screen (CallLogScreen)
    Navigator.pop(context, widget.callLogEntry);
  }
}

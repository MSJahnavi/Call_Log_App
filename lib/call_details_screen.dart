// call_details_screen.dart

import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';

class CallDetailsScreen extends StatelessWidget {
  final CallLogEntry callLogEntry;

  CallDetailsScreen({required this.callLogEntry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caller Name: ${callLogEntry.name ?? 'Unknown Caller'}',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            Divider(),
            Text(
              'Phone Number: ${callLogEntry.number}',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            Text(
              'Duration: ${_formatDuration(callLogEntry.duration)}',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            Text(
              'Timestamp: ${DateTime.fromMillisecondsSinceEpoch(callLogEntry.timestamp ?? 0)}',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int? duration) {
    if (duration == null) return 'Unknown';

    int minutes = (duration / 60).floor();
    int seconds = duration % 60;

    return '$minutes min ${seconds} sec';
  }
}

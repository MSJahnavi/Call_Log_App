import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'call_details_screen.dart';
import 'edit_contact_screen.dart';
import 'dart:math' as math;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Log Access App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          headline6: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          bodyText1: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
      home: CallLogScreen(),
    );
  }
}

class CallLogScreen extends StatefulWidget {
  @override
  _CallLogScreenState createState() => _CallLogScreenState();
}

class _CallLogScreenState extends State<CallLogScreen> {
  static List<CallLogEntry> callLogs = [];
  List<CallLogEntry> filteredCallLogs = [];
  CallLogEntry? tappedCallLogEntry;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestCallLogPermission();
  }

  Future<void> _requestCallLogPermission() async {
    await Permission.phone.request().then((status) {
      if (status.isGranted) {
        _getCallLogs();
      } else {
        // Handle the case when permission is denied
        // You can show a dialog or display a message to the user
      }
    });
  }

  Future<void> _getCallLogs() async {
    Iterable<CallLogEntry> entries = await CallLog.get();
    setState(() {
      callLogs = entries.toList();
      filteredCallLogs = callLogs; // Initialize filtered list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Call Log', style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  _filterCallLogs(value);
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: _buildCallLogList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallLogList() {
    callLogs.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

    Map<String, List<CallLogEntry>> groupedCallLogs =
        _groupCallLogsByDate(filteredCallLogs);

    return ListView.builder(
      itemCount: groupedCallLogs.length,
      itemBuilder: (context, index) {
        String heading = groupedCallLogs.keys.elementAt(index);
        List<CallLogEntry> entries = groupedCallLogs[heading]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeading(heading),
            for (CallLogEntry entry in entries) ...[
              ListTile(
                leading: _buildCircleAvatar(entry.name),
                title: Text(
                  entry.name != null && entry.name!.isNotEmpty
                      ? entry.name!
                      : 'Unknown Caller',
                  style: TextStyle(
                    color: _getTextColor(entry.callType),
                  ),
                ),
                trailing: _buildLeadingIcon(entry.callType),
                onTap: () {
                  _toggleOptionsDialog(entry);
                },
              ),
              if (tappedCallLogEntry == entry) ...[
                Divider(
                  color: Colors.white,
                ),
                _buildOptionsDialog(context, entry),
              ],
              Divider(
                color: Colors.black,
              ),
            ],
          ],
        );
      },
    );
  }

  Color _getTextColor(CallType? callType) {
    if (callType != CallType.incoming && callType != CallType.outgoing) {
      return Colors.red;
    }
    return Colors.black;
  }

  Widget _buildHeading(String heading) {
    Color fontColor = Colors.black;
    if (heading == 'Yesterday' ||
        heading == 'Today' ||
        _isDateHeading(heading)) {
      fontColor = Colors.black;
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        heading,
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: fontColor),
      ),
    );
  }

  Widget _buildOptionsDialog(BuildContext context, CallLogEntry callLogEntry) {
    return Container(
      color: Colors.white,
      child: GestureDetector(
        onTap: () {
          setState(() {
            tappedCallLogEntry = null;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () {
                _navigateToEditContactScreen(context, callLogEntry);
              },
              child: Text('Edit'),
            ),
            ElevatedButton(
              onPressed: () {
                _navigateToHistoryScreen(context, callLogEntry);
              },
              child: Text('History'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleOptionsDialog(CallLogEntry entry) {
    setState(() {
      if (tappedCallLogEntry == entry) {
        tappedCallLogEntry = null;
      } else {
        tappedCallLogEntry = entry;
      }
    });
  }

  void _navigateToEditContactScreen(
      BuildContext context, CallLogEntry callLogEntry) async {
    final updatedEntry = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditContactScreen(
          callLogEntry: callLogEntry,
        ),
      ),
    );

    if (updatedEntry != null) {
      _updateCallLogsList(updatedEntry);
    }
  }

  void _navigateToHistoryScreen(
      BuildContext context, CallLogEntry callLogEntry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallDetailsScreen(callLogEntry: callLogEntry),
      ),
    );
  }

  void _updateCallLogsList(CallLogEntry modifiedEntry) {
    setState(() {
      int index = callLogs
          .indexWhere((entry) => entry.hashCode == modifiedEntry.hashCode);
      if (index != -1) {
        callLogs[index] = modifiedEntry;
        // Update filtered list as well
        filteredCallLogs[index] = modifiedEntry;
      }
    });
  }

  Map<String, List<CallLogEntry>> _groupCallLogsByDate(
      List<CallLogEntry> callLogs) {
    Map<String, List<CallLogEntry>> groupedCallLogs = {};

    for (var entry in callLogs) {
      DateTime logDate = DateTime.fromMillisecondsSinceEpoch(entry.timestamp!);

      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime yesterday = today.subtract(Duration(days: 1));

      if (logDate.isAfter(today)) {
        // Today
        _addToGroup(groupedCallLogs, 'Today', entry);
      } else if (logDate.isAfter(yesterday)) {
        // Yesterday
        _addToGroup(groupedCallLogs, 'Yesterday', entry);
      } else {
        // Other dates
        String dateString = _formatDateString(logDate);
        _addToGroup(groupedCallLogs, dateString, entry);
      }
    }

    return groupedCallLogs;
  }

  void _addToGroup(Map<String, List<CallLogEntry>> groupedCallLogs,
      String group, CallLogEntry entry) {
    if (!groupedCallLogs.containsKey(group)) {
      groupedCallLogs[group] = [];
    }
    groupedCallLogs[group]!.add(entry);
  }

  String _formatDateString(DateTime date) {
    // You can customize the date formatting based on your preference
    return '${_getDayOfWeek(date.weekday)}, ${date.day} ${_getMonth(date.month)}';
  }

  String _getDayOfWeek(int day) {
    List<String> daysOfWeek = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return daysOfWeek[day - 1];
  }

  String _getMonth(int month) {
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildCircleAvatar(String? name) {
    String initial =
        name != null && name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return CircleAvatar(
      backgroundColor: Colors.blue, // You can customize the color
      child: Text(
        initial,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  bool _isDateHeading(String heading) {
    return heading.contains(RegExp(r'^[A-Za-z]{3,9}, [0-9]+ [A-Za-z]{3,9}$'));
  }

  void _filterCallLogs(String query) {
    setState(() {
      if (query.isNotEmpty) {
        // Filter callLogs based on the search query
        filteredCallLogs = callLogs
            .where((log) =>
                log.name?.toLowerCase().contains(query.toLowerCase()) ?? false)
            .toList();
      } else {
        // If the query is empty, show all callLogs
        filteredCallLogs = callLogs;
      }
    });
  }

  Widget _buildLeadingIcon(CallType? callType) {
    Color backgroundColor;
    IconData icon;
    double rotationAngle;

    switch (callType) {
      case CallType.incoming:
        backgroundColor = Colors.blue;
        icon = Icons.arrow_forward;
        rotationAngle = 135 * math.pi / 180; // 45 degrees right upward arrow
        break;
      case CallType.outgoing:
        backgroundColor = Colors.green;
        icon = Icons.arrow_back;
        rotationAngle = 135 * math.pi / 180; // 45 degrees left upward arrow
        break;
      default:
        backgroundColor = Colors.red; // Red color for missed calls
        icon = Icons.phone;
        rotationAngle = 0; // No rotation for missed or other call types
        break;
    }

    return SizedBox(
      width: 24, // Adjust the width according to your preference
      child: Transform.rotate(
        angle: rotationAngle,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    );
  }
}

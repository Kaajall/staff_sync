import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssignMissionScreen extends StatefulWidget {
  @override
  _AssignMissionScreenState createState() => _AssignMissionScreenState();
}

class _AssignMissionScreenState extends State<AssignMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedStaffId;
  String locationName = '';
  List<dynamic> staffList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadStaff();
  }

  Future<void> loadStaff() async {
    try {
      final data = await ApiService.getAllStaff();
      setState(() {
        staffList = data;
      });
    } catch (e) {
      print("Failed to load staff list: $e");
    }
  }

  Future<void> assignMission() async {
    final url = Uri.parse('${ApiService.baseUrl}/missions');
    final body = {
      'staff_id': selectedStaffId,
      'name': locationName,
    };

    setState(() => isLoading = true);
    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text('Mission assigned successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Pop AssignMissionScreen, return success
                },
                child: Text('OK'),
              ),
            ],
          ),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign mission.')),
        );
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign New Mission')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedStaffId,
                items: staffList.map<DropdownMenuItem<String>>((staff) {
                  return DropdownMenuItem<String>(
                    value: staff['id'].toString(),
                    child: Text('${staff['name']} (ID: ${staff['id']})'),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Select Staff'),
                onChanged: (value) => setState(() => selectedStaffId = value),
                validator: (value) =>
                value == null ? 'Please select a staff member' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Enter Location Name'),
                onChanged: (value) => locationName = value,
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter a location' : null,
              ),
              SizedBox(height: 24),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    assignMission();
                  }
                },
                child: Text('Assign Mission'),
              ),


            ],

          ),
        ),
      ),
    );
  }
}

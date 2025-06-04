import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../screens/missions.dart';
import '../screens/assign_missions.dart';
import 'dart:async';

class Admin extends StatefulWidget {
  @override
  _AdminState createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  List<dynamic> staffList = [];
  List<dynamic> filteredStaffList = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    try {
      final data = await ApiService.getAllStaff();
      setState(() {
        staffList = data;
        filteredStaffList = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterStaff(String query) {
    final filtered = staffList.where((staff) {
      final username = staff['username']?.toLowerCase() ?? '';
      return username.contains(query.toLowerCase());
    }).toList();

    setState(() {
      searchQuery = query;
      filteredStaffList = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Staff List')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: filterStaff,
              decoration: InputDecoration(
                hintText: 'Search Staff',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredStaffList.length,
              itemBuilder: (context, index) {
                final staff = filteredStaffList[index];
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(staff['username'] ?? 'Unknown'),
                    subtitle: Text('ID: ${staff['id']}'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MissionScreen(staffId: staff['id'], role: 'admin'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AssignMissionScreen()),
          );
          if (result == true) {
            fetchStaff();
          }
        },
        icon: Icon(Icons.add),
        label: Text('Assign Mission'),
      ),
    );
  }
}

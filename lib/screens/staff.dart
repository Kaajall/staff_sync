import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'missions.dart';
import '../services/api_services.dart';


class StaffScreen extends StatefulWidget {
  final String staffId;
  const StaffScreen({Key? key, required this.staffId}) : super(key: key);


  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isMissionDrawerOpen = false;

  List<Map<String, dynamic>> targetLocations = [];
  bool _isLoadingMissions = true;




  Set<Marker> _createTargetMarkers() {
    return targetLocations.map((loc) {
      return Marker(
        markerId: MarkerId(loc['name']),
        position: LatLng(loc['lat'], loc['lng']),
        infoWindow: InfoWindow(title: loc['name']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();
  }
  Widget _buildBottomIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: Colors.black87),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }




  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    print("🧩 StaffScreen loaded with staffId: ${widget.staffId}");
    _fetchMissions(widget.staffId);
  }

  Future<void> _fetchMissions(String staffId) async {
    try {
      print("Fetching missions using ApiService for staffId: $staffId");
      final missions = await ApiService.getMissions(staffId);
      setState(() {
        targetLocations = missions.map((e) => {
          'name': e['name'],
          'lat': e['latitude'],
          'lng': e['longitude'],
        }).toList();
        _isLoadingMissions = false;
      });
      print("Missions fetched successfully: $targetLocations");
    } catch (e) {
      print('Error fetching missions: $e');
      setState(() {
        _isLoadingMissions = false;
      });
    }
  }


  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        16,
      ));
    }
  }


  void _focusOnAllMissions() {
    if (targetLocations.isEmpty || _mapController == null) return;

    LatLngBounds bounds;
    final latitudes = targetLocations.map((loc) => loc['lat'] as double);
    final longitudes = targetLocations.map((loc) => loc['lng'] as double);

    final southwest = LatLng(latitudes.reduce((a, b) => a < b ? a : b),
        longitudes.reduce((a, b) => a < b ? a : b));
    final northeast = LatLng(latitudes.reduce((a, b) => a > b ? a : b),
        longitudes.reduce((a, b) => a > b ? a : b));

    bounds = LatLngBounds(southwest: southwest, northeast: northeast);

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }



  void _openMissionDrawer() {
    setState(() {
      _isMissionDrawerOpen = true;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _buildMissionDrawer(),
    );
  }

  Widget _buildMissionDrawer() {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      builder: (_, controller) {
        return ListView.builder(
          controller: controller,
          itemCount: targetLocations.length,
          itemBuilder: (_, index) {
            final loc = targetLocations[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent.shade100,
                child: Icon(Icons.place, color: Colors.white),
              ),
              title: Text(
                loc['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.location_on, color: Colors.blueAccent),
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(loc['lat'], loc['lng']),
                          17,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: () {
                      Navigator.pop(context);
                      _openSecondaryDrawer(loc);
                    },
                  ),
                ],
              ),
            );

          },
        );
      },
    );
  }

  void _openSecondaryDrawer(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Remarks for ${location['name']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your remarks...',
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add snap logic
                  },
                  icon: Icon(Icons.camera_alt_rounded),
                  label: Text('Take Picture'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _currentPosition == null || _isLoadingMissions
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            markers: _createTargetMarkers(),
          ),

          // bottom bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                height: 70,
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBottomIcon(Icons.map, "My Location", () {
                      if (_currentPosition != null && _mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            16,
                          ),
                        );
                      }
                    }),
                    _buildBottomIcon(Icons.center_focus_strong, "Focus", _focusOnAllMissions),
                    _buildBottomIcon(Icons.menu, "Missions", _openMissionDrawer),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

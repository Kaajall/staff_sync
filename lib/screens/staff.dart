import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'missions.dart';
import '../services/api_services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;



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
  bool isWithinRange = false;


  List<Map<String, dynamic>> targetLocations = [];
  bool _isLoadingMissions = true;




  Set<Marker> _createTargetMarkers() {
    return targetLocations
        .where((loc) => loc['status'] != 'completed')
        .map((loc) => Marker(
      markerId: MarkerId(loc['name']),
      position: LatLng(loc['lat'], loc['lng']),
      infoWindow: InfoWindow(title: loc['name']),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ))
        .toSet();
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
          'id': e['id'],
          'name': e['name'],
          'lat': e['latitude'],
          'lng': e['longitude'],
          'status': e['status'], // ✅ Make sure 'status' is in your API response
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
    final pendingLocations = targetLocations.where((m) => m['status'] != 'completed').toList();
    if (pendingLocations.isEmpty || _mapController == null) return;
    // Calculate bounds for all pending locations
    final latitudes = pendingLocations.map((loc) => loc['lat'] as double);
    final longitudes = pendingLocations.map((loc) => loc['lng'] as double);
    final southwest = LatLng(
      latitudes.reduce((a, b) => a < b ? a : b),
      longitudes.reduce((a, b) => a < b ? a : b),
    );

    final northeast = LatLng(
      latitudes.reduce((a, b) => a > b ? a : b),
      longitudes.reduce((a, b) => a > b ? a : b),
    );

    final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

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
        final pendingMissions = targetLocations.where((m) => m['status'] != 'completed').toList();
        return ListView.builder(
          controller: controller,
          itemCount: pendingMissions.length,
          itemBuilder: (_, index) {
            final loc = pendingMissions[index];
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
                      _checkProximity(loc['lat'], loc['lng']).then((_) {
                        _openSecondaryDrawer(loc);
                      });

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
  Future<File?> _takePictureAndSave() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);

      if (pickedFile == null) return null; // User cancelled

      final tempImage = File(pickedFile.path);
      final appDir = await getApplicationDocumentsDirectory();
      final uploadsDir = Directory('${appDir.path}/uploads');

      // Create uploads dir if it doesn't exist
      if (!await uploadsDir.exists()) {
        await uploadsDir.create(recursive: true);
      }

      final fileName = path.basename(pickedFile.path);
      final savedImage = await tempImage.copy('${uploadsDir.path}/$fileName');

      return savedImage;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  Future<void> _checkProximity(double targetLat, double targetLng) async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLat,
      targetLng,
    );

    setState(() {
      isWithinRange = distanceInMeters <= 200;
    });
  }


  void _openSecondaryDrawer(Map<String, dynamic> location) {
    final TextEditingController remarksController = TextEditingController();
    File? capturedPhoto;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Helper to check if submit can be enabled
            bool canSubmit = capturedPhoto != null && remarksController.text.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 30,
              ),
              child: SingleChildScrollView(
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
                      'Complete Mission: ${location['name']}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Add remarks and capture a photo to submit the mission.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        labelText: 'Remarks',
                        hintText: 'Enter your remarks here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      maxLines: 3,
                      onChanged: (_) => setState(() {}), // To update Submit button enable state
                    ),
                    SizedBox(height: 20),

                    // Photo preview or placeholder
                    GestureDetector(
                      onTap: isWithinRange
                          ? () async {
                        final photo = await _takePictureAndSave();
                        if (photo != null) {
                          setState(() {
                            capturedPhoto = photo;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Photo not captured.")),
                          );
                        }
                      }
                          : null,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade400),
                          color: Colors.grey.shade100,
                          boxShadow: capturedPhoto != null
                              ? [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ]
                              : [],
                        ),
                        child: capturedPhoto == null
                            ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                isWithinRange
                                    ? 'Tap to take picture'
                                    : 'You must be within 200 meters to take a picture',
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            capturedPhoto!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canSubmit && !isSubmitting
                            ? () async {
                          setState(() => isSubmitting = true);

                          // Call API to complete mission
                          await ApiService.completeMission(
                            missionId: location['id'].toString(),
                            staffId: widget.staffId.toString(),
                            remarks: remarksController.text.trim(),
                            photoFile: capturedPhoto!,
                          );

                          setState(() => isSubmitting = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Mission marked as complete.")),
                          );

                          Navigator.pop(context); // Close drawer

                          // Refresh missions on main screen
                          _fetchMissions(widget.staffId);
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: canSubmit ? Colors.orange : Colors.grey.shade400,
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                            : Text('Submit Mission'),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
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


import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:geolocator/geolocator.dart';




class MissionScreen extends StatefulWidget {
  final dynamic staffId;
  final String role;

  const MissionScreen({required this.staffId, required this.role, Key? key}) : super(key: key);

  @override
  _MissionScreenState createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  List<dynamic> missions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMissions();
  }

  Future<void> fetchMissions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.getMissions(widget.staffId.toString());
      if (data is List && data.every((e) => e is Map)) {
        setState(() {
          missions = data;
          isLoading = false;
        });
      } else {
        throw Exception("Unexpected data format from API");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        missions = [];
      });
    }
  }




  Future<void> _showSubmitDialog(Map<String, dynamic> mission) async {
    final TextEditingController remarksController = TextEditingController();


    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Complete Mission: ${mission['name'] ?? ''}'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  TextField(
                    controller: remarksController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cancel
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Step 1: Check and request location permission
                    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!serviceEnabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location services are disabled.')),
                      );
                      return;
                    }

                    LocationPermission permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.denied) {
                      permission = await Geolocator.requestPermission();
                      if (permission == LocationPermission.denied) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location permissions are denied')),
                        );
                        return;
                      }
                    }

                    if (permission == LocationPermission.deniedForever) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location permissions are permanently denied')),
                      );
                      return;
                    }

                    // Step 2: Get current location
                    Position currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

                    // Step 3: Get mission coordinates
                    final double? missionLat = (mission['latitude'] as num?)?.toDouble();
                    final double? missionLng = (mission['longitude'] as num?)?.toDouble();

                    if (missionLat == null || missionLng == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mission location data is invalid.')),
                      );
                      return;
                    }

                    // Step 4: Calculate distance
                    double distance = Geolocator.distanceBetween(
                      missionLat,
                      missionLng,
                      currentPosition.latitude,
                      currentPosition.longitude,
                    );

                    if (distance > 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Too far from mission location (Distance: ${distance.toStringAsFixed(1)} m). Must be within 200 meters.'),
                        ),
                      );
                      return;
                    }

                    // Step 5: Proceed with mission completion
                    Navigator.pop(context); // Close dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );



                    Navigator.pop(context); // Close loading dialog
                    fetchMissions(); // Refresh missions
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mission marked as completed')),
                    );
                  } catch (e) {
                    Navigator.pop(context); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Missions')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : missions.isEmpty
          ? const Center(child: Text('No missions available'))
          : ListView.builder(
        itemCount: missions.length,
        itemBuilder: (context, index) {
          final mission = missions[index] as Map<String, dynamic>?;

          if (mission == null) {
            return const ListTile(title: Text("Invalid mission data"));
          }

          final name = mission['name']?.toString() ?? 'Unnamed Mission';
          final latValue = mission['latitude'];
          final lngValue = mission['longitude'];
          final lat = latValue is num ? latValue.toStringAsFixed(6) : 'N/A';
          final lng = lngValue is num ? lngValue.toStringAsFixed(6) : 'N/A';
          final status = mission['status'] ?? 'unknown';
          final remarks = mission['remarks'] ?? '';
          final imageUrl = mission['image_url'] ?? '';

          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Lat: $lat, Lng: $lng'),
                  const SizedBox(height: 4),
                  Text('Status: ${status.toString().toUpperCase()}'),
                  if (remarks.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Remarks: $remarks'),
                    ),
                  if (imageUrl.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}

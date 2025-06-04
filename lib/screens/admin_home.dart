import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_services.dart';
import 'missions.dart';
import 'admin.dart';
import 'dart:ui' as ui;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'missions.dart';



class AdminHome extends StatefulWidget {
  @override
  _AdminHome createState() => _AdminHome();
}

class _AdminHome extends State<AdminHome> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  List<dynamic> staffList = [];
  bool isLoading = true;
  Timer? _refreshTimer;
  final int refreshIntervalSeconds = 10; // Adjust as needed


  @override
  void initState() {
    super.initState();
    fetchStaffData();
    _refreshTimer = Timer.periodic(Duration(seconds: refreshIntervalSeconds), (timer) {
      fetchStaffData(); // refresh periodically
    });
  }
  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }


  Future<BitmapDescriptor> getMarkerIconFromUrl(String imageUrl, {int size = 150}) async {
    try {
      // Use the default image if the imageUrl is null or empty
      if (imageUrl.isEmpty) {
        imageUrl = 'https://your-server.com/uploads/default_marker.png'; // Or your fallback image URL
      }

      final file = await DefaultCacheManager().getSingleFile(imageUrl);
      final Uint8List imageBytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes, targetWidth: size);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final Paint paint = Paint()..isAntiAlias = true;

      // Draw circular image
      final double radius = size / 2;
      final Rect rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius);

      canvas.drawCircle(Offset(radius, radius), radius, paint);
      paint.shader = ImageShader(image, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage);
      canvas.drawCircle(Offset(radius, radius), radius, paint);

      // Optional: white border
      final Paint border = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..isAntiAlias = true;
      canvas.drawCircle(Offset(radius, radius), radius, border);

      final img = await recorder.endRecording().toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(buffer);
    } catch (e) {
      print("Image load failed, using fallback. Error: $e");
      final ByteData data = await rootBundle.load('assets/default_marker.png');  // Using local fallback asset
      return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
    }
  }



  Future<void> fetchStaffData() async {
    try {
      final data = await ApiService.getAllStaff();
      List<Marker> newMarkers = [];

      for (var staff in data) {
        final lat = staff['latitude'] as double?;
        final lng = staff['longitude'] as double?;
        final photoUrl = staff['photoUrl'] ?? 'https://via.placeholder.com/150';

        if (lat != null && lng != null) {
          final icon = await getMarkerIconFromUrl(photoUrl);

          newMarkers.add(
            Marker(
              markerId: MarkerId(staff['id'].toString()),
              position: LatLng(lat, lng),
              icon: icon,
              infoWindow: InfoWindow(
                title: staff['username'] ?? 'Unknown',
                snippet: 'Tap for details',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MissionScreen(staffId: staff['id'], role: 'admin'),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }

      setState(() {
        staffList = data;
        _markers = newMarkers.toSet();
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load staff data. Please try again.')),
      );
    }
  }


  void _focusOnStaff(double lat, double lng) {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Staff Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.people),
            tooltip: 'View Full Staff List',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => Admin(),
              ));
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(20.5937, 78.9629),
              zoom: 4.5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.all(8),
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return GestureDetector(
                  onTap: () {
                    if (staff['latitude'] != null && staff['longitude'] != null) {
                      _focusOnStaff(staff['latitude'], staff['longitude']);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MissionScreen(staffId: staff['id'], role: 'admin'),
                      ),
                    );

                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 160,
                      padding: EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: (staff['photoUrl'] != null && staff['photoUrl'].toString().isNotEmpty)
                                ? CachedNetworkImageProvider(staff['photoUrl'])
                                : AssetImage('assets/default_marker.png'),
                          ),

                          SizedBox(height: 4),
                          Text(
                            staff['username'] ?? 'Unknown',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          SizedBox(height: 2),
                          Text(
                            'ID: ${staff['id']}',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            '📍 ${staff['locationName'] ?? 'Location unknown'}',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),

    );
  }
}

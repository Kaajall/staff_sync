import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/wave_bg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'admin_home.dart';
import 'staff.dart';
import 'dart:convert';
import 'register.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
  const LoginScreen({super.key});
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailOrPhoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;


  void loginUser() async {
    try {
      final response = await ApiService.loginUser(
          emailOrPhoneController.text,
          passwordController.text
      );
      print("Login response: $response");





      // Save tokens
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('accessToken', response['accessToken']);
      await prefs.setString('refreshToken', response['refreshToken']);


      // Decode the accessToken to extract the role
      final accessToken = response['accessToken'];
      final payload = accessToken.split('.')[1];
      final normalized = base64Url.normalize(payload);
      final decodedPayload = json.decode(utf8.decode(base64Url.decode(normalized)));

      print("Decoded payload: $decodedPayload");
      final role = decodedPayload['role'];
      await prefs.setString('role', role);
      print("Decoded role: $role");
      final String loggedInStaffId = decodedPayload['id'].toString(); // ✅ Get ID
      await prefs.setString('staffId', loggedInStaffId);
      print("Logged in staff ID: $loggedInStaffId");



      // Ensure the widget is still mounted before accessing context
      if (!mounted) return;

      // Use rootNavigator for SnackBar inside Dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Successful!")),
      );

      Navigator.of(context).pop(); // Close the login dialog

      // Navigate based on role
      if (role == 'staff') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StaffScreen(staffId: loggedInStaffId)),
          );
        });
      } else if (role == 'admin') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminHome()),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid role!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: $e")),
      );
    }
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          Positioned.fill(child: WaveBackground()),
          // Card
          Center(
            child: Container(
              margin: const EdgeInsets.fromLTRB(30, 30, 30, 30),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.shade800,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("LOGIN", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  SizedBox(height: 20),
                  TextField(
                    controller: emailOrPhoneController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      prefixIcon: Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                  SizedBox(height: 16),


                  // Password Field
                  TextField(
                    controller: passwordController,
                    obscureText:  _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () { print("Login button pressed"); // 🐛 Debug
                    loginUser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("CONTINUE",
                    textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18,color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Toggle to Register
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close current popup
                      showDialog(
                        context: context,
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.transparent,
                          body: RegisterScreen(),
                        ),
                      );
                    },
                    child: Text("Don't have an account? Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:flutter_launcher_icons/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nostos/AdminLogin.dart';
import 'package:nostos/AdminPanel.dart';
import 'package:nostos/LoadingScreen.dart';
import 'package:nostos/main.wrapper.dart';
import 'package:nostos/user.wrapper.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nostos/user_id.dart' as globals;

import 'package:nostos/Break.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:nostos/termAndConditions.dart';

import 'AdminPanelMobile.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  late IO.Socket? socket;
  final tx = TextEditingController();
  final pwd = TextEditingController();
  String id = "";
  String password = "";

 String url = "http://192.168.1.2:5000";
  //String url = "https://server-render-mbl1.onrender.com";
  //String url = "https://server-render-low-ping.onrender.com";
  //String url = "http://5.172.195.146:5000";
  //String url = "https://noninterruptive-suprarational-ruby.ngrok-free.dev";

  String message = "";
  bool connect = false;
  bool showsnackbar = false;
  bool exists = false;
  bool isLoading = false;
  final secureStorage = FlutterSecureStorage();

  late final AnimationController _controller;

  String baseUrl = '';

  Future<void> getUrl() async {
    final response = await http.post(
      Uri.parse('https://nostosapi.onrender.com/url'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': 'John', 'userid': '123'}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        baseUrl = (data['URL'] ?? '').toString().trim();
      });
      print('URL loaded: $baseUrl');
    }
  }

  Future<void> close() async {
    socket?.off("login_response");
    socket?.off("Admin_Login");
    socket?.disconnect();
    socket?.dispose();

    tx.dispose();
    pwd.dispose();
    _controller.dispose();

    await Future.delayed(const Duration(milliseconds: 3000));
    await FlutterExitApp.exitApp();
    exit(0);
  }

  Future<void> get_Volume() async {
    String? savedVolume = await secureStorage.read(key: 'NostosVolume');
    if (savedVolume != null) {
      globals.volume = double.parse(savedVolume);
    } else {
      print("No Volume Retreived");
    }
  }

  Future<void> remember_me(String user_id, String password, bool exists) async {
    if (exists == true) {
      String? savedUserId = await secureStorage.read(key: 'userId');
      String? savedPassword = await secureStorage.read(key: 'NostosPassword');
      String? savedToken = await secureStorage.read(key: 'NostosToken'); // ✅ FIXED: was reading 'NostosPassword' before

      print("Saved User ID: $savedUserId");

      if (savedUserId != null && savedPassword != null && savedUserId.isNotEmpty) {
        globals.userid = savedUserId;
        if (!mounted) return;
        tx.text = globals.userid;
        pwd.text = savedPassword;
        setState(() => isLoading = true);

        socket?.emit("login", {
          "token": savedToken,
          "password": savedPassword,
          "id": globals.userid,
          "mode": globals.State,
          "reconnect": false,
        });

        // ✅ Safety timeout: if server is down or no response in 8s, stop the spinner
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && isLoading) {
            setState(() => isLoading = false);
          }
        });
      }
    } else {
      await secureStorage.write(key: 'userId', value: user_id);
      await secureStorage.write(key: 'NostosPassword', value: password);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat();

    get_Volume();

    socket = IO.io(url, {
      'transports': ['websocket'],
      'force new connection': true,
      'reconnection': true,
      'reconnectionAttempts': 1000,
      'reconnectionDelay': 1000,
    });

    socket?.onReconnect((_) async {
      String? savedPassword = await secureStorage.read(key: 'NostosPassword');
      String? savedToken = await secureStorage.read(key: 'NostosToken'); // ✅ FIXED
      socket?.emit("login", {
        "token": savedToken,
        "password": savedPassword,
        "id": globals.userid,
        "mode": globals.State,
        "reconnect": false,
      });
    });

    socket?.connect();

    remember_me("start", "start", true);

    socket?.off("Admin_Login");
    socket?.on("Admin_Login", (data) {
      if (data["success"] == true) {
        if (!globals.app_open) {
          globals.userid = data["id"];
          globals.name = data["name"];
          globals.token = data['token'];
          secureStorage.write(key: 'NostosToken', value: globals.token);
          if (MediaQuery.of(context).size.width < 850) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminPanelMobile(socket: socket),
                ),
              );
            });
          } else {
            print('pc');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminPanelScreen(socket: socket),
                ),
              );
            });
          }
          globals.app_open = true;
        } else {
          // already open, nothing to do
        }
      } else {
        if (showsnackbar == false) {
          showsnackbar = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text("Wrong or inactive ID"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              ).closed.then((_) => showsnackbar = false);
          });
        }
      }
    });

    socket?.onConnect((_) {
      print("Connected");
    });

    socket?.off("login_response");
    socket?.on("login_response", (data) {
      print("📩 Server says: $data");

      if (data["success"] == true) {
        globals.token = data['token'];
        globals.name = data["name"];
        secureStorage.write(key: 'NostosToken', value: globals.token);
        globals.job = data["job"];

        // ✅ Stop spinner as soon as we get a valid response
        if (mounted && isLoading) {
          setState(() => isLoading = false);
        }

        if (globals.isloggedin == false) {
          globals.isloggedin = true;

          if (data["recon"] == false) {
            if (data["job"] == "user") {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserWrapper(socket: socket, startIndex: 0),
                  ),
                );
              });
            } else if (data["job"] == "groom") {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoadingScreen(socket: socket, mode: 0, indexer: 0),
                  ),
                );
              });
            }
          } else {
            if (globals.app_open == false) {
              printStatus("got here ");
              String received_mode = data["mode"];
              print("📩 Server says: $data");
              int integer_mode = 0;
              switch (received_mode) {
                case 'Requests_List':
                  integer_mode = 0;
                  break;
                case 'Accepted_List':
                  integer_mode = 1;
                  break;
                case 'Break':
                  integer_mode = 1;
                  break;
                case 'ChatPage':
                  integer_mode = 0;
                  break;
                default:
                  integer_mode = 0;
              }

              if (data["job"] == "user") {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserWrapper(socket: socket, startIndex: 0),
                    ),
                  );
                });
              } else if (data["job"] == "groom") {
                if (data['is_breaking'] == true) {
                  globals.is_breaking = true;
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoadingScreen(socket: socket, mode: 0, indexer: integer_mode),
                    ),
                  );
                });
              }

              globals.app_open = true;
            } else {
              print("ACCESSED");
              print(globals.app_open);
              socket?.emit("mode_updater", {
                "user_id": globals.userid,
                "mode": globals.State,
                "token": globals.token,
              });
              socket!.emit("update", {
                "token": globals.token,
                "user_id": globals.userid,
                "mode": globals.State,
              });
              socket!.emit("get_accepted_requests", {
                "user_id": globals.userid,
                "mode": globals.State,
              });
            }
          }
        }
      } else {
        // ✅ Always stop spinner on failure
        if (mounted && isLoading) {
          setState(() => isLoading = false);
        }

        if (data["reason"] == "expired" || data["reason"] == "invalid") {
          globals.token = null;
          secureStorage.delete(key: 'NostosToken');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Session expired, closing..."),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            ).closed.then((_) async {
              await Future.delayed(const Duration(seconds: 2));
              socket?.off("login_response");
              socket?.off("Admin_Login");
              socket?.disconnect();
              socket?.dispose();
              await FlutterExitApp.exitApp();
              exit(0);
            });
          } else {
            socket?.disconnect();
            socket?.dispose();
            exit(0);
          }
          return;
        } else {
          if (showsnackbar == false) {
            showsnackbar = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text("Wrong or inactive ID"),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                ).closed.then((_) => showsnackbar = false);
            });
          }
          message = "User not found";
          connect = false;
        }
      }
    });
  }

  @override
  void dispose() {
    tx.dispose();
    pwd.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/login_image.webp",
              fit: BoxFit.cover,
            ),
          ),
          // 2. Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),
          // 3. Login Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _GlassBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Club Car Dispatch',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'IKOS ODISIA',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.85),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Login",
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            cursorColor: Colors.white,
                            controller: tx,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type User id',
                              hintStyle: GoogleFonts.manrope(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 1.3),
                                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2.0),
                                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                              ),
                              suffixIcon: !isLoading
                                  ? IconButton(
                                      onPressed: () => tx.clear(),
                                      icon: const Icon(Icons.clear, color: Colors.white),
                                    )
                                  : RotationTransition(
                                      turns: _controller,
                                      child: const SizedBox(
                                        width: 5,
                                        height: 5,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 5,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            obscureText: true,
                            cursorColor: Colors.white,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            controller: pwd,
                            decoration: InputDecoration(
                              hintText: 'Type Password',
                              suffixIconColor: Colors.white,
                              hintStyle: GoogleFonts.manrope(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 1.3),
                                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2.0),
                                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                              ),
                              suffixIcon: !isLoading
                                  ? IconButton(
                                      onPressed: () => pwd.clear(),
                                      icon: const Icon(Icons.clear),
                                    )
                                  : RotationTransition(
                                      turns: _controller,
                                      child: const SizedBox(
                                        width: 5,
                                        height: 5,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 5,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 10,
                                backgroundColor: Colors.white.withOpacity(0.15),
                                foregroundColor: Colors.white,
                                shadowColor: Colors.black.withOpacity(0.25),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                id = tx.text;
                                password = pwd.text;
                                globals.userid = id;
                                remember_me(globals.userid, password, false);
                                socket?.emit("login", {
                                  "token": "placeholder",
                                  "auth": true,
                                  "password": password,
                                  "id": globals.userid,
                                  "mode": globals.State,
                                  "reconnect": false
                                });
                              },
                              child: Text(
                                "Enter",
                                style: GoogleFonts.manrope(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          RichText(
                            text: TextSpan(
                              text: "Terms And Conditions",
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => tC()),
                                  );
                                },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const _GlassBox({required this.child, this.width, this.height, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(25),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
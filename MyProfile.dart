import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostos/termAndConditions.dart';
import 'package:nostos/user_id.dart' as globals;
import 'dart:io';
import 'package:flutter_exit_app/flutter_exit_app.dart';

double isMobile = 0;

class MyProfile extends StatefulWidget {
  final IO.Socket? socket;
  const MyProfile({super.key,required this.socket});

  @override
  State<MyProfile> createState() => _GroomProfilePage();
}

class _GroomProfilePage extends State<MyProfile> {
  late List<Map<String, String>> _PersonInfo = [
    {
      "userid":globals.userid,
      "name":globals.name
    }
  ];
  final secureStorage = FlutterSecureStorage();
  Future<void> Logout() async {
    String? savedUserId = globals.userid;
    while(savedUserId == globals.userid){
      //await Future.delayed(Duration(milliseconds: 2000));
      await secureStorage.delete(key: 'userId');
      await secureStorage.delete(key: 'NostosPassword');
      await secureStorage.delete(key: 'NostosToken');
      await Future.delayed(const Duration(milliseconds: 200));
      savedUserId = await secureStorage.read(key: 'userId');
      print(savedUserId);
    }
    await FlutterExitApp.exitApp();
    exit(0);
    /*widget.socket?.close();
    if(isMobile<850){
      await FlutterExitApp.exitApp();
    }
    else{
      exit(0);
    }*/
  }

  Future<void> confirm() async{
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent, // Transparent to let GlassBox show
        insetPadding: const EdgeInsets.all(10), // Small padding from screen edge
        child: Center(
          child: ConstrainedBox(
            // --- LIMIT WIDTH HERE ---
            constraints: const BoxConstraints(maxWidth: 400),

            child: _GlassBox(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Shrink vertically to fit content
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- HEADER ---
                    Text(
                      "Are You Sure?",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))
                          ]
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- ACTION BUTTONS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Cancel Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.red,
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("No", style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 8),

                        // Add Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                            widget.socket?.emit("Logout",{"signal":true,"user_id":globals.userid,"mode":globals.State,"job":globals.job});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.white,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
  }



  @override
  void initState() {
    super.initState();

    //precacheImage(AssetImage("assets/ikos_pool.jpg"), context);

    widget.socket?.off("Logout_Confirmation");
    widget.socket?.on("Logout_Confirmation",(data){

      Logout();

    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND LAYER
          Positioned.fill(
              child: Image.asset("assets/ikos_pool.webp", fit: BoxFit.cover,)
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaY: 5.0, sigmaX: 5.0),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- THE MAIN PROFILE CARD ---
                    SafeArea(
                        child: _GlassBox(
                          width: double.infinity,
                          // No height defined, so it wraps content
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 40, horizontal: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Profile Picture with a border
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    minRadius: 35,
                                    child: Text(
                                      ((_PersonInfo[0]['name']?.isNotEmpty == true)
                                          ? _PersonInfo[0]['name']![0]
                                          : "?"),
                                      style: const TextStyle(color: Colors.white,fontSize: 35),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Username
                                Text(
                                  _PersonInfo[0]["name"]!,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: 1.5,
                                  ),
                                ),

                                // User ID
                                Text(
                                  "@${_PersonInfo[0]["userid"]!}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),

                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        )
                    ),

                    Slider(
                      value: globals.volume,
                      onChanged: (newVolume){
                        setState(() {
                          globals.volume = newVolume;
                        });
                      },
                      onChangeEnd: (value) async {
                        setState(() {
                          globals.audio_player.setVolume(value);
                          secureStorage.write(key: 'NostosVolume', value: value.toString());
                        });
                      },
                      min: 0.0,
                      max: 1.0,
                    ),

                    // --- SECONDARY ACTION BUTTONS (Using GlassBox as buttons) ---
                    SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. The Boxes Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _GlassBox(
                                width: 120,
                                height: 120,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => tC()),
                                  );
                                },
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.policy, color: Colors.black87, size: 30),
                                    SizedBox(height: 8),
                                    Text("Terms & Conditions",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              ),
                              _GlassBox(
                                width: 120,
                                height: 120,
                                onTap: () {
                                  confirm();
                                },
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout, color: Colors.black87, size: 30),
                                    SizedBox(height: 8),
                                    Text("Log Out", style: TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24), // Spacing between the boxes and the footer text

                          // 2. The Powered by NGA Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Powered by  ",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    colors: [Colors.green, Colors.blue],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'NGA',
                                  style: TextStyle(
                                    fontSize: 32.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
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
            constraints: const BoxConstraints(maxWidth: 600),
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
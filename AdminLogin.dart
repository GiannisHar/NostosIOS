import 'package:nostos/AdminPanelMobile.dart';
import 'package:nostos/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostos/termAndConditions.dart';

import 'AdminPanel.dart';

import 'package:nostos/user_id.dart' as globals;

class Adminlogin extends StatefulWidget {
  final IO.Socket? socket;
  const Adminlogin({super.key,required this.socket});

  @override
  State<Adminlogin> createState() => _AdminLoginPage();
}

class _AdminLoginPage extends State<Adminlogin> {

  bool showsnackbar = false;
  final tx = TextEditingController();

  @override
  void dispose() {
    tx.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    widget.socket?.off("Connected");
    widget.socket?.on("Connected",(data){
      if(data["success"] == true){
        //globals.password = tx.text;
        if(MediaQuery.of(context).size.width < 850) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminPanelMobile(socket: widget.socket),
              ),
            );
          });
        } else {
          print('pc');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminPanelScreen(socket: widget.socket),
              ),
            );
          });
        }
      }
      else{
        // Show SnackBar here
        if(showsnackbar == false){
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
              ).closed.then((_) => showsnackbar = false); // reset after dismiss
          });
        }
      }

    });

  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Move background images/gradients to body so Scaffold handles resizing
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/ikos_aerial.webp",
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
                  // STABLE SIZE: Constrain the width for tablets/web
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _GlassBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Admin Panel Login',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 38, // Slightly reduced to fit better
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
                          const Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Confirm Password",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: tx,
                            cursorColor: Colors.white,
                            obscureText: true,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Confirm your password',
                              hintStyle: GoogleFonts.manrope(
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              enabledBorder: const OutlineInputBorder(
                                borderSide:
                                BorderSide(color: Colors.white, width: 2.0),
                                borderRadius:
                                BorderRadius.all(Radius.circular(12.0)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide:
                                BorderSide(color: Colors.white, width: 4.0),
                                borderRadius:
                                BorderRadius.all(Radius.circular(12.0)),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  tx.clear();
                                },
                                icon: const Icon(Icons.clear, color: Colors.white),
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
                                backgroundColor:
                                Colors.white.withOpacity(0.15),
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

                                String id = tx.text;
                                print(id);
                                widget.socket?.emit("admin_password",{"user_id":globals.userid,"password":id,"token":globals.token});
                                /*
                                id = tx.text;

                                globals.userid = id;
                                remember_me(globals.userid, false);
                                // Remove duplicate emit if backend logic is redundant
                                // socket?.emit("login", {"id": id, "amiin": "amiin"});

                                socket?.emit("login", {
                                  "id": globals.userid,
                                  "mode": globals.State,
                                  "reconnect": false
                                });



                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminPanelScreen(
                                      socket: socket,
                                    ),
                                  ),
                                );

                                 */

                              },
                              child: Text(
                                "Enter",
                                style: GoogleFonts.manrope(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
    );  }
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
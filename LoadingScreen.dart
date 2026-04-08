import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nostos/AdminPanel.dart';
import 'package:nostos/Requester_Renewed.dart';
import 'package:nostos/main.wrapper.dart';
import 'package:nostos/user_id.dart' as globals;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatefulWidget {
  late IO.Socket? socket;
  int mode;
  int indexer;
  LoadingScreen({super.key,required this.mode,required this.indexer,required this.socket});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    //switch (widget.mode){
    //groom
      //case 0:
        await Future.wait([
          //gia to break
          precacheImage(const AssetImage("assets/ikos_chill.webp"), context),
          //gia to accepted
          precacheImage(const AssetImage("assets/spa.webp"), context),
          //gia to chat
          precacheImage(const AssetImage("assets/ikos_elia_xriso.webp"), context),
          //gia to profile
          precacheImage(const AssetImage("assets/ikos_pool.webp"), context),
          //gia to main(requests_List_renewed)
          precacheImage(const AssetImage('assets/main_background.webp'), context),
        ]);
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MainWrapper(socket: widget.socket,startIndex: widget.indexer,)),

          );
        }
       // break;
    /*
      case 1:
        await precacheImage(const AssetImage("assets/ikos_purple.jpg"), context);

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AdminPanelScreen(socket: widget.socket)),

          );
        }
        break;
      case 2:
        await precacheImage(const AssetImage("assets/ikos_purple.jpg"), context);

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AdminPanelScreen(socket: widget.socket)),

          );
        }
        break;

     */
    //}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. ΤΑ "ΚΡΥΦΑ" WIDGETS (Rasterization Trigger)
          // Τα τοποθετούμε πίσω από όλα, με σχεδόν μηδενικό opacity
          Opacity(
            opacity: 0.01,
            child: Stack(
              children: [
                Image.asset("assets/ikos_chill.webp"),
                Image.asset("assets/spa.webp"),
                Image.asset("assets/ikos_elia_xriso.webp"),
                Image.asset("assets/ikos_pool.webp"),
                Image.asset("assets/main_background.webp"),
              ],
            ),
          ),

          // 2. ΤΟ ΚΥΡΙΟ UI ΤΗΣ LOADING SCREEN
          Center(
            child: Lottie.asset('assets/amaksaki.json'),
          ),
        ],
      ),
    );
  }
}
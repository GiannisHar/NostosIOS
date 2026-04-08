import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class tC extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => tCstate();
}

class tCstate extends State<tC>{
  @override

  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // screen size
    final width = size.width;
    final height = size.height;

    return Material(
        child: Container(
            child: Stack(children: [
            Positioned.fill(child: Image.asset("assets/elia-restaurant.jpg",fit: BoxFit.cover,
            )),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar:AppBar(
                centerTitle: true,
                title: FittedBox(fit:BoxFit.fitWidth, child: Text('Terms and Conditions', style: GoogleFonts.manrope(fontSize: 40,fontWeight: FontWeight.w900), textAlign: TextAlign.left),),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(size: 40, color: Colors.black),
              ),

              //extendBodyBehindAppBar: true,
              body:
              _GlassBox(

                  child:
                  FutureBuilder<String>(
                    future: loadAsset(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text("Error loading terms"));
                      } else {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(snapshot.data ?? "", style: GoogleFonts.manrope(fontSize: 30,fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                        );
                      }
                    },
                  ),
                ),
              ),])
            ));


  }




}

Future<String> loadAsset() async {
  return await rootBundle.loadString('assets/terms.txt');
}

class _GlassBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const _GlassBox({required this.child, this.width, this.height, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(20),child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(25),
            ),
            child: child,
          ),
        ),
      ),
    ));
  }
}
import 'dart:io';
import 'dart:ui';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nostos/user_id.dart' as globals;

import 'package:http/http.dart' as http;



class Break extends StatefulWidget {
  late IO.Socket? socket;


  Break({super.key,required this.socket});

  @override
  State<Break> createState() => _BreakState();
}

String url = globals.url;
String? dropdown;
final tx = TextEditingController();
String? text = ""; //for text of the searching bar
bool bclicked = false;
bool inBreak = false;
int time = 0;

bool showsnackbar = false;

class _BreakState extends State<Break> {


  @override
  void initState() {
    super.initState();

    globals.State = "Break";
    widget.socket?.emit("mode_updater",{"user_id":globals.userid,"mode":globals.State,"token": globals.token,});


    if(widget.socket == null) { widget.socket = IO.io(url,{'transports': ['websocket'], 'force new connection': true, });
    widget.socket?.onConnect((_) => print("✅ Connected to server"));
    widget.socket?.onDisconnect((_) => print("❌ Disconnected from server"));
    }
    widget.socket?.off("break_confirmation");
    widget.socket?.on("break_confirmation",(data){

      setState(() {
        if(data["confirmation"] == true){
          //bclicked = false;
          //inBreak = true;
          //globals.State = "inBreak";
          //globals.is_breaking = true;

          //Future.delayed(Duration(seconds: 10));

        }
        else{
          //bclicked = false;
          //inBreak = false;
          //globals.is_breaking = false;
        }


      });
    });

/*widget.socket!.onReconnect((_) {
    print("✅Reconnected");

    widget.socket!.emit("login", {
      "id": globals.userid,
      "mode":globals.State,
      "reconnect":true
    });

    print("📡 Sent identify on reconnect: ${globals.userid}");
  });*/

    widget.socket?.off("breaking_time");
    widget.socket?.on("breaking_time", (data) {
      setState(() {
        time = data["time"];
      });
    });

  }

  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // screen size
    final w = size.width;
    final h = size.height;

    return Scaffold(

      //backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [

          Positioned.fill(

            child:ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Image.asset(
                "assets/ikos_chill.jpg",   // change to your image name
                fit: BoxFit.cover,
              ),

            ),
          ),

          inBreak == false && globals.is_breaking == false?
          Align(
              alignment: Alignment(0,0),
              child: SafeArea(child: Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 10),child: _GlassBox(child: Container(
                height: h*0.45,
                width: w*0.9,
                decoration: BoxDecoration(
                  //color: Colors.white,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // shadow colorr
                      blurRadius: 10,                        // softness
                      spreadRadius: 2,                       // how wide
                      offset: Offset(0, 3),                  // (x, y)
                    ),
                  ],
                ),
                child: SafeArea(child: Column(
                  children: [

                    SizedBox(height: h*0.05),

                    Icon(
                      Icons.free_breakfast_outlined,
                      size: 100,
                      color: Colors.orange,
                    ),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(" Want a Break?",style: TextStyle(color: Colors.white,fontSize: 30,fontWeight: FontWeight.bold,shadows:
                    [
                      Shadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 0))
                    ]
                    ),),),


                    SizedBox(height: h*0.05),


                    bclicked == false?
                    ElevatedButton(
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(" Take a Break",style: TextStyle(color: Colors.white,fontSize: 20),),),
                      onPressed: () {
                        if(globals.acceptedRequests.isEmpty)
                        {
                          bclicked = true;
                          setState(() {
                          });
                        }else{
                          if(showsnackbar == false){
                            showsnackbar = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text("You Have Active Deliveries"),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 2),
                                  ),
                                ).closed.then((_) => showsnackbar = false); // reset after dismiss
                            });
                          }
                        }

                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:  Colors.orange,

                          shape:RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),

                          fixedSize: Size(w*0.7, h*0.057),
                          elevation: 3
                      ),
                    ):
                    SizedBox.shrink(),


                    bclicked == true?
                    ElevatedButton.icon(
                      icon: Icon( Icons.check,
                        color: Colors.white ,
                        fontWeight: FontWeight.bold,
                      ),
                      label:  FittedBox(fit: BoxFit.scaleDown, child: Text("Yes",style: TextStyle(color: Colors.white,fontSize: 20),),),
                      onPressed: () {

                        //bclicked = false;
                        //inBreak = true;
                        //globals.State = "inBreak";
                        //globals.is_breaking = true;
                        widget.socket?.emitWithAckAsync("Break",{"reason":text,"userid":globals.userid,"token":globals.token},
                            ack: (data){
                              if(data == true){
                                bclicked = false;
                                inBreak = true;
                                globals.State = "inBreak";
                                globals.is_breaking = true;
                                setState(() {

                                });
                              }
                            } )
                            .timeout(const Duration(seconds: 1,), onTimeout: (){
                          setState(() {
                            if(showsnackbar == false){
                              showsnackbar = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text("Wait Before Having Another Break"),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  ).closed.then((_) => showsnackbar = false); // reset after dismiss
                              });
                            }
                          });
                        },);



                        print("Socket connected? ${widget.socket?.connected}");
                        print(globals.userid);
                        //widget.socket?.emit("Break",{"reason":text,"userid":globals.userid,"token":globals.token});
                        setState(() {
                          time = 0;
                        });




                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:  Colors.orange,

                          shape:RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),

                          fixedSize: Size(w*0.7, h*0.057),
                          elevation: 3
                      ),
                    ):
                    SizedBox.shrink(),

                    bclicked == true?
                    SizedBox(height: h*0.01):
                    SizedBox.shrink(),


                    bclicked == true?
                    ElevatedButton.icon(
                      icon: Icon( Icons.cancel,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      label: FittedBox(fit: BoxFit.scaleDown, child: Text(" Cancel",style: TextStyle(color: Colors.black,fontSize: 20),),),
                      onPressed: () {

                        bclicked = false;
                        setState(() {
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:  const Color.fromARGB(255, 219, 218, 216),

                          shape:RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),

                          fixedSize: Size(w*0.7, h*0.057),
                          elevation: 3
                      ),
                    ):
                    SizedBox(height: h*0.05),







                  ], ),
                ),))))
          ):


//in break logic



          Align(
              alignment: Alignment(0,0),
              child: SafeArea(child: Padding(padding: EdgeInsets.all(10),child: _GlassBox(child:Container(
                height: h*0.45,/////////////
                width: w*0.9,//////////////
                decoration: BoxDecoration(
                  //color: Colors.white,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // shadow color
                      blurRadius: 10,                        // softness
                      spreadRadius: 2,                       // how wide
                      offset: Offset(0, 3),                  // (x, y)
                    ),
                  ],
                ),
                child: Column(
                  children: [

                    SizedBox(height: h*0.04),

                    Icon(
                      Icons.access_time_outlined,
                      size: 100,
                      color: Colors.orange,
                    ),
                    FittedBox(fit: BoxFit.scaleDown, child: Text("You are on a break for",style: TextStyle(color: Colors.white,fontSize: 30,fontWeight: FontWeight.bold,shadows:[Shadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 0))]
                    ),),),


                    FittedBox(fit: BoxFit.scaleDown, child: Text("${(time ~/ 60).toString().padLeft(2, '0')}:${(time % 60).toString().padLeft(2, '0')} Minutes ",style: TextStyle(color:Colors.deepOrange,fontWeight: FontWeight.bold,fontSize: 30,shadows:[Shadow(color: Colors.black38, blurRadius: 30, offset: Offset(0, 0))]),),),


                    SizedBox(height: h*0.05),



                    ElevatedButton.icon(
                      icon: Icon( Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        size: 25,
                      ),
                      label: FittedBox(fit: BoxFit.scaleDown, child: Text("Finish Break",style: TextStyle(color: Colors.white,fontSize: 20),),),
                      onPressed: () {

                        //bclicked = false;
                        //inBreak = false;
                        //globals.is_breaking = false;
                        //widget.socket?.emit("Break",{"reason":"stop","userid":globals.userid,"token":globals.token});
                        widget.socket?.emitWithAckAsync("Break",{"reason":"stop","userid":globals.userid,"token":globals.token},
                            ack: (data){
                              if(data == true){
                                bclicked = false;
                                inBreak = false;
                                globals.is_breaking = false;
                                setState(() {

                                });
                              }
                            } )
                            .timeout(const Duration(seconds: 1,), onTimeout: (){

                          setState(() {
                            if(showsnackbar == false){
                              showsnackbar = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text("Wait Before Finishing the Break"),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  ).closed.then((_) => showsnackbar = false); // reset after dismiss
                              });
                            }
                          });

                        },);
                        //setState(() {
                        //});
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:  Colors.orange,

                          shape:RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          ),

                          fixedSize: Size(w*0.7, h*0.057),
                          elevation: 3

                      ),
                    )

                  ], ),
              ),
              )









              ))
          ) ],

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
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
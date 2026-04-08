import 'package:flutter/material.dart';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nostos/user_id.dart' as globals;



class BreakingGrooms extends StatefulWidget {
  late IO.Socket? socket;

  BreakingGrooms({super.key,required this.socket});

  @override
  State<BreakingGrooms> createState() => _BreakingGroomsState();
}

String url = globals.url;

class _BreakingGroomsState extends State<BreakingGrooms> {

  List<dynamic> receivedList = [];
  List<String> groomList = [];
  @override
  void initState() {
    super.initState();



    if(widget.socket == null) { widget.socket = IO.io(url,{'transports': ['websocket'], 'force new connection': true, });
    widget.socket?.onConnect((_) => print("✅ Connected to server"));
    widget.socket?.onDisconnect((_) => print("❌ Disconnected from server"));
    }

    setState(() {
      widget.socket?.emit("seeBreaks",{"seeBreaks":true});
    });

    widget.socket?.on("breaking_grooms",(data){
      setState(() {
        receivedList = data['list']; // This is a Dart List now
        groomList = List<String>.from(receivedList); // Convert to List<String>

        print(groomList); // Output: [John, Ali, David]
      });



    });


  }



  @override
  void dispose() {
    widget.socket?.emit("seeBreaks",{"seeBreaks":false});
    widget.socket?.off("breaking_grooms"); // clean socket listener
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xff29fff2),
                Color(0xff1ea1ff),
              ],
              tileMode: TileMode.mirror,
            ),
          ),
          child: Scaffold(
              appBar: AppBar(
                title: const Text("Grooms at Break",style: TextStyle(color: Colors.blue,fontWeight: FontWeight.bold, fontSize: 20),),
                backgroundColor: Colors.transparent,
              ),
              backgroundColor: Colors.transparent,
              body: Scrollbar(
                  thumbVisibility: false,
                  thickness: 0,
                  child: ListView.builder(
                    itemCount: groomList.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.transparent,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ExpansionTile(
                          leading: const Icon(Icons.person),
                          title: Text(
                            groomList[index],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          children: [
                            ListTile(
                              title: Text("Status: On Break"),
                            ),
                            ListTile(
                              title: Text("Time Started: 10:30 AM"),
                            ),
                            ListTile(
                              title: Text("Estimated Return: 11:00 AM"),
                            ),
                          ],
                        ),
                      );
                    },
                  ))
          ),));
  }
}
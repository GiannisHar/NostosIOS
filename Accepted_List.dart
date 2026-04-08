import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nostos/user_id.dart' as globals;

import 'package:nostos/Board.dart';

class Accepted_List extends StatefulWidget {
  late IO.Socket? socket;  
   Accepted_List({super.key,required this.socket});

  @override
  State<Accepted_List> createState() => _Accepted_ListState();
}

class _Accepted_ListState extends State<Accepted_List> {

 String url = globals.url;
 int action = 0;
 bool is_selected = false;
 bool clicked = false;
 bool showsnackbar = false;

 bool isLoading = true;


//List<Board> board = [];
List<bool> acceptor = [];

Timer? globalTimer;


Map<String, dynamic> sender = {
  "user": "",         // server expects "user"
  "location": "",
  "room_number": "",  // if you have a room number
  "task": "",         // optional fields
  "dropdown": "",
  "counter": 0,
  "time": 0,
  "accepted": false,
  "index": -1,
  "RID": 0
};

@override
void initState() {
  super.initState();
    globals.State = "Accepted_List";

  globalTimer = Timer.periodic(Duration(seconds: 1), (_) {
    for (var item in globals.board) {
      item.time++;   
    }

    setState(() {});
  });

  if(widget.socket == null) { widget.socket = IO.io(url,{'transports': ['websocket'], 'force new connection': true, }); 
   widget.socket?.onConnect((_) => print("✅ Connected to server"));
   widget.socket?.onDisconnect((_) => print("❌ Disconnected from server")); 
}

  widget.socket!.onReconnect((_) {
    print("✅Reconnected");

    widget.socket!.emit("login", {
      "id": globals.userid,
      "mode":globals.State,
      "reconnect":true
    });

    print("📡 Sent identify on reconnect: ${globals.userid}");
  });

 widget.socket?.emit("mode_updater",{"user_id":globals.userid,"mode":globals.State,"token":globals.token,});
/*widget.socket!.emit("update", {
      "user_id": globals.userid,
      "mode":globals.State
    });*/
 

  widget.socket!.emit("get_accepted_requests", {
      "user_id": globals.userid,
      "mode": globals.State,
    });

     widget.socket?.off("accepted_requests"); // remove old listener if any
  widget.socket?.on("accepted_requests", (data) {

     List<Map<String, dynamic>> requests = List<Map<String, dynamic>>.from(data);

    // Update globals.acceptedRequests
    globals.acceptedRequests = requests;

    // Ensure acceptor list is synced
    if (acceptor.length != globals.acceptedRequests.length) {
      acceptor = List<bool>.filled(globals.acceptedRequests.length, false);
    }

    setState(() {
      isLoading = false;
    });

     if (acceptor.length != globals.acceptedRequests.length) {
    acceptor = List<bool>.filled(globals.acceptedRequests.length, false);
  }
  setState(() {
    isLoading = false;
  });
  });

  // Listen to the Board updates
  /*widget.socket?.off("Board");
    widget.socket?.on("Board", (data) {

      setState(() {
        
      
       print("📦 Board data received: $data"); 
    // Step 3: clone the list to ensure Flutter detects changes
    
    final newBoard = (data as List)
        .map((req) => Board(
              location: req["location"],
              userId: req["user"],
              room_number: req["room_number"],
               task: req["task"],
              dropdown: req["dropdown"],
              counter: req["counter"],
              time: req["time"],
              accepted: req["accepted"] ?? false,
              RID: req["RID"],

            ))
        .toList();

    setState(() {
      globals.board = List<Board>.from(newBoard); // replace the list with a fresh copy
      if (acceptor.length != globals.board.length) {
    acceptor = List<bool>.filled(globals.board.length, false);
  }

   isLoading = false;

    });


    });
  });*/

   setState(() {
      if (acceptor.length != globals.board.length) {
    acceptor = List<bool>.filled(globals.board.length, false);
  }

   isLoading = false;});
   

 widget.socket?.on("call_thief",(data){
  
    int newRID = data["RID"];
    int index = globals.board.indexWhere((req) => req.RID == newRID);
    
      globals.acceptedRequests.add({
      "userId": globals.board[index].userId,
      "location": globals.board[index].location,
      "room_number": globals.board[index].room_number,
      "task": globals.board[index].task,
      "dropdown": globals.board[index].dropdown,
      "counter": globals.board[index].counter,
      "time": globals.board[index].time,
      "accepted": true,
      "index": index,
      "RID": globals.board[index].RID,
    });

   setState(() {});

 });

}

@override
void dispose() {
  globalTimer?.cancel();
  //widget.socket?.off("call_thief"); 
  //widget.socket?.off("Board"); 
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body:  Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/spa.webp'),
            fit: BoxFit.cover,
          ),
        ),child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 👈 blur strength
        child:SafeArea(child:Container(
          color: Colors.transparent,
        child: isLoading? Center(
            child: LoadingAnimationWidget.threeArchedCircle(
              color: Colors.white,
              size: 50,
            ),
          ):
        globals.acceptedRequests.isEmpty? Align(
        alignment: Alignment(0,0),
        child: Text("No Accepted Pickups",style: GoogleFonts.manrope(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A2C42),
        ),)):
      Stack(children: [
          

        globals.acceptedRequests.isNotEmpty?

           Scrollbar(
             child: Column(
             children: [
             Expanded(
              child: Padding(padding: EdgeInsetsGeometry.directional(top: 14),child: ListView.builder(
               
              itemCount: globals.acceptedRequests.length,
              itemBuilder: (context, index){
                final req = globals.acceptedRequests[index];
                 return  Card(
          color: Colors.transparent,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          shadowColor: Colors.white,
          child:_GlassBox(rad: 14,bg: Colors.white,child: ListTile(
            leading: IconButton(
                icon: Icon(Icons.delete),
                color:Colors.red,
                onPressed: () {    
                 print("Icon clicked!");

                                   widget.socket?.emit("groom_declined", {
                                   "groom": globals.userid,
                                   "RID":req["RID"]
                                   });

                                   /*int boardIndex = globals.board.indexWhere((b) => b.RID == req["RID"]);
                                   globals.acceptedRequests.removeWhere((r) => r["RID"] == req["RID"]);
                                   acceptor[boardIndex] = false;*/
                                   



                  },
                 
                
                      ),
                      title: FittedBox(fit: BoxFit.scaleDown,child: Text("${ req["room_number"]} - ${req["location"]} - ${req["task"]}",style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),)),

                      subtitle:
                          Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisAlignment: MainAxisAlignment.start,
                               children: [
                               FittedBox(fit: BoxFit.scaleDown,child:Text("${req["userId"]}, ${req["counter"]}, ${req["dropdown"]}"),),

                               /*req["time"] >= 600?Text("${(req["time"] ~/ 60).toString().padLeft(2, '0')}:${(req["time"] % 60).toString().padLeft(2, '0')} Minutes ago",style: TextStyle(color:Colors.red[900]),):
                              req["time"] >= 300 && req["time"] <600?Text("${(req["time"] ~/ 60).toString().padLeft(2, '0')}:${(req["time"] % 60).toString().padLeft(2, '0')} Minutes ago",style: TextStyle(color: Colors.amber[800]),):
                              Text("${(req["time"] ~/ 60).toString().padLeft(2, '0')}:${(req["time"] % 60).toString().padLeft(2, '0')} Minutes ago",style: TextStyle(color: Colors.green[600]),)
                                 */

/*board[req["index"]].time >= 600?Text("${(board[req["index"]].time ~/ 60).toString().padLeft(2, '0')}:${(board[req["index"]].time % 60).toString().padLeft(2, '0')} Minutes ago",style: TextStyle(color:Colors.red[900]),):
                              board[req["index"]].time >= 300 && board[req["index"]].time <600?Text("${(board[req["index"]].time ~/ 60).toString().padLeft(2, '0')}:${(board[req["index"]].time % 60).toString().padLeft(2, '0')} Minutes ago",style: TextStyle(color: Colors.amber[800]),):
                              Text("${(board[req["index"]].time ~/ 60).toString().padLeft(2, '0')}:${(board[req["index"]].time % 60).toString().padLeft(2, '0')} Minutes ago",style: TextStyle(color: Colors.green[600]),)*/

                              /*globals.board[globals.board.indexWhere((b) => b.RID == req["RID"])].time >= 600?Text("${(globals.board[globals.board.indexWhere((b) => b.RID == req["RID"])].time ~/ 60).toString().padLeft(2, '0')}:${(globals.board[globals.board.indexWhere((b) => b.RID == req["RID"])].time % 60).toString().padLeft(2, '0')} Minutes ago",style: TextStyle(color:Colors.red[900]),):
                              globals.board[globals.board.indexWhere((b) => b.RID == req["RID"])].time >= 300 && globals.board[globals.board.indexWhere((b) => b.RID == req["RID"])].time <600?Text("${(globals.board[req["index"]].time ~/ 60).toString().padLeft(2, '0')}:${(globals.board[globals.board.indexWhere((b) => b.RID == req["RID"])].time % 60).toString().padLeft(2, '0')} Minutes ago",style: TextStyle(color: Colors.amber[800]),):
                              Text("${(globals.board[globals.board.indexWhere((b) => b.RID == req["RID"])].time ~/ 60).toString().padLeft(2, '0')}:${(globals.board[globals.board.indexWhere((b) => b.RID == req["RID"])].time % 60).toString().padLeft(2, '0')} Minutes ago",style: TextStyle(color: Colors.green[600]),)*/
                                 Text(
                                 "${(req["time"] ~/ 60).toString().padLeft(2, '0')}:${(req["time"] % 60).toString().padLeft(2, '0')} Minutes ago",
                                 style: TextStyle(
                                 color: req["time"] >= 600
                                 ? Colors.red[900]
                                 : req["time"] >= 300
                                 ? Colors.amber[800]
                                 : Colors.green[600],
                                 ),
                                 )


                               ]

                          ), 
                              trailing: 
                              _GlassBox(rad: 10, bg: Colors.black87,child: ElevatedButton(
                       onPressed: () {
                        setState(() {
                              print(globals.userid);
                              widget.socket?.emit("Arrived",{"groom":globals.userid,"useridPick":req["userId"],"Accepted":true,"RID":req["RID"]});
                               //globals.acceptedRequests.removeWhere((r) => r["RID"] == req["RID"]);
                           });
                       },
                       child: Text("Arrived",style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                       style: ElevatedButton.styleFrom(
                        //backgroundColor:  Color.fromARGB(255, 172, 188, 196),
                         backgroundColor: Colors.transparent,
                        shadowColor: Colors.black87,
                        elevation: 0,
                        foregroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.all(Radius.circular(10))),
                        fixedSize: Size(105,30)
                       ),
                       
                    )
                         
           
          )),
            
          ));},

        ),),)],),//
        
        )
        :Align(),
        


        
     


        
        

         
      ],
      )

    )))
      ));
  }
}


class _GlassBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final double rad;
  final Color bg;
  const _GlassBox({required this.child, this.width, this.height, this.onTap,required this.rad,required this.bg});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(rad),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: bg.withOpacity(0.1),
              border: Border.all(color: bg.withOpacity(0.5),width: 1.3),
              borderRadius: BorderRadius.circular(rad),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
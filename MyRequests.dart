import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nostos/user_id.dart' as globals;
import 'package:google_fonts/google_fonts.dart';

class MyRequests extends StatefulWidget {
    late IO.Socket? socket;

   MyRequests({super.key,required this.socket});

  @override
  State<MyRequests> createState() => _MyRequestsState();
}

 String url = globals.url;
 bool isLoading = true;
 List<Map<String, dynamic>> myRequests = [];

class _MyRequestsState extends State<MyRequests> {

  ScrollController _scrollController = ScrollController();

 @override
 void initState() {
  super.initState();

   globals.State = "User_Requests";

  if(widget.socket == null) { widget.socket = IO.io(url,{'transports': ['websocket'], 'force new connection': true, });
  widget.socket?.onConnect((_) => print("✅ Connected to server"));
  widget.socket?.onDisconnect((_) => print("❌ Disconnected from server"));
  }

  widget.socket?.emit("get_user_active_requests",{"user_id":globals.userid,"mode":globals.State,"token":globals.token,});

    widget.socket?.off("user_active_requests");
widget.socket?.on("user_active_requests", (data) {
  final List<Map<String, dynamic>> parsed =
      List<Map<String, dynamic>>.from(data);

  setState(() {
    myRequests = parsed;
    isLoading = false;
  });
});
}

 @override
  void dispose() {
   _scrollController.dispose();
   widget.socket?.off("user_active_requests");

    super.dispose();
  }


  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(children: [


      Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/pool_sent.webp'),
          //image: AssetImage('assets/ikos_odisia_attention.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(filter:
        ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child:  Container(decoration:
            BoxDecoration(color: Colors.white.withOpacity(0.0)),)),
    ),
      /*decoration: const BoxDecoration(
        image: DecorationImage(
          //image: AssetImage('assets/main_background.png'),
          image: AssetImage('assets/pool_sent.png'),
          fit: BoxFit.cover,
        ),
      ),*/
       SafeArea(
        child: isLoading
            ? Center(
                child: LoadingAnimationWidget.threeArchedCircle(
                  color: const Color(0xFF1A2C42),
                  size: 50,
                ),
              )
            : myRequests.isEmpty
                ? Center(
                    child: Text(
                      "No active requests",
                      style: GoogleFonts.manrope(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                          shadows: [Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 40,
                            color: Colors.black.withOpacity(1),
                          )]
                      ),
                    ),
                  )
                : Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 10,
                  radius: Radius.circular(12),

                child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: myRequests.length,
                    itemBuilder: (_, index) {
                      final task = myRequests[index];

                      return Padding(padding: const EdgeInsets.symmetric(vertical: 1),child: _GlassBox(child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding:
                            const EdgeInsets.fromLTRB(24, 12, 12, 10),
                        decoration: BoxDecoration(
                            color: Colors.transparent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 0),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${task["room_number"]} - ${task["task"]}",
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          const Color(0xFF1A2C42),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${task["dropdown"]} • ${task["counter"]}",
                                    style: GoogleFonts.lato(
                                      fontSize: 13,
                                      color:
                                          Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// DELETE BUTTON
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                widget.socket?.emit(
                                  "delete_request",
                                  {
                                    "token":globals.token,
                                    "RID": task["RID"],
                                    "user_id": globals.userid,
                                  },
                                );
                              },
                            ),
                          ],
                        ),)
                      ));
                    },
                  ),),
      ),
    ]),
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
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:nostos/user_id.dart' as globals;
import 'package:nostos/Board.dart';


class ChatPage extends StatefulWidget {
  final IO.Socket? socket;

  const ChatPage({
    super.key,
    required this.socket,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> messages = [];

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  int page = 0;
  bool isLoading = false;
  bool hasMore = true;
  
 int? _selectedRID;
 int? _editingMessageId;

  @override
  void initState() {
    super.initState();


    globals.State = "ChatPage";
    widget.socket?.emit("mode_updater",{"user_id":globals.userid,"mode":globals.State,"token": globals.token,});
    globals.page = page;


    widget.socket?.off("chat_override");
    widget.socket?.on("chat_override", _onChatOverride);


    //_loadMessages();
    widget.socket?.emit("get_messages_page", {
      "token":globals.token,
      "page": page,
    });

    // Listen for pages
    widget.socket?.on("messages_page", _onMessagesPage);


    // Listen for realtime new messages (optional)
    widget.socket?.on("message_sent", _onNewMessage);

    widget.socket?.on("refresh_messages", (_) {
      _forceRefreshMessages();
    });


    _scrollController.addListener(_scrollListener);
  }

  @override
void dispose() {
  widget.socket?.off("messages_page");
  widget.socket?.off("message_sent");
  widget.socket?.off("refresh_messages"); // <-- important
  widget.socket?.off("chat_override");
  _scrollController.dispose();
  _textController.dispose();
  super.dispose();
}

  /* ---------------- LOAD PAGED MESSAGES ---------------- */



   void _openRequestPickerDialog() {
  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Your Accepted Requests",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: globals.acceptedRequests.length,
                  itemBuilder: (_, i) {
                    final r = globals.acceptedRequests[i];

                    return Card(
                      child: ListTile(
                        title: Text(
                          "${r["location"]} - ${r["room_number"]}",
                        ),
                        subtitle: Text(r["task"]),
                        trailing: ElevatedButton(
                          child: const Text("Send"),
                          onPressed: () {
                            _sendRequestToChat(r["RID"]);
                            widget.socket?.emit("update_sql_req",{"RID":r["RID"],"user_id":globals.userid,"action":0});
                            Navigator.pop(context);

                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


void _openSendRequestConfirm() async {
  if (globals.acceptedRequests.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No accepted requests to send")),
    );
    return;
  }

  bool? confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Send Request to Chat"),
      content: const Text("Choose one of your accepted requests to send?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Yes"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    _openRequestPickerDialog();
  }
}

void _sendRequestToChat(rid) {
  widget.socket?.emit("chat_request_message", {
    "RID": rid,
    "sender": globals.userid,
  });
  //_forceRefreshMessages();
}

Widget _buildRequestChatBubble(Map msg) {
   int rid = msg["RID"];
  final String senderId =
      msg["sender"]?.toString() ??
      msg["name"]?.toString() ??
      "";

  final bool mine = senderId == globals.userid;

  final Color bg = mine
      ? const Color(0xFF91FF91) // 🟢 mine
      : Colors.orange.shade200; // 🟠 others

  final request = findRequestByRID(msg["RID"]);

  final String location = request?["location"] ?? "Unknown";
  final int room = request?["room_number"] ?? 0;
  final String task = request?["task"] ?? "Unknown task";
  final GlobalKey bubbleKey = GlobalKey();

   
  
  return GestureDetector(
    onLongPress: mine
        ? () {
            final RenderBox box =
                bubbleKey.currentContext!.findRenderObject() as RenderBox;
            final Offset pos = box.localToGlobal(Offset.zero);

            showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                pos.dx,
                pos.dy,
                pos.dx + box.size.width,
                pos.dy + box.size.height,
              ),
              items: const [
                PopupMenuItem(
                  value: "delete",
                  child: Text("Delete"),
                ),
              ],
            ).then((value) {
              if (value == "delete") {
                _deleteRequestMessage(rid);
              }
            });
          }
        : null,

       
 
  child: Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      key: bubbleKey, // attach anchor here
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: mine ? Radius.circular(16) : Radius.circular(0), // Sharp corner for tail
          bottomRight: mine ? Radius.circular(0) : Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
 

  if (_selectedRID == rid && mine)
  Positioned(
    top: 0,
    right: mine ? -32 : null,
    left: mine ? null : -32,
    child: PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (value) {
        if (value == "delete") {
          _deleteRequestMessage(rid);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: "delete",
          child: Text("Delete"),
        ),
      ],
    ),
  ),

          if (!mine)
            Text(
              senderId,
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          if (!mine) const SizedBox(height: 4),

          const Text(
            "REQUEST",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          Text("$location - $room"),
          Text(task),
          Text(rid.toString()),

          ElevatedButton(
  onPressed: () async {
     // <-- replace this with the RID you want

    // Find the request in globals.board by RID
    final boardReq = globals.board.firstWhere(
      (b) => b.RID == rid,
      orElse: () => Board(
        location: "",
        userId: "",
        room_number: 0,
        task: "",
        dropdown: "",
        counter: 0,
        time: 0,
        accepted: false,
        RID: rid,
      ),
    );

    // Show override dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("OVERRIDE CALL"),
        content: const Text("Do you want to override this call?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Emit override action
    widget.socket?.emit("delivery", {
      "action": 1, // override
      "groom": globals.userid,
      "userId": boardReq.userId,
      "location": boardReq.location,
      "room_number": boardReq.room_number,
      "task": boardReq.task,
      "dropdown": boardReq.dropdown,
      "counter": boardReq.counter,
      "time": boardReq.time,
      "accepted": true,
      "RID": boardReq.RID,
      "token":globals.token
    });
      
     widget.socket?.emit("update_sql_req",{"RID":rid,"user_id":globals.userid,"action":1});
     _forceRefreshMessages();
   



  },
  child: const Text("Override"),
)



        ],
      ),
    ),
  ),

  );

}


Map<String, dynamic>? findRequestByRID(int rid) {
  for (var r in globals.acceptedRequests) {
    if (r["RID"] == rid) return r;
  }

  for (var b in globals.board) {
    if (b.RID == rid) {
      return {
        "location": b.location,
        "room_number": b.room_number,
        "task": b.task,
      };
    }
  }

  return null;
}

Widget _buildSendToChatMiniBar() {
  return Align(alignment: AlignmentGeometry.center,child: _GlassBox(bg: Colors.white,rad: 50,child:
          InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: _openSendRequestConfirm,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.add,
                color: Colors.black,
                size: 30,
              ),
            ),
          ),)



  );
}

void _deleteRequestMessage(int rid) async {
  bool? confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Delete Request"),
      content: const Text("Are you sure you want to delete this request message?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  widget.socket?.emit("delete_request_message", {
    "token":globals.token,
    "RID": rid,
    "user_id": globals.userid,
  });

  //_forceRefreshMessages();
}

void _deleteMessage(int messageId) async {
  bool? confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Delete Message"),
      content: const Text("Are you sure you want to delete this message?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  widget.socket?.emit("delete_message", {
    "token":globals.token,
    "user_id": globals.userid,
    "id":messageId,
  });

//  _forceRefreshMessages();
}

void _editMessage(int messageId, String text) {
  setState(() {
    _editingMessageId = messageId;
    _textController.text = text;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  });
}

Future<void> _onChatOverride(data) async {
     print("🟢 OVERRIDE EVENT RECEIVED");
  print("📦 Raw data: $data");

    if (!mounted) return;

    if (data["override"] == true) {
      //int overRID = data["RID"];

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Call got Overridden'),
          content: const Text('Press OK to continue delivering'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _forceRefreshMessages();

      setState(() {
           widget.socket?.emit("get_messages_page", {
             "token":globals.token,
             "page": page,
    });
      
      });
    }
  }

  void _forceRefreshMessages() {
  if (!mounted) return; // <-- add this

  setState(() {
    messages.clear();
    page = 0;
    hasMore = true;
    isLoading = false;
  });

  widget.socket?.emit("get_messages_page", {
    "token":globals.token,
    "page": page,
  });
}


  void _loadMessages() {
    if (isLoading || !hasMore) return;

    isLoading = true;

    widget.socket?.emit("get_messages_page", {
      "token":globals.token,
      "page": page,
    });
  }

void _onMessagesPage(dynamic data) {
  final List list = data["messages"];
  if (list.isEmpty) {
    hasMore = false;
    isLoading = false;
    return;
  }

  final incoming = List<Map<String, dynamic>>.from(list);

  setState(() {
    final existingIds = messages.map((m) => m["id"]).toSet();

    for (final msg in incoming) {
      if (!existingIds.contains(msg["id"])) {
        messages.add(msg);
      }
    }

    page++;
    isLoading = false;
  });

  if (page < 3 && hasMore) _loadMessages();
}

  /* ---------------- REALTIME MESSAGE ---------------- */

  void _onNewMessage(dynamic data) {
  setState(() {
    //messages.insert(0, Map<String, dynamic>.from(data));
  });

   /*widget.socket?.emit("get_messages_page", {
      "page": page,
    });*/
  // Optional: auto-scroll to bottom
  /*_scrollController.animateTo(
    0,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
  );*/

   _loadMessages();
  
}

  /* ---------------- SCROLL LISTENER ---------------- */

  void _scrollListener() {
  if (!_scrollController.hasClients || isLoading || !hasMore) return;

  final position = _scrollController.position;

  // Because reverse = true, top == maxScrollExtent
  if (position.pixels >= position.maxScrollExtent - 30)
 {
    _loadMessages();
  }
}

  /* ---------------- SEND MESSAGE ---------------- */

 void _sendMessage() {
  final text = _textController.text.trim();
  if (text.isEmpty) return;
 
   if (_editingMessageId != null) {
    // Send edit event
    widget.socket?.emit("edit_message", {
      "token":globals.token,
      "messageId": _editingMessageId,
      "user_id": globals.userid,
      "message": text,
    });

    setState(() {
      _editingMessageId = null;
    });
  }
  else{
    widget.socket?.emit("send_message", {
      "token":globals.token,
      "user_id": globals.userid,
    "message": text,
  });
  }
 
  

   

 
   
  _textController.clear();

  _scrollController.animateTo(
    0,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
  );
 // _forceRefreshMessages();
}

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF5FB),

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ikos_elia_xriso.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // 👈 blur strength
          child: Container(
            color: Colors.white.withOpacity(0.15), // controls readability
            child: SafeArea(
          child: Column(
        children: [
            
          /* ---------------- MESSAGES ---------------- */

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // IMPORTANT
              padding: const EdgeInsets.all(12),
              //itemCount: messages.length + 1
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {

  if (index == messages.length) return _buildLoader();

  final msg = messages[index];



  if (msg["type"] == "request" || msg["RID"] != null) {
    return _buildRequestChatBubble(msg);
  }

  final isMe = (msg["name"] ?? "") == globals.userid;

  return _buildBubble(
  msg["message"]?.toString() ?? "",
  msg["name"]?.toString() ?? "Unknown",
  isMe,
  msg["id"] ?? 0,
);

}


              /*itemBuilder: (context, index) {

                  

                if (index == messages.length) {
                  return _buildLoader();
                }

                final msg = messages[index];

                final bool isMe =
                    msg["name"] == globals.userid;

               if (msg["type"] == "request") {
                 return _buildRequestChatBubble(msg);
}

                return _buildBubble(
                  msg["message"],
                  msg["name"],
                  isMe,
                );
              },*/
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Padding(padding: EdgeInsets.only(right: 10,bottom: 10,top: 0,left: 10),child: _buildSendToChatMiniBar()),
              Expanded(child:Padding(padding: EdgeInsets.only(right: 10,bottom: 5,top: 0,left: 10),child:
          _buildInput(),))
            ],)
        ],
      ),
    )))));
  }

  /* ---------------- MESSAGE BUBBLE ---------------- */

  Widget _buildBubble(String text, String sender, bool isMe, int id) {
      final GlobalKey bubbleKey = GlobalKey();
    return GestureDetector(
    onLongPress: isMe
        ? () {
            final RenderBox box =
                bubbleKey.currentContext!.findRenderObject() as RenderBox;
            final Offset pos = box.localToGlobal(Offset.zero);

            showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                pos.dx,
                pos.dy,
                pos.dx + box.size.width,
                pos.dy + box.size.height,
              ),
              items: const [
                PopupMenuItem(
                  value: "delete",
                  child: Text("Delete"),
                ),
                PopupMenuItem(
                  value: "edit",
                  child: Text("Edit"),
                ),
              ],
            ).then((value) {
              if (value == "delete") {
                _deleteMessage(id);
              }
              if (value == "edit") {
                _editMessage(id, text);
              }
            });
          }
        : null,
    
    child: Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,

      child: Padding(padding: EdgeInsets.symmetric(vertical: 1),child: Container(
        key: bubbleKey,
        margin: const EdgeInsets.symmetric(vertical:2),
        padding: const EdgeInsets.all(10),

        constraints: const BoxConstraints(maxWidth: 280),

        decoration: BoxDecoration(
          color: (!isMe)? Colors.white: Colors.blue.withOpacity(0.8),

          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isMe ? Radius.circular(16) : Radius.circular(0), // Sharp corner for tail
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            if (!isMe)
              Text(
                sender,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),

            if (!isMe) const SizedBox(height: 4),

            Text(
              text,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: isMe ? Colors.black87 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    ),)
    );
  }

  /* ---------------- INPUT BAR ---------------- */

  Widget _buildInput() {
    return SafeArea(
      child: _GlassBox(bg: Colors.white,rad: 22,child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 12),

        child: Row(
          children: [
            _buildSendToChatMiniBar(),
            const SizedBox(width: 8,),
            Expanded(
              child: TextField(
                controller: _textController,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: "Message...",
                  hintStyle: TextStyle(
                      fontSize: 17,color: Colors.black,fontStyle: GoogleFonts.manrope().fontStyle,fontWeight: FontWeight.w500 ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white70, width: 1.3),
                    borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                    gapPadding: 5.0,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 2.0),
                    borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                    gapPadding: 5.0,
                  ),
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded),
              color: Colors.black,
              onPressed: _sendMessage,
            ),
          ],
        ),
      )),
    );
  }

  /* ---------------- LOADING INDICATOR ---------------- */

  Widget _buildLoader() {
    if (!hasMore) return const SizedBox();

    return const Padding(
      padding: EdgeInsets.all(8),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
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
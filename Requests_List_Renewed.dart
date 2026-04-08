import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as secureStorage;
import 'package:intl/intl.dart';
import 'package:nostos/Break.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostos/user_id.dart' as globals;
import 'package:nostos/Board.dart';

class Requests_List_Renewed extends StatefulWidget {
  late IO.Socket? socket;
  Requests_List_Renewed({super.key, required this.socket});

  @override
  State<Requests_List_Renewed> createState() => _Requests_List_RenewedState();
}

class _Requests_List_RenewedState extends State<Requests_List_Renewed> {
  String url = globals.url;
  int action = 0;
  bool showsnackbar = false;
  Timer? globalTimer;

  List<bool> acceptor = [];
  bool isLoading = true;

  String _getElapsedTime(int startTimeUnix) {
    int currentUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int elapsedSeconds = currentUnix - startTimeUnix;
    if (elapsedSeconds < 0) return "00:00";
    int minutes = elapsedSeconds ~/ 60;
    int seconds = elapsedSeconds % 60;
    String mStr = minutes.toString().padLeft(2, '0');
    String sStr = seconds.toString().padLeft(2, '0');
    return "$mStr:$sStr";
  }

  Map<String, dynamic> sender = {
    "user": "",
    "location": "",
    "room_number": 0,
    "task": "",
    "dropdown": "",
    "counter": 0,
    "time": 0,
    "accepted": false,
    "index": -1,
    "RID": 0
  };

  // ================== INIT ==================
  @override
  void initState() {
    super.initState();

    globals.State = "Requests_List";

    globalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      for (var item in globals.board) {
        item.time++;
      }
      setState(() {});
    });

    if (widget.socket == null) {
      widget.socket = IO.io(url, {
        'transports': ['websocket'],
        'force new connection': true,
      });
    }

    _setupListeners();
    _requestInitialData();
  }

  void _requestInitialData() {
    widget.socket?.emit("mode_updater", {
      "user_id": globals.userid,
      "mode": globals.State,
      "token": globals.token,
    });

    widget.socket?.emit("update", {
      "token": globals.token,
      "user_id": globals.userid,
      "mode": globals.State,
    });

    widget.socket?.emit("get_accepted_requests", {
      "user_id": globals.userid,
      "mode": globals.State,
    });
  }

  void _setupListeners() {
    widget.socket?.off("accepted_requests");
widget.socket?.on("accepted_requests", (data) {
  if (!mounted) return;
  final requests = List<Map<String, dynamic>>.from(data);
  setState(() {
    globals.acceptedRequests = requests;
    if (acceptor.length != globals.acceptedRequests.length) {
      acceptor = List<bool>.filled(globals.acceptedRequests.length, false);
    }

    // ← RE-SORT board now that we know which requests are ours
    globals.board.sort((a, b) {
      int priority(Board req) {
        final isMine = req.accepted &&
            globals.acceptedRequests
                .any((r) => r["RID"].toString() == req.RID.toString());
        if (isMine) return 0;
        if (req.accepted) return 1;
        return 2;
      }
      return priority(a).compareTo(priority(b));
    });

    isLoading = false;
  });
});

    widget.socket?.off("permition_granded");
    widget.socket?.on("permition_granded", (data) {
      if (!mounted) return;
      setState(() {
        globals.acceptedRequests.add(Map.from(sender));
      });
    });

    widget.socket?.off("call_taken");
    widget.socket?.on("call_taken", (data) {
      if (!mounted) return;
      widget.socket!.emit("update", {
        "token": globals.token,
        "user_id": globals.userid,
        "mode": globals.State,
      });
      if (!showsnackbar) {
        showsnackbar = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(
            content: Text("Call was taken by another guy"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ))
              .closed
              .then((_) => showsnackbar = false);
        });
      }
    });

    widget.socket?.off("timestamp");
    widget.socket?.on("timestamp", (data) {
      if (!mounted) return;
      final int rid = data["RID"];
      final String ts = data["timestamp"] ?? "";
      setState(() {
        globals.timestamps[rid] = ts;
      });
    });

    widget.socket?.off("override");
    widget.socket?.on("override", (data) {
      _onOverride(data);
    });

    widget.socket?.off("Board");
    widget.socket?.on("Board", (data) {
      if (!mounted) return;

      final newBoard = (data as List).map((req) => Board(
        location: req["location"],
        userId: req["user"],
        room_number: req["room_number"],
        task: req["task"],
        dropdown: req["dropdown"],
        counter: req["counter"],
        time: req["elapsed"],
        accepted: req["accepted"] ?? false,
        RID: req["RID"],
      )).toList();

      newBoard.sort((a, b) {
        int priority(Board req) {
          final isMine = req.accepted &&
              globals.acceptedRequests
                  .any((r) => r["RID"].toString() == req.RID.toString());
          if (isMine) return 0;       // 🟢 mine first
          if (req.accepted) return 1; // 🟠 others accepted second
          return 2;                   // ⚪ pending last
        }
        return priority(a).compareTo(priority(b));
      });

      setState(() {
        globals.board = newBoard;
        acceptor = List<bool>.filled(globals.board.length, false);
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    globalTimer?.cancel();
    widget.socket?.off("Board");
    widget.socket?.off("timestamp");
    widget.socket?.off("call_thief");
    widget.socket?.off("permition_granded");
    widget.socket?.off("accepted_requests");
    widget.socket?.off("override");
    widget.socket?.off("call_taken");
    super.dispose();
  }

  // ================== UI HELPERS ==================
  Color _urgencyColor(int t) {
    if (t >= 600) return Colors.red.shade700;
    if (t >= 300) return Colors.orange.shade700;
    return Colors.green.shade600;
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 3));
    widget.socket!.emit("update", {
      "token": globals.token,
      "user_id": globals.userid,
      "mode": globals.State,
    });
    widget.socket!.emit("get_accepted_requests", {
      "user_id": globals.userid,
      "mode": globals.State,
    });
  }

  Future<void> _onOverride(data) async {
    print("🟢 OVERRIDE EVENT RECEIVED");
    print("📦 Raw data: $data");

    if (!mounted) return;

    if (data["override"] == true) {
      int overRID = data["RID"];

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

      if (!mounted) return;

      setState(() {
        widget.socket!.emit("update", {
          "token": globals.token,
          "user_id": globals.userid,
          "mode": globals.State,
        });
        globals.acceptedRequests.removeWhere((req) => req["RID"] == overRID);
      });
    }
  }

  String _currentTime() => DateFormat('HH:mm').format(DateTime.now());

  // ================== CARD UI ==================
  Widget _buildRequestCard(Board req, int index) {
    bool my_accepted_call = req.accepted &&
        globals.acceptedRequests
            .any((r) => r["RID"].toString() == req.RID.toString());

    final bool hasLocation =
        req.location != "Null" && req.location.isNotEmpty;
    final bool hasDropdown = req.dropdown != null && req.dropdown.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: _GlassBox(
        rad: 15,
        bg: _cardBackground(req),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _cardBackground(req).withOpacity(0.75),
                blurRadius: 10,
                offset: const Offset(0, 0),
              )
            ],
          ),
          child: Row(
            children: [
              my_accepted_call
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        print("Icon clicked!");
                        widget.socket?.emit("groom_declined", {
                          "token": globals.token,
                          "groom": globals.userid,
                          "RID": req.RID
                        });
                        setState(() {});
                      },
                    )
                  : const SizedBox(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                          children: hasLocation
                              ? [
                                  TextSpan(
                                    text: req.location,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(text: " - "),
                                  TextSpan(text: req.room_number.toString()),
                                  //const TextSpan(text: " - "),
                                   if (req.task != null && req.task.isNotEmpty) ...[
                                    const TextSpan(text: " - "),
                                    //const TextSpan(text: " - "),
                                     TextSpan(text: req.task),
                                        ],
                                ]
                              : [
                                  TextSpan(
                                    text: req.room_number.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  //const TextSpan(text: " - "),
                                  if (req.task != null && req.task.isNotEmpty) ...[
                                    const TextSpan(text: " - "),
                                     TextSpan(text: req.task),
                                        ],
                                ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasDropdown
                          ? "${req.userId} • ${req.counter} • ${req.dropdown}"
                          : "${req.userId} • ${req.counter}",
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(Icons.access_time_filled, color: _urgencyColor(req.time)),
                  Text(
                    globals.timestamps[req.RID] ?? "-",
                    style: GoogleFonts.lato(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: req.accepted
                      ? Colors.orange.shade600
                      : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (!my_accepted_call) {
                    if (req.accepted) {
                      bool? confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("OVERRIDE CALL"),
                          content: const Text(
                              "Do you want to override this call?"),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text("No")),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                  action = 1;
                                },
                                child: const Text("Yes")),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                    }

                    setState(() {
                      if (index >= acceptor.length) {
                        acceptor =
                            List<bool>.filled(globals.board.length, false);
                      }
                      acceptor[index] = !acceptor[index];
                      sender
                        ..["userId"] = req.userId
                        ..["location"] = req.location
                        ..["room_number"] = req.room_number
                        ..["task"] = req.task
                        ..["dropdown"] = req.dropdown
                        ..["counter"] = req.counter
                        ..["time"] = req.time
                        ..["accepted"] = true
                        ..["index"] = index
                        ..["RID"] = req.RID;

                      widget.socket?.emit("delivery", {
                        "token": globals.token,
                        "action": action,
                        "groom": globals.userid,
                        ...sender,
                      });
                      action = 0;
                    });
                  } else {
                    widget.socket?.emit("Arrived", {
                      "groom": globals.userid,
                      "useridPick": req.userId,
                      "Accepted": true,
                      "RID": req.RID,
                      "token": globals.token
                    });
                  }
                },
                child: Text(req.accepted ? "Omw" : "Go"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Board? _nextPendingRequest() {
    try {
      return globals.board.firstWhere((r) => !r.accepted);
    } catch (_) {
      return null;
    }
  }

  // ================== NEXT PENDING HEADER ==================
  Widget _buildNextPendingHeader() {
    final Board? candidate = _nextPendingRequest();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: _GlassBox(
        rad: 12,
        bg: Colors.white,
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 0),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Next Pending Request:",
                style: GoogleFonts.manrope(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              if (candidate != null)
                _buildRequestCard(candidate, 0)
              else
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "No Pending Requests",
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _cardBackground(Board req) {
    bool isMine = req.accepted &&
        globals.acceptedRequests
            .any((r) => r["RID"].toString() == req.RID.toString());

    if (isMine) return const Color.fromARGB(255, 145, 255, 145);
    if (req.accepted) return Colors.orange.shade100;
    return Colors.white;
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/blue_panoramic1.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.blue,
            child: SafeArea(
              child: isLoading
                  ? Center(
                      child: LoadingAnimationWidget.threeArchedCircle(
                        color: const Color(0xFF1A2C42),
                        size: 50,
                      ),
                    )
                  : Column(
                      children: [
                        _buildNextPendingHeader(),
                        Expanded(
                          child: globals.board.isEmpty
                              ? Center(
                                  child: Text(
                                    "No Available Pickups",
                                    style: GoogleFonts.manrope(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A2C42),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 0, 16, 8),
                                  itemCount: globals.board.length,
                                  itemBuilder: (_, i) =>
                                      _buildRequestCard(globals.board[i], i),
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
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

  const _GlassBox(
      {required this.child,
      this.width,
      this.height,
      this.onTap,
      required this.rad,
      required this.bg});

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
              border: Border.all(color: bg.withOpacity(0.5), width: 1.3),
              borderRadius: BorderRadius.circular(rad),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
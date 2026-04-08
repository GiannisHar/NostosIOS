import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:nostos/user_id.dart' as globals;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:smart_autocomplete/smart_autocomplete.dart';

class Requester_Renewed extends StatefulWidget {
  late IO.Socket? socket;
  Requester_Renewed({super.key, required this.socket});

  @override
  State<Requester_Renewed> createState() => Requester_RenewedState();
}

class Requester_RenewedState extends State<Requester_Renewed> {
  String url = globals.url;

  // FIX 1: Define a GlobalKey to control the SnackBar safely
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();

  final List<String> pickupLocations = [
    "Theatre", "Adults Pool", "Sports Center", "Teens Club", "Kids Club",
    "Spa", "Gym", "Main Lobby", "Central Pool", "Trampoline",
    "Deluxe Pool", "Deluxe Beach", "Main Beach", "Sea Beach",
    "Diving Center", "Water Sports", "Fresco", "Elia",
    "Ouzo", "Sea Grill", "Oliva", "Parking",
  ];

  late List<bool> is_selected;
  List<bool> is_selected_2 = [false, false, false, false, false];

  String requester = "Null";
  String requester_2 = "";
  String? dropdown = "Attention";
  int counter = 1;

  // Logic for Smart AutoComplete
  final TextEditingController tx = TextEditingController();
  TextEditingController? _autoController;
  bool showSuggestions = true;
  String? text = "";
  bool scheduleEnabled = false;
  TimeOfDay? scheduledTime;
  bool rightroom = true;
  List<int> secondaryList = [];

  double w = 0;
  double h = 0;



  bool _isLoading = false;

  void _handleClick() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(milliseconds: 3000), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

// Add this to your state variables
  OverlayEntry? _cursorOverlay;



// Replace _hovering logic with these methods:
/*void _showCursor(Offset position) {
  _cursorOverlay?.remove();
  _cursorOverlay = OverlayEntry(
    builder: (_) => Positioned(
      left: position.dx - 50,
      top: position.dy - 50,
      child: IgnorePointer(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Lottie.asset("assets/amaksaki.json", repeat: true),
        ),
      ),
    ),
  );
  Overlay.of(context).insert(_cursorOverlay!);
}

void _hideCursor() {
  _cursorOverlay?.remove();
  _cursorOverlay = null;
}

void _updateCursor(Offset position) {
  _cursorOverlay?.remove();
  _cursorOverlay = OverlayEntry(
    builder: (_) => Positioned(
      left: position.dx - 50,
      top: position.dy - 50,
      child: IgnorePointer(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Lottie.asset("assets/amaksaki.json", repeat: true),
        ),
      ),
    ),
  );
  Overlay.of(context).insert(_cursorOverlay!);
}*/



  final ScrollController _taskScrollController = ScrollController();
  final ScrollController _screenscrollbar = ScrollController();

  // --- HELPER METHODS ---

  Future<void> playDing() async {
    await globals.audio_player.play(AssetSource('Request_Sent.mp3'));
  }

  List<int> proposeRoomFast(int roomToFind, Set<int> validRooms) {
    final List<int> secondaryList = [];

    // First loop
    for (int i = 0; i < 5; i++) {
      int r = roomToFind + i;

      if (validRooms.contains(r)) {
        secondaryList.add(r);
      }
    }

    // Same winter logic
    final String winter =
        roomToFind.toString().padRight(3, '0') + "1";

    final int fina = int.parse(winter);

    // Second loop
    for (int i = 0; i < 5; i++) {
      int f = fina + i;

      if (validRooms.contains(f)) {
        secondaryList.add(f);
      }
    }

    return secondaryList;
  }


  void  room_check_upper(String room){
    if(globals.roomNumbers.contains(room)){
      rightroom = true;
      return;
    }
    rightroom = false;
  }

  void clearer() {

    setState(() {
      tx.clear();
      _autoController?.clear();
      rightroom = true;
      showSuggestions = false;

    });

  }

  void reseter(int n, List<bool> list) {
    if (n != -1) list[n] = !list[n];
    for (int i = 0; i < list.length; i++) {
      if (i != n) list[i] = false;
    }
  }

  // --- INITIALIZATION ---

  @override
  void initState() {
    super.initState();

    globals.State = "Requester";
    is_selected = List<bool>.filled(pickupLocations.length, false);

    // Socket Initialization
    if (widget.socket == null) {
      widget.socket = IO.io(url, {
        'transports': ['websocket'],
        'force new connection': true,
      });
    }

    // Initial check
    /*widget.socket?.emit("room_check", {
      "user_id": globals.userid,
      "room": 67,
    });*/

    /*widget.socket?.onReconnect((_) {
      widget.socket!.emit("login", {
        "id": globals.userid,
        "mode": globals.State,
        "reconnect": true
      });
    });*/

    // --- SOCKET LISTENERS ---

    widget.socket?.off("room_return");
    widget.socket?.on("room_return", (data) async {
      //if (!mounted) return;
      if(_autoController?.text == ""){
        setState(() {
          rightroom = true;
        });
      }
      if (data["response"] == 1) {

        setState(() {
          rightroom = true;
          dropdown = data["priority"];
        });


      } else if (data["response"] == 0) {
        setState(() {
          rightroom = false;
        });

      } else {
        // FIX 3: Use the key to show SnackBar. No context needed!
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
            content: SizedBox(
              height: h*0.11, // Force height
              child: const Center(
                child: Text("This Room Doesn't Exist",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            width: w ,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    });


    /* widget.socket?.emit("room_check", {
      "user_id": globals.userid,
      "room": 67,
    });*/

    widget.socket?.off("Status");
    widget.socket?.on("Status", (data) {
      if (!mounted) return;

      setState(() {
        if (data["accepted"] == true) {
          rightroom = true;
          tx.clear();
          _autoController?.clear();
          reseter(-1, is_selected);
          reseter(-1, is_selected_2);
          dropdown = "Attention";
          counter = 1;
          playDing();
          if (!mounted) return;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // OPTION 1: Use Padding to control thickness
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
              content: SizedBox(
                height: h*0.11, // OPTION 2: Force a specific height here
                child: const Center(
                  child: Text("Request Sent",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              width: w,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounder for small bars
              duration: const Duration(milliseconds: 1500),
            ),
          );
          _handleClick();
        } else {
          // FIX 3: Use the key here too
          _messengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text("Server can't listen"),
              backgroundColor: Colors.red,
              duration: Duration(milliseconds: 1500),
            ),
          );
        }
      });
    });
    widget.socket?.off("finished");
    widget.socket?.on("finished", (data) {
      if (!mounted) return;
      if (data["state"] == true) {
        globals.MyRequests.removeWhere((request) => request["RID"] == data["RID"]);
      }
    });
  }

  @override
  void dispose() {
    // FIX: Do NOT dispose 'tx' manually to avoid SmartAutoComplete crash
    tx.dispose();
    _autoController?.dispose();


    widget.socket?.off("room_return");
    widget.socket?.off("Status");
    widget.socket?.off("finished");

    _taskScrollController.dispose();
    _screenscrollbar.dispose();
    super.dispose();
  }



  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // screen size
    w = size.width;
    h = size.height;


    // FIX 2: Wrap the entire Scaffold in a ScaffoldMessenger with our key
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/blue_panoramic.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: _GlassBox(
                  child: SingleChildScrollView(
                    controller: _screenscrollbar,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                                color: rightroom ? Colors.white : Colors.red, width: 3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue value) {
                              if (value.text.isEmpty) return const Iterable<String>.empty();
                              return globals.roomNumbers.where((item) =>
                                  item.contains(value.text.toLowerCase()));
                            },
                            onSelected: (String item) {
                              tx.text = item;
                              setState(() {
                                if(item.isNotEmpty)
                                {
                                  int? r = int.parse(item ?? "")??0;
                                  widget.socket?.emit("room_check", {
                                    "user_id": globals.userid,
                                    "room": r ,
                                    "token":globals.token
                                  });
                                }
                                room_check_upper(item);
                              });
                            },
                            fieldViewBuilder: (BuildContext context,
                                TextEditingController fieldController,
                                FocusNode focusNode,
                                VoidCallback onFieldSubmitted) {
                              _autoController = fieldController;
                              fieldController.addListener(() {
                                tx.text = fieldController.text;
                              });
                              return TextField(
                                maxLength: 4,
                                onChanged: (value) {
                                  setState(() {
                                    //if(value.isNotEmpty)
                                    //{
                                    int? r = int.parse(value ?? "")??0;
                                    widget.socket?.emit("room_check", {
                                      "user_id": globals.userid,
                                      "room": r ,
                                      "token":globals.token
                                    });
                                    //}

                                    room_check_upper(value);
                                  });
                                },
                                controller: fieldController,
                                focusNode: focusNode,
                                cursorColor: Colors.white,
                                textAlignVertical: TextAlignVertical.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  counterText: "",
                                  hintText: "Room number",
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.zero,
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        rightroom = true;
                                        _autoController?.clear();
                                      });

                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // PICKUP LOCATION
                        const Text(
                          "Pickup location (optional)",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            alignment: WrapAlignment.start,
                            children: List.generate(pickupLocations.length, (index) {
                              return ChoiceChip(
                                side: const BorderSide(color: Colors.transparent, width: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                selectedColor: Colors.black26,
                                label: Text(pickupLocations[index]),
                                labelStyle: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                selected: is_selected[index],
                                onSelected: (_) {
                                  setState(() {
                                    reseter(index, is_selected);
                                    if (is_selected[index]) {
                                      requester = pickupLocations[index];
                                    } else {
                                      requester = "Null";
                                    }
                                  });
                                },
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // TASK
                        const Text(
                          "Task",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 56,
                          child: Scrollbar(
                            controller: _taskScrollController,
                            thumbVisibility: true,
                            child: ListView(
                              controller: _taskScrollController,
                              scrollDirection: Axis.horizontal,
                              children: [
                                _task("Transfer", 0),
                                _task("Departure", 1),
                                _task("Other", 2),
                                _task("Sterilize Bottles", 3),
                                _task("Collect Laundry", 4),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // PRIORITY & COUNTER
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child:     DropdownButton<String>(
                                    hint: const Text("Attention Level"),
                                    //value: dropdown,
                                    value: dropdown,
                                    items: const [
                                      DropdownMenuItem(value: 'VIP / Executives', child: Text('VIP / Executives')),
                                      DropdownMenuItem(value: 'Repeaters', child: Text('Repeaters')),
                                      DropdownMenuItem(value: 'C-Report', child: Text('C-Report')),
                                      DropdownMenuItem(value: 'Mobility Issues', child: Text('Mobility Issues')),
                                      DropdownMenuItem(value: 'Attention', child: Text('Attention')),
                                    ],
                                    onChanged: (v) => setState(() => dropdown = v),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _counter(),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // REQUEST BUTTON
                        Center(
                          child: SizedBox(
                            width: size.width * 0.7,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _sendRequest,
                              child: const Text(
                                "Request",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // SCHEDULE
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: scheduleEnabled,
                                    onChanged: (value) => _toggleSchedule(value ?? false),
                                    activeColor: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Schedule Request",
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              if (scheduleEnabled && scheduledTime != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Scheduled for ${scheduledTime!.format(context)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _task(String text, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ChoiceChip(
        side: const BorderSide(color: Colors.transparent, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        selectedColor: Colors.black26,
        label: Text(text),
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        selected: is_selected_2[index],
        onSelected: (_) {
          setState(() {
            reseter(index, is_selected_2);
            if (is_selected_2[index]) {
              requester_2 = text;
            } else {
              requester_2 = "";
            }
          });
        },
      ),
    );
  }

  Widget _counter() {
    return Container(
      height: 52,
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.red),
            onPressed: () => setState(() {
              if (counter > 0) counter--;
            }),
          ),
          Text(
            "$counter",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green),
            onPressed: () => setState(() => counter++),
          ),
        ],
      ),
    );
  }

  // --- LOGIC ---

  void _sendRequest() {
    text = tx.text;
    int? room = int.tryParse(text ?? "") ?? 0;
    bool selector = is_selected.contains(true);
    bool selector2 = is_selected_2.contains(true);

    if (!selector) requester = "Null";
    if (!selector2) requester_2 = "";

    //if (selector2 && text!.isNotEmpty && dropdown != null && counter != 0) {
     if (text!.isNotEmpty && dropdown != null && counter != 0) {
      final rid = Random().nextInt(999999) + 100000;

      widget.socket?.emit("locator", {
        "location": requester,
        "Room Number": room,
        "Task": requester_2,
        "DropDown": dropdown,
        "Counter": counter,
        "RID": rid,
        "token":globals.token
      });
    } else {
      if (rightroom == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
            content: SizedBox(
              height: h*0.11, // Force height
              child: const Center(
                child: Text("Fill All Mandatory Fields",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            width: w ,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            duration: const Duration(seconds: 2),
          ),);}
    }
  }

  Future<void> _toggleSchedule(bool value) async {
    if (value) {
      final picked = await _openScheduleDialog();
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          scheduleEnabled = true;
          scheduledTime = picked;
        });
      } else {
        setState(() {
          scheduleEnabled = false;
        });
      }
    } else {
      setState(() {
        scheduleEnabled = false;
        scheduledTime = null;
      });
    }
  }

  Future<TimeOfDay?> _openScheduleDialog() async {
    TimeOfDay tempTime = scheduledTime ?? TimeOfDay.now();
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: const Text("Select Scheduled Time", style: TextStyle(fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xfff4f6f8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffe0e3e7)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(tempTime.format(context),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: tempTime);
                            if (picked != null) setStateDialog(() => tempTime = picked);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(tempTime),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
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
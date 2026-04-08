import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:nostos/user_id.dart' as globals;


// ########### MALAKIES GIA NA LEITOYRGEI TO DROP DOWN MENU #########

typedef Attention = DropdownMenuEntry<AttentionLevel>;

enum AttentionLevel {
  vip('VIP / Executives'),
  rep('Repeaters'),
  c('C-Report'),
  mob('Mobility Issues'),
  att('Attention');

  const AttentionLevel(this.level);
  final String level;

  static final List<Attention> entries = UnmodifiableListView<Attention>(
    values.map<Attention>(
      (AttentionLevel level) => Attention(
        value: level,
        label: level.level,
      ),
    ),
  );
}





// ###########################################################


class AttentionRooms extends StatefulWidget {
  late IO.Socket? socket;  
  AttentionRooms({super.key,required this.socket});

  @override
  State<AttentionRooms> createState() => _AttentionRoomsState();
}

// ###########  _AttentionRoomsState ΜΕΧΤΙ ΚΑΙ ΓΡΑΜΜΗ 250 ##############################

class _AttentionRoomsState extends State<AttentionRooms> {

  AttentionLevel? selectedLevel;
  final TextEditingController roomController = TextEditingController();
  final TextEditingController attentionController = TextEditingController();
  TextEditingController? _autoController;
  bool rightroom = true;

  void  room_check_upper(String room){
    if(globals.roomNumbers.contains(room)){
      rightroom = true;
      return;
    }
    rightroom = false;
  }

  void clearer() {
    setState(() {
      roomController.clear();
      _autoController?.clear();
      rightroom = true;
    });
  }

  bool loading = true;

@override
  void initState() {
  super.initState();

  globals.State = "Attention_List";

  widget.socket?.off("AttentionList");
  widget.socket?.on("AttentionList", (data) {
  if (!mounted) return;
  final List list = data["list"];
  setState(() {
  attentionList = list.map((e) {
  return AttentionRoom(
  number: e["number"],
  level: AttentionLevel.values.firstWhere(
  (lvl) => lvl.level == e["level"],  // ← .level not .name
  orElse: () => AttentionLevel.att,  // ← safe fallback
  ),
  );
  }).toList();
  loading = false;

  });
  if(data["editing"] == false){
  clearer();
  }

  });

  // ask server for the list
  widget.socket?.emit("send_attention_list",{"token":globals.token});

  
}


  @override
  Widget build(BuildContext context) {
     final size = MediaQuery.of(context).size; // screen size
     final w= size.width;
     final h = size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      body:  Container(
  decoration: const BoxDecoration(
    image: DecorationImage(
      //image: AssetImage('assets/ikos_odisia_attention.png'),
      //image: AssetImage('assets/room_attention.png'),
      image: AssetImage('assets/room2_attention.webp'),
      fit: BoxFit.cover,
    ),
  ),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), // 👈 blur strength
    child: Container(
      color: Colors.white.withOpacity(0.15), // controls readability
      child: SafeArea(
        child: Column(
          children: [

            Padding(padding: EdgeInsets.all(15),child: _GlassBox(child: _fieldsSection())),
            Expanded(child: _dynamicSection()),
          ],
        ),
      ),
    ),
  ),
),
    );
  }

  // ===================== (Static) INPUT SECTION =====================

  Widget _fieldsSection() {
    return
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [

            // ===== Room input =========
            // Expanded(
            //   flex: 2,
            //   child: TextFormField(
            //     controller: roomController,
            //     keyboardType: TextInputType.number,
            //     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            //     cursorColor: Colors.white,
            //     decoration: InputDecoration(
            //       hintText: 'Enter Room',
            //         hintStyle: TextStyle(
            //         fontSize: 14 ),
            //       contentPadding:
            //           const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            //       enabledBorder: OutlineInputBorder(
            //         borderSide: const BorderSide(color: Colors.white, width: 2.0),
            //         borderRadius: const BorderRadius.all(Radius.circular(12.0)),
            //         gapPadding: 5.0,
            //       ),
            //       focusedBorder: OutlineInputBorder(
            //         borderSide: const BorderSide(color: Colors.white, width: 4.0),
            //         borderRadius: const BorderRadius.all(Radius.circular(12.0)),
            //         gapPadding: 5.0,
            //       ),
            //     ),
            //   ),
            // ),
            //
            // const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child:Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
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
                    roomController.text = item;
                    setState(() {
                      room_check_upper(item);
                    });
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    _autoController = fieldController;
                    fieldController.addListener(() {
                      roomController.text = fieldController.text;
                    });
                    return TextField(
                      maxLength: 4,
                      onChanged: (value) {
                        setState(() {
                          //if(value.isNotEmpty)
                          //
                          //}

                          room_check_upper(value);
                        });
                      },
                      controller: fieldController,
                      focusNode: focusNode,
                      cursorColor: const Color.fromARGB(255, 0, 164, 214),
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
                ),),
            ),

            const SizedBox(width: 12),

            // ======== Attention dropdown =======
            Expanded(
              flex: 2,
              child: SizedBox(
                width: 160,
                child: DropdownMenu<AttentionLevel>(
                  enableFilter: false,          // ❌ disables typing filter oute kan einai toso xrhshmo
                  requestFocusOnTap: false,     // ❌ prevents keyboard auto kati kanei
                  dropdownMenuEntries: AttentionLevel.entries,
                  controller: attentionController,
                   label: Text(
                  'Attention',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14),),
                onSelected: (AttentionLevel? level) {
                 setState(() {
                    selectedLevel = level;});},
                  inputDecorationTheme: InputDecorationTheme(
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white, width: 2.0),
                      borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                      gapPadding: 5.0,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white, width: 4.0),
                      borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                      gapPadding: 5.0,
                    ),
                  contentPadding:
                     const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
               ),
            ),
           ),
          ),
         ),

            const SizedBox(width: 12),

            // ========= Add button ==========
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (roomController.text.isEmpty ||
                        selectedLevel == null || rightroom == false){

                      clearer();
                      attentionController.clear();
                      return;

                    };

                    setState(() {
                      attentionList.add(
                        AttentionRoom(
                          number: int.parse(roomController.text),
                          level: selectedLevel,                         
                        ),
                      );
                      widget.socket?.emit("AttentionAddition", {"addition":
                      {
                        "number": int.parse(roomController.text),
                        "level": selectedLevel!.name, // enum → string
                      },
                        "token":globals.token,
                        "editing":false

                      }
                        );

                      roomController.clear();
                      attentionController.clear();
                      selectedLevel = null;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.white;
                      }
                      return Colors.transparent;
                    }),

                    side: WidgetStateProperty.all(const BorderSide(color: Colors.white, width: 2)),

                    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.black;
                      }
                      return Colors.black;
                    }),

                    elevation: WidgetStateProperty.all(0),
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    alignment: Alignment.center,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: WidgetStateProperty.all(const Size(0, 0)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Add',
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )),
              ),
            ),
          ],
        ),

    );
  }

  // ===================== DYNAMIC SECTION =====================

  Widget _dynamicSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: loading == true? Center(
            child: LoadingAnimationWidget.threeArchedCircle(
              color: Colors.blue,
              size: 50,
            ),
          ):LayoutBuilder(
        builder: (context, constraints) {
          return ScrollConfiguration(behavior: NoStretchScrollBehavior(), child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: attentionList.mapIndexed((index, room) {
                  return Padding(padding: EdgeInsetsGeometry.only(bottom: 10), child: _GlassBox(child: ItemWidget(
                    roomNumber: room.number,
                    level: room.level! ,
                    onDelete: () {
                      setState(() {
                        attentionList.removeAt(index);
                        widget.socket?.emit("AttentionRemoval",{"index":index,"token":globals.token,"editing":false});
                      });
                    },
                    onEdit: () {
                      setState(() {
                        roomController.text = room.number.toString();
                        _autoController!.text =  room.number.toString();
                        selectedLevel = room.level as AttentionLevel?;
                        attentionController.text = room.level!.level;
                        attentionList.removeAt(index);
                        widget.socket?.emit("AttentionRemoval",{"index":index,"token":globals.token,"editing":true});
                      });
                    },)
                  ));
                }).toList(),
              ),
            ),
          ));
        },
      ),
    );
  }
}













// ############# Το entity-καρτέλα για κάθε Δωμάτιο στη δυναμική Λίστα #############################

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    super.key,
    required this.roomNumber,
    required this.level,
    this.onEdit,
    this.onDelete,
  });

  final int roomNumber;
  final AttentionLevel level;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color _chipColor() {
    switch (level) {
      case AttentionLevel.vip:
        return const Color(0xFF1A2C42);
      case AttentionLevel.rep:
        return Colors.teal.shade600;
      case AttentionLevel.c:
        return Colors.red.shade700;
      case AttentionLevel.mob:
        return Colors.orange.shade700;
      case AttentionLevel.att:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Room $roomNumber",
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2C42),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _chipColor().withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    level.level,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _chipColor(),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF1A2C42)),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade700),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ################ Η Λογική Λίστα που κρατάει τα δωμάτια ###########################################

late List<AttentionRoom> attentionList;


class AttentionRoom {
  final int number;
  final AttentionLevel? level;

  AttentionRoom({
    required this.number,
    required this.level,
  });
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

class NoStretchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // This completely removes the Android stretch and glow effects!
    return child;
  }
}
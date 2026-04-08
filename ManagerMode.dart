import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nostos/user_id.dart' as globals;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'ManagerModeBar.dart'; // Ensure this file exists

class ManagerMode extends StatefulWidget {
  final IO.Socket? socket;

  const ManagerMode({super.key, required this.socket});

  @override
  State<ManagerMode> createState() => _ManagerModeScreen();
}

class _ManagerModeScreen extends State<ManagerMode> {
  late int pageIndex;
  List<Map<String, dynamic>> usr = [];
  List<Map<String, dynamic>> gr = [];
  List<Map<String, dynamic>> temp = [];
  List<Map<String, dynamic>> currentList= [];
  @override
  void initState() {
    super.initState();
    pageIndex = 0;

    widget.socket?.off("groom_getter");
    widget.socket?.on("groom_getter", (data) {
      setState(() {
        gr = (data["grooms"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
            if(pageIndex == 1){
               temp = gr;
            }
        
      });
    });
    widget.socket?.off("user_getter");
    widget.socket?.on("user_getter", (data) async {
      print(data);
      setState(() {
        usr = (data["users"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        
        if(pageIndex == 0){
               temp = usr;
            }
      });
    });

    widget.socket?.emit("get_work", {"job":"grooms"});
    widget.socket?.emit("get_work", {"job":"users"});


  }

  void activate_workers(){
    setState(() {
      String job2 = pageIndex == 0?"users":"grooms";
      widget.socket?.emit("activate_workers",{"table":job2,"workers":currentList});
    });
    currentList.clear();
  }

  void deactivate_workers(){
    setState(() {
      String job2 = pageIndex == 0?"users":"grooms";
      widget.socket?.emit("deactivate_workers",{"table":job2,"workers":currentList});
    });
    currentList.clear();
  }

  void delete_workers(){
    setState(() {
      String job2 = pageIndex == 0?"users":"grooms";
      widget.socket?.emit("delete_workers",{"table":job2,"workers":currentList});
    });
    currentList.clear();
  }


  void goToPage(int index) {
    if (index == pageIndex) return;
    setState(() {
      pageIndex = index;
      if (pageIndex == 0) {
        temp = usr;
        /*
        temp=[
          {"id":"groom001",
            "name":"Niggers",
            "status":"active",},
          {"id":"groom002",
            "name":"Thug",
            "status":"active",},
          {"id":"groom003",
            "name":"White",
            "status":"inactive",}
        ];
        */

        currentList =[];
      } else {
        temp = gr;
        /*
        temp=[
          {"id":"groom001",
            "name":"Niggers",
            "status":"active",},
          {"id":"groom002",
            "name":"Thug",
            "status":"active",},
          {"id":"groom003",
            "name":"White",
            "status":"inactive",}
        ];
        */

        currentList=[];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;
    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND LAYER
          // We use Positioned.fill to ensure it covers the whole screen
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/ikos_purple.webp"),

                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // 👈 blur strength
            child: Container(
              child:
              // 2. CONTENT LAYER
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 15), // Top padding

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: _GlassBox(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8.0, // Κενό ανάμεσα στα κουμπιά οριζόντια
                            runSpacing: 8.0,
                            //mainAxisAlignment:
                            //MainAxisAlignment.spaceEvenly,
                            children: [
                              // WRAP EACH BUTTON IN "EXPANDED" TO MAKE IT SHRINK
                              Expanded(
                                child: _buildMenuButton(
                                  icon: Icons.add,
                                  label: (pageIndex == 1)
                                      ? "Add groom"
                                      : "Add user",
                                  isMobile: isMobile,
                                  onTap: () => _showAddDialog(context),
                                ),
                              ),
                              Expanded(
                                child: _buildMenuButton(
                                  icon: Icons.delete_forever,
                                  label: (pageIndex == 1)
                                      ? (currentList.length>1)?"Remove grooms":"Remove groom"
                                      : (currentList.length>1)?"Remove users": "Remove user",
                                  isMobile: isMobile,
                                  onTap: () => _showDialog(context,currentList: currentList,frame: "Are you sure you want to remove", onTap: delete_workers ),
                                ),
                              ),
                              Expanded(
                                child: _buildMenuButton(
                                  icon: Icons.check,
                                  label: (pageIndex == 1)
                                      ? (currentList.length>1)?"Activate grooms":"Activate groom"
                                      : (currentList.length>1)?"Activate users": "Activate user",
                                  isMobile: isMobile,
                                  onTap: () => _showDialog(context,currentList: currentList,frame: "Are you sure you want to activate", onTap: activate_workers ),
                                ),
                              ),
                              Expanded(
                                child: _buildMenuButton(
                                  icon: Icons.close,
                                  label: (pageIndex == 1)
                                      ? (currentList.length>1)? "Deactivate grooms":"Deactivate user"
                                      : (currentList.length>1)? "Deactivate users":"Deactivate user",
                                  isMobile: isMobile,
                                  onTap: () => _showDialog(context,currentList: currentList,frame: "Are you sure you want to deactivate", onTap: deactivate_workers ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10,),
                    //edo fortonoun oi tipades
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: temp.length,
                        itemBuilder: (context, index) {
                          return _buildCard(
                            user: temp[index],
                            index: index,
                            currentList: currentList,
                          );
                        },
                      ),
                    ),

                    // Spacer pushes the nav bar to the bottom

                    // --- NAVIGATION BAR ---
                    // This is now outside the scroll view, so it can fill the screen width
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ManagerModeBar(
                          currentIndex: pageIndex,
                          onTap: (index) =>
                              goToPage(index), // Fixed the callback
                        ),
                      ),
                    )

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //otan pas na diagrapseis
  Future<void> _showDialog(BuildContext context,{required currentList, required onTap,required frame}) async {
    // Determine mode (Groom vs User)
    final isGroom = (pageIndex == 1); // Assuming 0 is groom based on your previous logic
    final count = currentList.length;
    final String type = isGroom ? (count!=1)?"grooms":"groom":(count!=1)?"users": "user";
    return showDialog(
      context: context,
      barrierColor: Colors.black54, // Slight dark background behind the glass
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Transparent to let GlassBox show
          insetPadding: const EdgeInsets.all(10), // Small padding from screen edge
          child: Center(
            child: ConstrainedBox(
              // --- LIMIT WIDTH HERE ---
              constraints: const BoxConstraints(maxWidth: 400),

              child: _GlassBox(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Shrink vertically to fit content
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- HEADER ---
                      Text(
                        "$frame $count $type",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))
                            ]
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- ACTION BUTTONS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Cancel Button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.red,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("No", style: TextStyle(color: Colors.white70)),
                          ),
                          const SizedBox(width: 8),

                          // Add Button
                          ElevatedButton(
                            onPressed: () {
                              onTap();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.white,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  //Gia na ginoun
  Widget _buildCard({
    required Map<String, dynamic> user,
    required int index,
    required List<Map<String, dynamic>> currentList,
  }) {
    return Padding(
      // Add vertical spacing so cards don't touch
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 10.0),
      child: _GlassBox(
        xroma: (currentList.contains(user))?Colors.black :(user['status']=='active')? Colors.lightGreenAccent:Colors.redAccent,
        child: CheckboxListTile(
          // 1. STATE & LOGIC
          value: (currentList.contains(user))? true:false,
          onChanged: (bool? newValue) {
            setState(() {
              if(currentList.contains(user)){
                currentList.remove(user);
              } else{
                currentList.add(user);
              }
            });
          },

          // 2. LAYOUT
          // 'secondary' places the widget at the start (left side)
          secondary: CircleAvatar(
            backgroundColor: Colors.white24,
            child: Text(
              user['name']?.toString().isNotEmpty == true
                  ? user['name'][0]
                  : "?",
              style: const TextStyle(color: Colors.white),
            ),
          ),

          // 'title' is the top line of text
          title: Text(
            user['name']?.toString() ?? "Unknown",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          // 'subtitle' is the bottom line of text
          subtitle: Row(children: [Text(
            user['id']?.toString() ?? "No ID",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
            Text( (user['status']=="active")?" is active":" is not active",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            )
          ]
          ),

          // 3. STYLING
          activeColor: Colors.transparent, // Color of box when checked
          checkColor: Colors.black, // Color of checkmark
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          controlAffinity: ListTileControlAffinity.trailing, // Puts checkbox on the right
        ),
      ),
    );
  }

  // Helper widget to reduce code duplication
  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: _GlassBox(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isMobile ? 12 : 20,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black),
              if (!isMobile) ...[
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    // Controllers to capture text
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final passwordController = TextEditingController();

    // Determine mode (Groom vs User)
    final isGroom = (pageIndex == 1); // Assuming 0 is groom based on your previous logic
    final String type = isGroom ? "Groom" : "User";

    return showDialog(
      context: context,
      barrierColor: Colors.black54, // Slight dark background behind the glass
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Transparent to let GlassBox show
          insetPadding: const EdgeInsets.all(10), // Small padding from screen edge
          child: Center(
            child: ConstrainedBox(
              // --- LIMIT WIDTH HERE ---
              constraints: const BoxConstraints(maxWidth: 400),

              child: _GlassBox(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Shrink vertically to fit content
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- HEADER ---
                      Text(
                        "Add New $type",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))
                            ]
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- INPUT FIELDS ---
                      _buildGlassTextField(
                          controller: nameController,
                          icon: Icons.person,
                          hint: "Name"
                      ),
                      const SizedBox(height: 16),
                      _buildGlassTextField(
                          controller: idController,
                          icon: Icons.badge,
                          hint: "ID"
                      ),
                      const SizedBox(height: 16),
                      _buildGlassTextField(
                          controller: passwordController,
                          icon: Icons.remove_red_eye,
                          hint: "Password"
                      ),
                      const SizedBox(height: 30),

                      // --- ACTION BUTTONS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel Button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.red,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                          ),
                          const SizedBox(width: 8),

                          // Add Button
                          ElevatedButton(
                            onPressed: () {
                              //widget.socket?.emit("requests_per_day_time");
                              widget.socket?.emit("average_groom_completion_time");
                              widget.socket?.emit("average_requests_per_day_time");
                              String job = pageIndex == 0?"users":"grooms";
                              widget.socket?.emit("add_user", {
                                "new_user":idController.text,"job":job,"name":nameController.text,"password":passwordController.text
                              });
                              Navigator.pop(context);
                              setState(() {

                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.white,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Add"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// --- HELPER FOR GLASSY TEXT FIELDS ---
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        cursorColor: Colors.white,
        controller: controller,
        style: const TextStyle(color: Colors.white), // Typing text color
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none, // Removes the underline line
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  void onSelected(bool? value) {
  }
}

// =======================
// REUSABLE GLASSBOX WIDGET
// =======================
class _GlassBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color xroma;
  const _GlassBox({required this.child, this.width, this.height, this.onTap,this.xroma=Colors.white});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: xroma.withOpacity(0.3),
              border: Border.all(color: xroma.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(25),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
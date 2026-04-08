import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nostos/main.dart';
import 'package:nostos/main.wrapper.dart';
import 'package:nostos/user.wrapper.dart';
import 'package:nostos/user_id.dart' as globals;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'ManagerMode.dart';

// =======================
// PAGE ENUM
// =======================

enum AdminPage {
  dashboard,
  grooms,
  groomMode,
  userMode,
  manageMode
}

List<dynamic> hoursList = [];
List<Map<String, dynamic>> locationsList = [];
List<Map<String, dynamic>> top2Rooms = [];
List<FlSpot> averageHoursList = [];
List<dynamic> groomsAverageHoursList = [];
int TotalDailyRequests = 0;
int LateDailyRequests = 0;
String locationsText = "Loading...";
String roomText = "Loading";
GroomStatistics groomStatistic=GroomStatistics();
// =======================
// MAIN APP ENTRY SCREEN (NOW STATEFUL)
// =======================

class AdminPanelMobile extends StatefulWidget {
  final IO.Socket? socket;
  const AdminPanelMobile({super.key, required this.socket});


  @override
  State<AdminPanelMobile> createState() => _AdminPanelMobileState();
}

class _AdminPanelMobileState extends State<AdminPanelMobile> {
  final secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    widget.socket?.off("requests_per_day_time_acceptor");
    widget.socket?.on("requests_per_day_time_acceptor",(data){

      setState(() {
        hoursList = data['hours'];
        for (var item in hoursList) {
          print('Slot: ${item['slot']}, Count: ${item['count']}');
        }
      });


    });

    widget.socket?.off('daily_groom_deliveries');
    widget.socket?.on('daily_groom_deliveries', (data) {
      setState(() {
        groomStatistic.dailyGroomDeliveries = data['daily_groom_deliveries'] ?? [];
      });
    });

    widget.socket?.off('seven_days_groom_deliveries');
    widget.socket?.on('seven_days_groom_deliveries', (data) {
      setState(() {
        groomStatistic.sevenDaysGroomDeliveries = data['seven_days_groom_deliveries'] ?? [];
      });
    });

    widget.socket?.off('thirty_days_groom_deliveries');
    widget.socket?.on('thirty_days_groom_deliveries', (data) {
      setState(() {
        groomStatistic.thirtyDaysGroomDeliveries = data['thirty_days_groom_deliveries'] ?? [];
      });
    });

    widget.socket?.off('all_time_groom_deliveries');
    widget.socket?.on('all_time_groom_deliveries', (data) {
      setState(() {
        groomStatistic.allTimeGroomDeliveries = data['all_time_groom_deliveries'] ?? [];
      });
    });

    widget.socket?.off("average_execution_time_per_groom_for_today");
    widget.socket?.on('average_execution_time_per_groom_for_today', (data) {
      setState(() {
        groomStatistic.averageExecutionTimeToday = data['average_execution_time_per_groom_for_today'] ?? [];
      });
    });

    widget.socket?.off("average_execution_time_per_groom_7_days");
    widget.socket?.on('average_execution_time_per_groom_7_days', (data) {
      setState(() {
        groomStatistic.averageExecutionTimeWeekly = data['average_execution_time_per_groom_7_days'] ?? [];
      });
    });

    widget.socket?.off("average_execution_time_per_groom_30_days");
    widget.socket?.on('average_execution_time_per_groom_30_days', (data) {
      setState(() {
        groomStatistic.averageExecutionTimeMonthly = data['average_execution_time_per_groom_30_days'] ?? [];
      });
    });

    widget.socket?.off("average_execution_time_per_groom_all_time");
    widget.socket?.on('average_execution_time_per_groom_all_time', (data) {
      setState(() {
        groomStatistic.averageExecutionTimeAllTime = data['average_execution_time_per_groom_all_time'] ?? [];
      });
    });

    widget.socket?.off("top_2_locations");
    widget.socket?.on("top_2_locations",(data){
      print("📩 Server says: $data");

      setState(() {
        locationsList = List<Map<String, dynamic>>.from(data["top_2_locations"]);
        if (locationsList.isNotEmpty) {
          locationsText = locationsList.map((item) => item["location"]?.toString() ?? "Unknown").join(", ");
        } else {
          locationsText = "None";
        }
      });
    });

    widget.socket?.off("top_2_rooms");
    widget.socket?.on("top_2_rooms",(data){
      setState(() {
        top2Rooms = List<Map<String, dynamic>>.from(data['top_2_rooms']);
        if (top2Rooms.isNotEmpty) {
          roomText = top2Rooms.map((item) => item["room"]?.toString() ?? "Unknown").join(", ");
        } else {
          roomText = "None";
        }
      });
    });

    widget.socket?.off("Logout_Confirmation");
    widget.socket?.on("Logout_Confirmation",(data){

      Logout();

    });


    widget.socket?.off("average_requests_per_day_time_acceptor");
    widget.socket?.on("average_requests_per_day_time_acceptor",(data){

      print("📩 Server says: $data");
      if (data['hours'] is List) {
        final spots = (data['hours'] as List).map<FlSpot>((item) {
          final double x = (item['slot'] as num).toDouble();
          final double y = (item['count'] as num).toDouble();
          return FlSpot(x, y);
        }).toList();
        print("Spots length: ${averageHoursList.length}");

        setState(() {
          averageHoursList = spots;
        });
      }
      else{

      }


    });

    widget.socket?.off("total_daily_requests_acceptor");
    widget.socket?.on("total_daily_requests_acceptor",(data){
      setState(() {
        TotalDailyRequests = data["total_daily_requests"];
      });

    });




    widget.socket?.off("average_groom_completion_time_acceptor");
    widget.socket?.on("average_groom_completion_time_acceptor",(data){

      setState(() {
        groomsAverageHoursList= data['grooms'];
      });

    });

    widget.socket?.off("late_requests_for_today_acceptor");
    widget.socket?.on("late_requests_for_today_acceptor",(data){

      setState(() {
        LateDailyRequests = data["late_requests_for_today"];
      });

    });

    widget.socket?.emit('all_time_groom_deliveries');
    widget.socket?.emit("late_requests_for_today");
    widget.socket?.emit("top_2_rooms");
    widget.socket?.emit("top_2_locations");
    widget.socket?.emit("admin_total_daily_requests_sender_event");
    widget.socket?.emit("late_requests_for_today");
    widget.socket?.emit("get_average_requests_per_day");
    widget.socket?.emit('daily_groom_deliveries');
    widget.socket?.emit('average_today_requests_per_groom');
    widget.socket?.emit('seven_days_average');
    widget.socket?.emit('thirty_days_average');
    widget.socket?.emit('seven_days_groom_deliveries');
    widget.socket?.emit('thirty_days_groom_deliveries');
    widget.socket?.emit('average_execution_time_per_groom_for_today');
    widget.socket?.emit('average_execution_time_per_groom_7_days');
    widget.socket?.emit('average_execution_time_per_groom_30_days');
    widget.socket?.emit('average_execution_time_per_groom_all_time');
    widget.socket?.emit('average_time_to_complete_a_task_today');
    widget.socket?.emit('average_time_to_complete_a_task_7_days');
    widget.socket?.emit('average_time_to_complete_a_task_30_days');
    widget.socket?.emit('average_time_to_complete_a_task_all_time');
  }

  @override
  void dispose() {
    // Clean up listeners here if needed
    super.dispose();
  }

  Future<void> Logout() async {
    String? savedUserId = globals.userid;
    while(savedUserId == globals.userid){
      await secureStorage.delete(key: 'userId');
      await secureStorage.delete(key: 'NostosPassword');
      await secureStorage.delete(key: 'NostosToken');
      await Future.delayed(const Duration(milliseconds: 200));
      savedUserId = await secureStorage.read(key: 'userId');
      print(savedUserId);
    }
    await FlutterExitApp.exitApp();
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MenuAppController(),
      // Pass the socket from the widget configuration to the layout
      child: _MainLayout(socket: widget.socket),
    );
  }
}

// =======================
// CONTROLLER
// =======================

class MenuAppController extends ChangeNotifier {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AdminPage _currentPage = AdminPage.dashboard;

  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;
  AdminPage get currentPage => _currentPage;

  void controlMenu() {
    if (!_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  void setPage(AdminPage page) {
    _currentPage = page;
    notifyListeners();
  }
}

// =======================
// MAIN LAYOUT
// =======================

class _MainLayout extends StatelessWidget {
  final IO.Socket? socket;

  const _MainLayout({required this.socket});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MenuAppController>();
    //final isDesktop = MediaQuery.of(context).size.width >= 850;

    //final double sidebarWidth = 260.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.read<MenuAppController>().controlMenu(),
          child: const Icon(Icons.menu, color: Colors.white,shadows: [Shadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 0))],),
        ),
        titleTextStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 25, shadows: [Shadow(color: Colors.black87, blurRadius: 50, offset: Offset(0, 0))]),
        centerTitle: true,
        title: switch (controller.currentPage) {
          AdminPage.dashboard => Text("Dashboard"),
          AdminPage.grooms => Text("Metrics"),
          AdminPage.groomMode => Text("Groom"),
          AdminPage.userMode => Text("User"),
          AdminPage.manageMode => Text("Manager"),
        },
      ),
      key: controller.scaffoldKey,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      drawer: _SideMenu(isDrawer: true,socket: socket,),
      body: Stack(
        children: [
          // 1. GLOBAL BACKGROUND
          Container(
            decoration:  BoxDecoration(
              image: DecorationImage(
                image: controller.currentPage.index == 1
                    ? const AssetImage("assets/ikos_groom.webp")
                    : const AssetImage("assets/ikos_paralia.webp"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. CONTENT AREA
          Positioned.fill(
            child: IndexedStack(
              index: controller.currentPage.index,
              children: [
                // CASE A: Standard Pages (Dashboard)
                /*
                Padding(
                  padding: EdgeInsets.only(left: 0),
                  child:
                ),

                 */
                SafeArea(child: _DashboardScreen(socket)),
                /*
                Padding(
                  padding: EdgeInsets.only(left: 0),
                  child: const SafeArea(child: _WorkerListScreen()),
                ),
                 */
                SafeArea(child: _WorkerListScreen()),
                // CASE B: The Wrappers (User/Groom Mode)
                // THE TRICK: We wrap these in a MediaQuery that adds "padding.left".
                // The UserWrapper sees this as a "Safe Area" (like a notch).
                // It keeps the background full screen, but pushes the buttons right.
                _GroomModeScreen(socket: socket),



                _UserModeScreen(socket: socket),



                _ManageModeScreen(socket: socket)
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER FUNCTION FOR THE TRICK ---

}
//ManageMode Screen
class _ManageModeScreen extends StatelessWidget {
  final IO.Socket? socket;

  const _ManageModeScreen({required this.socket});


  @override
  Widget build(BuildContext context) {

    return ManagerMode(socket: socket);

  }
}




//UserMode screen
class _UserModeScreen extends StatelessWidget {
  final IO.Socket? socket;
  const _UserModeScreen({required this.socket});

  @override
  Widget build(BuildContext context) {
    // Check if we are on mobile to decide whether to show the menu button
    //final isMobile = MediaQuery.of(context).size.width < 850;

    return Stack(
      children: [
        // 1. The Main Content (Map/User Interface)
        Positioned.fill(
          child: UserWrapper(socket: socket),
        ),

        // 2. Floating Menu Button (Mobile Only)
        // We put this in a Stack so it floats ON TOP of the map/content
        /*
        if (isMobile)
        //if(true)
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: _GlassBox(
                width: 50,
                height: 50,
                onTap: () => context.read<MenuAppController>().controlMenu(),
                child: const Icon(Icons.menu, color: Colors.white),
              ),
            ),
          ),
         */
      ],
    );
  }
}

//Groom Mode screen
class _GroomModeScreen extends StatelessWidget {
  final IO.Socket? socket;
  const _GroomModeScreen({required this.socket});

  @override
  Widget build(BuildContext context) {
    //final isMobile = MediaQuery.of(context).size.width < 850;

    return Stack(
      children: [
        // 1. The Main Content
        Positioned.fill(
          child: MainWrapper(socket: socket,includeBreak: false,),
        ),

        /*
        if (isMobile)
        //if(true)
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: _GlassBox(
                width: 50,
                height: 50,
                onTap: () => context.read<MenuAppController>().controlMenu(),
                child: const Icon(Icons.menu, color: Colors.white),
              ),
            ),
          ),

         */
      ],
    );
  }
}

// =======================
// SIDEBAR COMPONENTS
// =======================

class _SideMenu extends StatelessWidget {
  final bool isDrawer;
  final IO.Socket? socket;

  const _SideMenu({this.isDrawer = false, required this.socket});

  @override
  Widget build(BuildContext context) {
    if (!isDrawer) return _SideMenuContent(socket: socket,);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: _GlassBox(
          child: _SideMenuContent(socket: socket,),
        ),
      ),
    );
  }

}

class _SideMenuContent extends StatelessWidget {
  final IO.Socket? socket;

  const _SideMenuContent({required this.socket});

  Future<void> confirm(BuildContext context) async{
    bool? confirm = await showDialog(
        context: context,
        builder: (_) => Dialog(
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
                        "Are You Sure?",
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
                              Navigator.pop(context, true);
                              socket?.emit("Logout",{"signal":true,"user_id":globals.userid,"mode":globals.State,"job":globals.job});
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
        ));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MenuAppController>();

    return Column(
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide.none),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.admin_panel_settings, size: 40, color: Colors.black),
              SizedBox(height: 10),
              Text(
                "ADMIN PANEL",
                style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              _buildTile(
                context,
                "Dashboard",
                Icons.dashboard,
                AdminPage.dashboard,
                controller,
              ),
              _buildTile(
                context,
                "Grooms",
                Icons.people,
                AdminPage.grooms,
                controller,
              ),
              _buildTile(
                context,
                "User Mode",
                Icons.computer,
                AdminPage.userMode,
                controller,
              ),
              _buildTile(
                context,
                "Groom Mode",
                Icons.local_taxi_outlined,
                AdminPage.groomMode,
                controller,
              ),
              _buildTile(
                context,
                "Manage personnel",
                Icons.manage_accounts,
                AdminPage.manageMode,
                controller,
              ),
              ListTile(
                onTap: () => confirm(context),
                horizontalTitleGap: 10.0,
                leading: const Icon(Icons.logout, color: Colors.black, size: 20),
                title: const Text("Logout",
                    style: TextStyle(color: Colors.black)),
                hoverColor: Colors.white.withOpacity(0.1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
      BuildContext context,
      String title,
      IconData icon,
      AdminPage page,
      MenuAppController controller,
      ) {
    final selected = controller.currentPage == page;

    return ListTile(
      leading: Icon(icon, color: Colors.black, size: 20),
      horizontalTitleGap: 10.0,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.black,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: Colors.white.withOpacity(0.2),
      hoverColor: Colors.white.withOpacity(0.1),
      onTap: () {
        controller.setPage(page);
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
      },
    );
  }
}

// =======================
// DASHBOARD SCREEN
// =======================

class _DashboardScreen extends StatefulWidget {
  final IO.Socket? socket;
  const _DashboardScreen(this.socket);

  @override
  State<_DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<_DashboardScreen> {
  @override
  void initState() {
    super.initState();

    _onDashboardSelected();

  }

  void _onDashboardSelected() {
    // You can emit socket events here

    // socket?.emit("admin_total_daily_requests_sender_event");
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2 ,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) => _buildInfoCard(context, index),
          ),
          const SizedBox(height: 20),
          Expanded(child:
          _GlassBox(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Recent Calls",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.black, fontSize: 20)),
                  const SizedBox(height: 20),
                  Expanded(
                      //height: MediaQuery.of(context).size.height*0.4,
                      //width: double.infinity,
                      child:  _GroomPerformanceChart()),
                ],
              ),
            ),),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, int index) {
    final info = [
      {
        "title": "Critical rooms",
        "val": roomText,
        "icon": Icons.hotel,
        "color": Colors.deepOrange,
      },
      {
        "title": "Critical locations",
        "val": locationsText,
        "icon": Icons.location_on,
        "color": Colors.orangeAccent,
      },
      {
        "title": "Total calls today",
        "val": TotalDailyRequests.toString(),
        "icon": Icons.phone,
        "color": Colors.green,
      },
      {
        "title": "Late requests",
        "val": LateDailyRequests.toString(),
        "icon": Icons.dangerous,
        "color": Colors.redAccent,
      },
    ];

    return _GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                info[index]["icon"] as IconData,
                color: info[index]["color"] as Color,
                size: 40.0,
              ),
              const SizedBox(height: 12),
              Text(
                info[index]["title"] as String,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              Text(
                info[index]["val"] as String,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================
// WORKER LIST SCREEN
// =======================

class _WorkerListScreen extends StatefulWidget {
  const _WorkerListScreen({super.key});
  @override
  State<_WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<_WorkerListScreen> {
  var mode = 0;

  @override
  Widget build(BuildContext context) {
    // 1. Pick the correct lists based on the mode
    List<dynamic> activeList = switch (mode) {
      0 => groomStatistic.dailyGroomDeliveries,
      1 => groomStatistic.sevenDaysGroomDeliveries,
      2 => groomStatistic.thirtyDaysGroomDeliveries,
      3 => groomStatistic.allTimeGroomDeliveries,
      _ => groomStatistic.dailyGroomDeliveries,
    };

    List<dynamic> activeAvgList = switch (mode) {
      0 => groomStatistic.averageExecutionTimeToday,
      1 => groomStatistic.averageExecutionTimeWeekly,
      2 => groomStatistic.averageExecutionTimeMonthly,
      3 => groomStatistic.averageExecutionTimeAllTime,
      _ => groomStatistic.averageExecutionTimeToday,
    };

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Center(
            child: SafeArea(
              child: _GlassBox(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      mode = (mode + 1) % 4;
                    });
                  },
                  child: SafeArea(
                    child: SizedBox(
                      height: 50,
                      width: 200,
                      child: Center(
                        child: Text(
                          switch ((mode+1)%4) {
                            0 => 'Daily calls',
                            1 => 'Weekly calls',
                            2 => 'Monthly calls',
                            _ => 'Total calls',
                          },
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: activeList.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),
              child: ListView.separated(
                itemCount: activeList.length,
                separatorBuilder: (c, i) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final groom = activeList[index];

                  // Match the Groom
                  final String rawName = groom['name']?.toString() ?? groom['groomid']?.toString() ?? groom['groom']?.toString() ?? "Unknown";
                  final String searchName = rawName.toLowerCase().trim();
                  final int calls = groom['deliveries'] ?? groom['count'] ?? 0;

                  final avgData = activeAvgList.firstWhere(
                          (a) {
                        final aGroom = a['groom']?.toString().toLowerCase().trim();
                        final aName = a['name']?.toString().toLowerCase().trim();
                        final aGroomId = a['groomid']?.toString().toLowerCase().trim();
                        return searchName == aGroom || searchName == aName || searchName == aGroomId;
                      },
                      orElse: () => null
                  );

                  // Extract time string
                  String callTimeString = "N/A";
                  if (avgData != null && avgData['time'] != null) {
                    callTimeString = avgData['time'].toString().trim();
                  }

                  return _GlassBox(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Text(rawName.isNotEmpty && rawName != "Unknown" ? rawName[0].toUpperCase() : "?",
                                style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rawName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                const SizedBox(height: 10),
                                SafeArea(child: Row(
                                  children: [
                                    const Text("Avg Time",
                                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Text(callTimeString, // Injected the real time here
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ],
                                ))
                              ],
                            ),
                          ),
                          const SizedBox(width: 16), // Added a small gap before the calls column
                          SizedBox(
                            width: 90,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  switch (mode) {
                                    0 => 'Daily calls',
                                    1 => 'Weekly calls',
                                    2 => 'Monthly calls',
                                    _ => 'Total calls',
                                  },
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                                Text("$calls",
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
// =======================
// CHART COMPONENT
// =======================

class _GroomPerformanceChart extends StatefulWidget {


  const _GroomPerformanceChart();

  @override
  State<_GroomPerformanceChart> createState() =>
      _GroomPerformanceChartState();
}

class _GroomPerformanceChartState extends State<_GroomPerformanceChart> {

  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: // 1. Wrap your LineChart in a SingleChildScrollView
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // 2. Give it a Container or SizedBox with a large width
        child: Container(
          width: 900, // <--- Adjust this! The larger the number, the more spread out the points will be.
          padding: const EdgeInsets.only(right: 24, top: 16, bottom: 16), // Padding to ensure the last point isn't cut off
          child: LineChart(
            LineChartData(
              // minX: 0, // Optional: strictly enforce your start/end points if things get weird
              // maxX: 24,
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  axisNameSize: 20,
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 10,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Text("Time of Day", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                  ),
                  axisNameSize: 30,
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final hour = value.toInt();
                      if (hour > 24) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "${hour.toString().padLeft(0, '0')}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              lineBarsData: [
                LineChartBarData(
                  spots: averageHoursList,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: const [],
                  isCurved: true,
                  color: Colors.orange,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}

// =======================
// GLASS BOX HELPER
// =======================

class _GlassBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color xromataki;

  const _GlassBox({required this.child, this.width, this.height, this.onTap,this.xromataki=Colors.white});

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
              color: xromataki.withOpacity(0.1),
              border: Border.all(color: xromataki.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(25),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GroomStatistics {
  List<dynamic> dailyGroomDeliveries = [];
  dynamic averageTodayRequestsPerGroom;
  dynamic sevenDaysAverage;
  dynamic thirtyDaysAverage;

  List<dynamic> sevenDaysGroomDeliveries = [];
  List<dynamic> thirtyDaysGroomDeliveries = [];
  List<dynamic> allTimeGroomDeliveries = [];

  List<dynamic> averageExecutionTimeToday = [];
  List<dynamic> averageExecutionTimeWeekly = []; // Maps to 7_days
  List<dynamic> averageExecutionTimeMonthly = []; // Maps to 30_days
  List<dynamic> averageExecutionTimeAllTime = [];

  List<dynamic> averageTimeTaskToday = [];
  List<dynamic> averageTimeTaskWeekly = []; // Maps to 7_days
  List<dynamic> averageTimeTaskMonthly = []; // Maps to 30_days
  List<dynamic> averageTimeTaskAllTime = [];
}
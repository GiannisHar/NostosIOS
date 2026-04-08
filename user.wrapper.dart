import 'package:flutter/material.dart';
import 'package:nostos/MyProfile.dart';
import 'package:nostos/user_bottom_bar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:nostos/MyRequests.dart';
import 'package:nostos/AttentionRooms.dart';
import 'package:nostos/user_id.dart' as globals;

import 'package:nostos/Requester_Renewed.dart';

class UserWrapper extends StatefulWidget {
  final IO.Socket? socket;
  final int startIndex;

  const UserWrapper({
    super.key,
    required this.socket,
    this.startIndex = 0,
  });

  @override
  State<UserWrapper> createState() => _UserWrapperState();
}

class _UserWrapperState extends State<UserWrapper> with WidgetsBindingObserver {
  late int pageIndex;

  @override
  void initState() {
    super.initState();
    pageIndex = widget.startIndex;

    WidgetsBinding.instance.addObserver(this);
    globals.job = "user";

  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch(state) {
      case AppLifecycleState.resumed:
        print("App resumed (foreground)");
        //widget.socket?.emit('app_resumed', {'user_id': globals.userid});
        break;
      case AppLifecycleState.paused:
        globals.isloggedin = false;
        //widget.socket?.emit('app_paused', {'user_id': globals.userid,"job":globals.job});
        print("App paused (background / sleep)");
        break;
      case AppLifecycleState.detached:
      //widget.socket?.emit('app_closed', {'user_id': globals.userid,"job":globals.job});
      //print("App detached (closing)");

        break;
      case AppLifecycleState.inactive:
      // temporary inactive state (e.g., phone call)
        break;
      case AppLifecycleState.hidden:
        globals.isloggedin = false;
        print("App hidden (platform-specific)");
        //widget.socket?.emit('app_paused', {'user_id': globals.userid}); // treat as paused
        break;
    }
  }






  void goToPage(int index) {
    if (index == pageIndex) return;

    setState(() {
      pageIndex = index;
    });
  }

  /// 🔥 NEW widget instance every time → initState runs
  Widget _buildPage() {
    switch (pageIndex) {
      case 0:
        return Requester_Renewed(
          key: UniqueKey(),
          socket: widget.socket,
        );

      case 1:
        return MyRequests(
          key: UniqueKey(),
          socket: widget.socket,
        );

      case 2:
        return AttentionRooms(
          key: UniqueKey(),
          socket: widget.socket,
        );
      case 3:
        return MyProfile(
          key: UniqueKey(),
          socket: widget.socket,
        );

      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _buildPage(),
        extendBody: true,
        bottomNavigationBar:SafeArea(child: Padding(padding: EdgeInsets.only(
          top: 10,
          bottom: 8,
          right: 10,
          left: 10,
        ),child:  UserBottomBar(
          currentIndex: pageIndex,
          onTap: goToPage,
        ),))
    );
  }
}
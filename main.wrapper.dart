import 'package:flutter/material.dart';
import 'package:nostos/ChatPage.dart';
import 'package:nostos/CompletedTasksPage.dart';
import 'package:nostos/MyProfile.dart';
import 'package:nostos/main.dart';
import 'package:nostos/my_bottom_bar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:nostos/Requests_List_Renewed.dart';
import 'package:nostos/Accepted_List.dart';
import 'package:nostos/Break.dart';
import 'package:nostos/user_id.dart' as globals;

import 'package:battery_plus/battery_plus.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:nostos/Board.dart';

class MainWrapper extends StatefulWidget {
  final IO.Socket? socket;
  final int startIndex;
  final bool includeBreak;
  const MainWrapper({
    super.key,
    required this.socket,
    this.startIndex = 0,
    this.includeBreak = true,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper>
    with WidgetsBindingObserver {
  late int pageIndex;
  Timer? timer;
  var battery = Battery();
  BatteryState? currentState;

  // ✅ Pre-built pages — created ONCE in initState, never recreated on rebuild
  late final Widget _page0;
  late final Widget _page1;
  late final Widget _page2;
  late final Widget _page3;

  Future<void> Listen() async {
    try {
      final bool enabled = await WakelockPlus.enabled;
      battery.onBatteryStateChanged.listen((BatteryState state) {
        currentState = state;
      });

      int level = await battery.batteryLevel;
      String charging = currentState?.toString() ?? "unknown";
      widget.socket?.emit("battery", {
        "token": globals.token,
        "user_id": globals.userid,
        "battery": level,
        "charging": charging,
        "wakeclock": enabled,
      });
    } catch (e) {
      debugPrint("Battery error: $e");
    }
  }

  Future<void> battery_count() async {
    timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await Listen();
    });
  }

  void stopBatteryLoop() {
    timer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    pageIndex = widget.startIndex;

    // ✅ Build pages once here — stable references, no UniqueKey()
    _page0 = Requests_List_Renewed(
      key: const ValueKey('requests_list_page'),
      socket: widget.socket,
    );

    if (widget.includeBreak) {
      _page1 = Break(
        key: const ValueKey('break_page'),
        socket: widget.socket,
      );
      _page2 = ChatPage(
        key: const ValueKey('chat_page'),
        socket: widget.socket,
      );
    } else {
      _page1 = ChatPage(
        key: const ValueKey('chat_page'),
        socket: widget.socket,
      );
      _page2 = MyProfile(
        key: const ValueKey('profile_page'),
        socket: widget.socket,
      );
    }
    _page3 = MyProfile(
      key: const ValueKey('profile_page_3'),
      socket: widget.socket,
    );

    WidgetsBinding.instance.addObserver(this);

    widget.socket?.off("override");
    widget.socket?.on("override", _onOverride);

    widget.socket?.on("Low_Battery", (data) {
      if (data["act"] == true) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    });

    battery_count();

    globals.job = "groom";
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

        globals.acceptedRequests
            .removeWhere((req) => req["RID"] == overRID);
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    stopBatteryLoop();
    WidgetsBinding.instance.removeObserver(this);
    widget.socket?.off("override", _onOverride);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print("App resumed (foreground)");
        break;
      case AppLifecycleState.paused:
        globals.isloggedin = false;
        widget.socket?.emit('app_paused', {
          'user_id': globals.userid,
          "job": globals.job,
          "token": globals.token,
        });
        print("App paused (background / sleep)");
        break;
      case AppLifecycleState.detached:
        widget.socket?.emit('app_closed', {
          'user_id': globals.userid,
          "job": globals.job,
          "token": globals.token,
        });
        print("App detached (closing)");
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        globals.isloggedin = false;
        print("App hidden (platform-specific)");
        widget.socket?.emit('app_paused', {
          'user_id': globals.userid,
          "token": globals.token,
        });
        break;
    }
  }

  void goToPage(int index) {
    if (index == pageIndex) return;
    setState(() {
      pageIndex = index;
    });
  }

  // ✅ Returns pre-built stable page — no UniqueKey(), no recreation on rebuild
  Widget _buildPage() {
    switch (pageIndex) {
      case 0:
        return _page0;
      case 1:
        return _page1;
      case 2:
        return _page2;
      case 3:
        return _page3;
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 8,
          right: 10,
          left: 10,
        ),
        child: MyBottomBar(
          includeBreak: widget.includeBreak,
          currentIndex: pageIndex,
          onTap: goToPage,
        ),
      ),
    );
  }
}
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nostos/user_id.dart' as globals;
bool showsnackbar = false;

class MyBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool includeBreak;
  const MyBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.includeBreak = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: _GlassBox(child: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      backgroundColor: Colors.transparent,
      selectedItemColor: Colors.black,
      elevation: 0,
      //onTap: onTap,
      onTap: (index) {
        if (globals.is_breaking == false) {
          onTap(index);
        }
        else{
          if(showsnackbar == false){
            showsnackbar = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text("You are on a Break"),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                ).closed.then((_) => showsnackbar = false); // reset after dismiss
            });
          }
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.inbox_outlined),
          activeIcon: Icon(Icons.inbox),
          label: "Requests",
        ),
        if(includeBreak)
         BottomNavigationBarItem(
          icon: Icon(Icons.free_breakfast_outlined),
          activeIcon: Icon(Icons.free_breakfast),
          label: "Break",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_outlined),
          activeIcon: Icon(Icons.chat),
          label: "Chat",
        ),
        if(includeBreak)
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person,),
          label: "Profile",
        ),
      ],
    )));
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
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.5),width: 1.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
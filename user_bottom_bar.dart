import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nostos/user_id.dart' as globals;
bool showsnackbar = false;

class UserBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;


  const UserBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(10),child: _GlassBox(child: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      elevation: 0,
      selectedItemColor: Colors.black,
      backgroundColor: Colors.transparent,
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
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.arrow_circle_right_outlined),
          activeIcon: Icon(Icons.arrow_circle_right_rounded),
          label: "Request",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined),
          activeIcon: Icon(Icons.account_circle_sharp),
          label: "My Requests",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: "Attention Rooms",
        ),
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
              color: Colors.white.withOpacity(0.1),
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
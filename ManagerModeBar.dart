import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nostos/user_id.dart' as globals;
bool showsnackbar = false;

class ManagerModeBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;


  const ManagerModeBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(10),child: _GlassBox(child: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      //onTap: onTap,
      elevation: 0,
      selectedItemColor: Colors.black,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      backgroundColor: Colors.transparent,
      onTap: (index) {
        onTap(index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.support_agent_outlined,),
          activeIcon: Icon(Icons.support_agent,fontWeight: FontWeight.bold),
          label: "Users",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car_outlined),
          activeIcon: Icon(Icons.directions_car,fontWeight: FontWeight.bold),
          label: "Grooms",
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
              color: Colors.white.withOpacity(0.3),
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
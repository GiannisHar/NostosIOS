import 'package:flutter/material.dart';

class BgLoader extends StatefulWidget {
  const BgLoader({super.key});

  @override
  State<BgLoader> createState() => _bgLoader();
}

class _bgLoader extends State<BgLoader> {
  /*
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage("assets/ikos_chill.webp"), context);
    precacheImage(const AssetImage("assets/spa.webp"), context);
    precacheImage(const AssetImage("assets/ikos_elia_xriso.webp"), context);
    precacheImage(const AssetImage("assets/ikos_pool.webp"), context);
    precacheImage(const AssetImage("assets/main_background.webp"), context);
  }
  
   */

  @override
  Widget build(BuildContext context) {
    precacheImage(const AssetImage("assets/ikos_chill.webp"), context);
    precacheImage(const AssetImage("assets/spa.webp"), context);
    precacheImage(const AssetImage("assets/ikos_elia_xriso.webp"), context);
    precacheImage(const AssetImage("assets/ikos_pool.webp"), context);
    precacheImage(const AssetImage("assets/main_background.webp"), context);

    return Opacity(opacity: 0.01, child: Stack(
            children: [
              Image.asset("assets/ikos_chill.webp"),
              Image.asset("assets/spa.webp"),
              Image.asset("assets/ikos_elia_xriso.webp"),
              Image.asset("assets/ikos_pool.webp"),
              Image.asset("assets/main_background.webp"),
            ],
          ),
      );
  }
}
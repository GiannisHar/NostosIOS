import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nostos/user_id.dart' as globals;
import 'package:http/http.dart' as http;
import 'package:nostos/Login.dart';

late IO.Socket? socket;
String url = globals.url;

Future<void> remember_me(String user_id,bool exists) async{
  //await GetStorage.init();
  //final storage = GetStorage();
  final secureStorage = FlutterSecureStorage();
  //await secureStorage.delete(key: 'userId');
  if(exists == true){
    //String? savedUserId = storage.read('userId');
    String? savedUserId = await secureStorage.read(key: 'userId');
    print(savedUserId);
    //if (savedUserId != null)
    if (savedUserId != null && savedUserId.isNotEmpty){
      globals.userid = savedUserId;
      socket?.emit("login", {
        "id": globals.userid,
        "mode":globals.State,
        "reconnect":false
      });
    }
  }else{
    //storage.write('userId', user_id);
    await secureStorage.write(key: 'userId', value: user_id);
  }
}

Future<void> initSocket() async{
  socket = IO.io(url, {
    'transports': ['websocket'],
    //'transports': ['polling', 'websocket'],
    'force new connection': true,
    'reconnection': true, // ✅ enable reconnection
    'reconnectionAttempts': 1000, // optional: max retries
    'reconnectionDelay': 1000, // optional: delay in ms between retries
  });

  socket?.onConnect((_) => print('✅ Connected'));
  socket?.onDisconnect((_) => print('❌ Disconnected'));
  socket?.connect();
}

void main() async
{
  WidgetsFlutterBinding.ensureInitialized(); // malakies tou chat gpt
  // url = await fetchServerIp();
  //initSocket();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //showPerformanceOverlay: true,
      home: Login(),
      debugShowCheckedModeBanner: false,
    );
  }
}

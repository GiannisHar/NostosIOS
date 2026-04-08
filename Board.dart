import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nostos/user_id.dart' as globals;

class Board{
  String location;
  String userId;
  int room_number;
  String task;
  String dropdown;
  int counter;
  int time;
  bool accepted;
  int RID;

  Board({
    required this.userId,
    required this.location,
    required this.room_number,
    required this.task,
    required this.dropdown,
    this.counter = 0,
    this.time = 0,
    this.accepted = false,
    this.RID = 0,
  });
}
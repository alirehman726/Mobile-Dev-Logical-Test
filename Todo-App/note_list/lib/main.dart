import 'dart:isolate';
import 'dart:ui';
 
import 'package:flutter/material.dart';
import 'package:note_list/screen/note_list.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

const String countKey = 'count';
const String isolateName = 'isolate';
final ReceivePort port = ReceivePort();
SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  IsolateNameServer.registerPortWithName(
    port.sendPort,
    isolateName,
  );
  prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(countKey)) {
    await prefs.setInt(countKey, 0);
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NoteList(),
    );
  }
}

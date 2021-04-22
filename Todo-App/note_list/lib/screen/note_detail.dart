import 'dart:isolate';
import 'dart:math';
import 'dart:ui';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:note_list/model/note.dart';
import 'package:note_list/util/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class NoteDetail extends StatefulWidget {
  final String appBarTitle;
  final Note note;

  NoteDetail(this.note, this.appBarTitle);

  @override
  State<StatefulWidget> createState() {
    return NoteDetailState(this.note, this.appBarTitle);
  }
}

class NoteDetailState extends State<NoteDetail> {
  //  Local Notification
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  //  Default Variables
  String title = 'Time Picker';
  TimeOfDay _time;
  DateTime result;
  static var _priorities = ['High', 'Middle', 'Low'];
  String appBarTitle;
  Note note;

  // State Default Constructor
  // @param note This is the Note Model Object
  // @param appBarTitle This is used to set actionbar Title
  NoteDetailState(this.note, this.appBarTitle);

  //  EditText Controllers

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController timeController;

  @override
  void initState() {
    super.initState();

    //  Function used to get the current time. It's [Time.now] by default.
    _time = TimeOfDay.now();
    print("Current Time Of --------------->$_time ");

    // Set default hour & minute in timeController
    String currTime = _time.hour.toString() + ":" + _time.minute.toString();
    timeController = new TextEditingController(text: currTime);
    print("Initial Time controller value is  ${timeController.text}");

    // Initialization of Alarm Manager
    AndroidAlarmManager.initialize();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('flutter_devs');
    var initializationSettingsIOs = IOSInitializationSettings();
    // ignore: unused_local_variable
    var initSetttings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOs);
  }

  // Added to Check Alarm add or update in background mode
  static SendPort uiSendPort;

  // A Callback function to check alarm is added or updated
  static Future<void> onAndroidAlarmManagerCallback() async {
    print('Alarm fired!');

    // Get the previous cached count and increment it.
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(countKey);
    await prefs.setInt(countKey, currentCount + 1);

    // This will be null if we're running in the background.
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);
  }

  //  Database_Helper
  DatabaseHelper helper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    TextStyle textStyle = Theme.of(context).textTheme.title;

    titleController.text = note.title;
    descriptionController.text = note.description;

    return WillPopScope(
      // ignore: missing_return
      onWillPop: () {
        moveToLastScreen();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                moveToLastScreen();
              }),
        ),
        body: Padding(
          padding: EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
          child: ListView(
            children: <Widget>[
              ListTile(
                //  selected DropDown
                title: DropdownButton(
                    items: _priorities.map((String dropDownStringItem) {
                      return DropdownMenuItem<String>(
                        value: dropDownStringItem,
                        child: Text(dropDownStringItem),
                      );
                    }).toList(),
                    style: textStyle,
                    value: getPriorityAsString(note.priority),
                    onChanged: (valueSelectedByUser) {
                      setState(() {
                        debugPrint('User selected $valueSelectedByUser');
                        updatePriorityAsInt(valueSelectedByUser);
                      });
                    }),
              ),
              SizedBox(height: 30.0),

              //  TextField Title
              Padding(
                padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                child: TextField(
                  controller: titleController,
                  style: textStyle,
                  onChanged: (value) {
                    debugPrint('Something changed in Title Text Field');
                    updateTitle();
                  },
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: textStyle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
              ),

              //  TextField Description
              Padding(
                padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                child: TextField(
                  controller: descriptionController,
                  style: textStyle,
                  onChanged: (value) {
                    debugPrint('Something changed in Description Text Field');
                    updateDescription();
                  },
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: textStyle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
              ),

              //  TextField Time
              Padding(
                padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                child: Container(
                  child: TextField(
                    controller: timeController,
                    style: textStyle,
                    onChanged: (value) {
                      debugPrint('Something changed in Time Text Field');
                      updateTime();
                    },
                    decoration: InputDecoration(
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onTap: _timePicker(),
                  ),
                ),
              ),

              //  SAVE Button
              Padding(
                padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        color: Theme.of(context).primaryColorDark,
                        textColor: Theme.of(context).primaryColorLight,
                        child: Text(
                          'Save',
                          textScaleFactor: 1.5,
                        ),
                        onPressed: () async {
                          setState(
                            () {
                              debugPrint("Save button clicked");

                              final now = new DateTime.now();
                              var d = new DateTime(now.year, now.month, now.day,
                                  _time.hour, _time.minute);
                              _save(d);

                              int timeStamp = d.millisecondsSinceEpoch;

                              int currentTimestamp = now.millisecondsSinceEpoch;

                              int diff = timeStamp - currentTimestamp;

                              if (diff > 0) {
                                print('Correct Time');
                              } else {
                                print('Incorrect of Time');
                                _showAlterDialog(
                                    'Alert', 'Please Correct Time Enter...!!');
                              }

                              //  Alarm Manager

                              AndroidAlarmManager.oneShot(
                                Duration(milliseconds: diff),
                                // alarmID,
                                Random().nextInt(pow(2, 31)),
                                onAndroidAlarmManagerCallback,
                                alarmClock: true,
                                exact: true,
                                wakeup: true,
                              ).then((val) => print(val)).catchError((e) {
                                print(e);
                              });
                              //  Notification for the selected time
                              scheduleNotification(diff);
                              print(
                                  'ANDROID___ALARM___MANAGER----------------------->>>>>>$diff');
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 5.0,
                    ),

                    //  Delete Button//
                    Expanded(
                      child: RaisedButton(
                        color: Theme.of(context).primaryColorDark,
                        textColor: Theme.of(context).primaryColorLight,
                        child: Text(
                          'Delete',
                          textScaleFactor: 1.5,
                        ),
                        onPressed: () {
                          setState(() {
                            debugPrint("Delete button clicked");
                            _delete();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  Page Route for next page

  void moveToLastScreen() {
    Navigator.pop(context, true);
  }

  //  Update Priority
  void updatePriorityAsInt(String value) {
    switch (value) {
      case 'High':
        note.priority = 1;
        break;

      case 'Middle':
        note.priority = 2;
        break;

      case 'Low':
        note.priority = 3;
        break;
    }
  }

  //  Priority convert int to String
  String getPriorityAsString(int value) {
    String priority;
    switch (value) {
      case 1:
        priority = _priorities[0];
        break;
      case 2:
        priority = _priorities[1];
        break;
      case 3:
        priority = _priorities[2];
        break;
    }
    return priority;
  }

  //  Update Title
  void updateTitle() {
    note.title = titleController.text;
  }

  //  Update Description
  void updateDescription() {
    note.description = descriptionController.text;
  }

  //  Update Time
  void updateTime() async {
    note.time = timeController.text;
    print('Updated Time--->${timeController.text}');
  }

  //  Save to Data
  void _save(d) async {
    //  Move to Next Screen
    moveToLastScreen();

    //  Update Time
    note.time = _time.hour.toString() + ":" + _time.minute.toString();

    //  Update Date
    note.date = DateFormat.yMMMd().format(DateTime.now());
    int result;

    if (note.id != null) {
      //  update node
      result = await helper.updateNote(note);
    } else {
      //  Insert node
      result = await helper.insertNote(note);
    }

    //  Dialog box (update note / insert node)
    if (result != 0) {
      _showAlterDialog('Status', 'Note Saved Successfully');
    } else {
      _showAlterDialog('Status', 'Problem Saving Note');
    }
  }

  // Delete Node
  void _delete() async {
    moveToLastScreen();
    if (note.id == null) {
      //  Delete Node
      _showAlterDialog('Status', 'No Note was deleted');
      return;
    }

    int result = await helper.deleteNote(note.id);
    //  Dialog box for the Delete
    if (result != 0) {
      _showAlterDialog('Status', 'Note Deleted Successfully');
    } else {
      _showAlterDialog('Status', 'Error Occured while Deleting Note');
    }
  }

  //  Show POP-Dialog
  void _showAlterDialog(String title, String message) {
    AlertDialog alertDialog = AlertDialog(
      title: Text(title),
      content: Text(message),
    );
    showDialog(context: context, builder: (_) => alertDialog);
  }

  //  TimePicker
  _timePicker() async {
    TimeOfDay time = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (BuildContext context, Widget child) {
        return Theme(
          data: ThemeData(),
          child: MediaQuery(
            child: child,
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          ),
        );
      },
    );
    if (time != null) {
      setState(
        () {
          _time = time;

          String currSelectedTime =
              _time.hour.toString() + ":" + _time.minute.toString();
          timeController.text = currSelectedTime;

          final now = new DateTime.now();
          // Current Date Time
          var d = new DateTime(
              now.year, now.month, now.day, _time.hour, _time.minute);

          // Inserted Time convert to Milisecond
          int timeStamp = d.millisecondsSinceEpoch;
          // Current Time Convert to Milisecond
          int currentTimestamp = now.millisecondsSinceEpoch;
          // Diffent to Current_time and Inserted_Time
          int diff = timeStamp - currentTimestamp;
          if (diff > 0) {
            print('Correct Time');
          } else {
            print('Incorrect of Time');
            _showAlterDialog('Alert', 'Please Correct Time Enter...!!');
          }
          //  Alarm Manager
          AndroidAlarmManager.oneShot(
            Duration(milliseconds: diff),
            Random().nextInt(pow(2, 31)),
            onAndroidAlarmManagerCallback,
            exact: true,
            alarmClock: true,
            wakeup: true,
          ).then((value) => print(value)).catchError((error) {
            print(error);
          });
        },
      );
    }
  }

  //  Notification
  Future<void> scheduleNotification(diff) async {
    print(
        '//notification_________________________________Correct___________________>>$diff');
    var scheduledNotificationDateTime =
        DateTime.now().add(Duration(milliseconds: diff));
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel id',
      'channel name',
      'channel description',
      icon: 'flutter_devs',
      largeIcon: DrawableResourceAndroidBitmap('flutter_devs'),
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(
        0,
        titleController.text,
        descriptionController.text,
        scheduledNotificationDateTime,
        platformChannelSpecifics,
        payload: "Schedule notifications");
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:note_list/model/note.dart';
import 'package:note_list/util/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'note_detail.dart';

// ignore: must_be_immutable
class NoteList extends StatefulWidget {
  @override
  _NoteListState createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  // Default Variables
  List<Note> noteList;
  int count = 0;

  //Database
  DatabaseHelper databaseHelper = DatabaseHelper();
  @override
  Widget build(BuildContext context) {
    // Show Node List
    if (noteList == null) {
      noteList = List<Note>();
      updateListView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: getNoteListView(),

      //Node Add Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('FAB clicked');
          navigateToDetail(Note('', '', 3, ''), 'Add Note');
        },
        tooltip: 'Add Note',
        child: Icon(Icons.add),
      ),
    );
  }

  ListView getNoteListView() {
    // ignore: deprecated_member_use
    TextStyle titleStyle = Theme.of(context).textTheme.subhead;

    return ListView.builder(
      itemCount: count,
      itemBuilder: (BuildContext context, int position) {
        return Slidable(
          key: ValueKey(position),
          actionPane: SlidableDrawerActionPane(),
          secondaryActions: <Widget>[
            //Slider left to right
            IconSlideAction(
              caption: 'Update',
              color: Colors.blue,
              icon: Icons.edit,
              closeOnTap: true,
              onTap: () {
                debugPrint('ListTitle Tapped');
                navigateToDetail(this.noteList[position], 'Edit Note');
              },
            ),
            //Slider left to right
            IconSlideAction(
              caption: 'Delete',
              color: Colors.red,
              icon: Icons.delete,
              closeOnTap: true,
              onTap: () {
                _delete(context, noteList[position]);
              },
            )
          ],
          child: Card(
            color: Colors.white,
            elevation: 2.0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    getPriorityColor(this.noteList[position].priority),
                child: getPriorityIcon(this.noteList[position].priority),
              ),

              title: Text(
                this.noteList[position].title,
                style: titleStyle,
              ),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(this.noteList[position].date),
                ],
              ),
              trailing: GestureDetector(
                child: Text(this.noteList[position].time),

                // List Delete
                onTap: () {
                  _delete(context, noteList[position]);
                },
              ),
              //
              // Upadte List
              onTap: () {
                debugPrint('ListTitle Tapped');
                navigateToDetail(this.noteList[position], 'Edit Note');
              },
            ),
          ),
        );
      },
    );
  }

  // Priority Color
  Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
        break;
      case 2:
        return Colors.green;
        break;

      case 3:
        return Colors.yellow;
        break;

      default:
        return Colors.yellow;
    }
  }

// Priority Icon
  Icon getPriorityIcon(int priority) {
    switch (priority) {
      case 1:
        return Icon(Icons.play_arrow);
        break;
      case 2:
        return Icon(Icons.dehaze);
        break;
      case 3:
        return Icon(Icons.keyboard_arrow_right);
        break;

      default:
        return Icon(Icons.keyboard_arrow_right);
    }
  }

  // Delete ListView
  void _delete(BuildContext context, Note note) async {
    int result = await databaseHelper.deleteNote(note.id);
    if (result != 0) {
      _showSnackBar(context, 'Note Delete Successfully');
      updateListView();
    }
  }

  // Update ListView
  void updateListView() {
    final Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      Future<List<Note>> noteListFuture = databaseHelper.getNoteList();
      noteListFuture.then((noteList) {
        setState(() {
          this.noteList = noteList;

          this.count = noteList.length;
        });
      });
    });
  }

  // SnackBar
  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    Scaffold.of(context).showSnackBar(snackBar);
  }

  void navigateToDetail(Note note, String title) async {
    bool result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return NoteDetail(
            note,
            title,
          );
        },
      ),
    );

    if (result == true) {
      updateListView();
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'wine_list.dart';
import 'fridge.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'God\'s Wine Cellar',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return StreamBuilder<FirebaseUser>(
      stream: _auth.onAuthStateChanged,
      builder: (context, firebaseUser) {
        if (!firebaseUser.hasData)
          return Scaffold(
            appBar: AppBar(
              title: Text('God\'s Wine Cellar'),
              actions: <Widget>[LoginWithGoogleButton(firebaseUser.data)],
            ),
            body: Text('Please Login to view your wine'),
          );
        return MainBody(firebaseUser);
      },
    );
  }
}

class MainBody extends StatefulWidget {
  final AsyncSnapshot<FirebaseUser> _user;

  MainBody(this._user);

  @override
  _MainBodyState createState() => _MainBodyState();
}

class _MainBodyState extends State<MainBody> {
  int _selectedIndex = 0;

  void _onNavBarItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('God\'s Wine Cellar'),
        actions: <Widget>[LoginWithGoogleButton(widget._user.data)],
      ),
      body: <Widget>[
        BottleBody(widget._user),
        FridgeBody(widget._user),
      ][_selectedIndex],
      floatingActionButton: AddBottleButton(widget._user.data.uid),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              title: Text("Wine List"),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit),
              title: Text("Fridge List"),
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onNavBarItemTapped,
        ),
      ),
    );
  }
}

class BottleBody extends StatefulWidget {
  final AsyncSnapshot<FirebaseUser> _user;

  BottleBody(this._user);

  @override
  _BottleBodyState createState() => _BottleBodyState();
}

class _BottleBodyState extends State<BottleBody> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection("users")
          .document(widget._user.data.uid)
          .collection("wines")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        return BottleList(snapshot.data.documents, widget._user.data.uid);
      },
    );
  }
}

class FridgeBody extends StatefulWidget {
  final AsyncSnapshot<FirebaseUser> _user;

  FridgeBody(this._user);

  @override
  _FridgeBodyState createState() => _FridgeBodyState();
}

class _FridgeBodyState extends State<FridgeBody> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection("users")
          .document(widget._user.data.uid)
          .collection("fridges")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        return FridgeList(snapshot.data.documents, widget._user.data.uid);
      },
    );
  }
}

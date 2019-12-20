import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gods_wine_locator/bottle.dart';
import 'auth.dart';
import 'bottle.dart';

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
        primarySwatch: Colors.red,
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
  int _selectedIndex = 0;

  void _onNavBarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    List<BottomNavigationBarItem> bottomNavBarItems;
    BottomNavigationBarItem wineListNavItem = BottomNavigationBarItem(
        icon: Icon(Icons.list), title: Text("Wine List"));
    BottomNavigationBarItem fridgeNavItem = BottomNavigationBarItem(
        icon: Icon(Icons.ac_unit), title: Text("Fridge List"));
    bottomNavBarItems = [wineListNavItem, fridgeNavItem];

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
        return Scaffold(
          appBar: AppBar(
            title: Text('God\'s Wine Cellar'),
            actions: <Widget>[LoginWithGoogleButton(firebaseUser.data)],
          ),
          body: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance
                  .collection("users")
                  .document(firebaseUser.data.uid)
                  .collection("wines")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return LinearProgressIndicator();
                return BottleList(
                    snapshot.data.documents, firebaseUser.data.uid);
              },
            ),
            Center(
              child: Text(
                'Index 1: Fridges',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
          ][_selectedIndex],
          floatingActionButton: AddBottleButton(firebaseUser.data.uid),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            child: BottomNavigationBar(
                items: bottomNavBarItems,
                currentIndex: _selectedIndex,
                onTap: _onNavBarItemTapped),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'common/auth.dart';
import 'wine/list.dart';
import 'fridge/view.dart';

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
  // _selectedIndex keeps track of which of the views we are in: Wine List, or Fridge List
  // The position of each element in the list of widgets below defines the index that selects that view.
  // We just need to ensure that the index of the list view and navigation bar items are in the same position in their respective lists.
  int _selectedIndex = 0;

  // _onNavBarItemTapped sets the index to the view that was tapped
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
        // Only the selected view is displayed
        WineListView(widget._user.data.uid),
        FridgeView(widget._user.data.uid),
      ][_selectedIndex],
      // This is the button for adding a new bottle of wine
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AddBottleDialog(widget._user.data.uid);
              });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // The bottom bar of the main app allows selecting the Wine List or Fridge List
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'bottle.dart';

class UnallocatedBottleList extends StatefulWidget {
  final List<DocumentSnapshot> _documents;

  // List of bottle document snapshots
  UnallocatedBottleList(this._documents);

  @override
  _UnallocatedBottleListState createState() => _UnallocatedBottleListState();
}

class _UnallocatedBottleListState extends State<UnallocatedBottleList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.only(top: 20.0),
        // data is a DocumentSnapshot
        itemCount: widget._documents.length,
        //The `itemBuilder` callback will be called only with indices greater than
        //or equal to zero and less than `itemCount`.
        itemBuilder: (context, index) {
          return BottleListItem(
              bottle: Bottle.fromSnapshot(widget._documents[index]));
        });
  }
}

class UnallocatedBottleListPage extends StatefulWidget {
  final String _userID;

  UnallocatedBottleListPage(this._userID);

  @override
  _UnallocatedBottleListPageState createState() =>
      _UnallocatedBottleListPageState();
}

class _UnallocatedBottleListPageState extends State<UnallocatedBottleListPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection("users")
            .document(widget._userID)
            .collection("unallocated")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();
          return SizedBox(
              height: 200.0,
              child: UnallocatedBottleList(snapshot.data.documents));
        });
  }
}

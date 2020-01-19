import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'bottle.dart';

class RowBottleGroupList extends StatefulWidget {
  final List<DocumentSnapshot> _documents;

  // List of bottle document snapshots
  RowBottleGroupList(this._documents);

  @override
  _RowBottleGroupListState createState() => _RowBottleGroupListState();
}

class _RowBottleGroupListState extends State<RowBottleGroupList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.only(top: 20.0),
        // data is a DocumentSnapshot
        itemCount: widget._documents.length,
        //The `itemBuilder` callback will be called only with indices greater than
        //or equal to zero and less than `itemCount`.
        itemBuilder: (context, index) {
          return BottleListItem(bottle: Bottle.fromSnapshot(widget._documents[index]));
        });
  }
}

class RowBottleGroupListPage extends StatefulWidget {
  final String _userID;
  final String _fridgeID;
  final String _fridgeName;
  final String _rowNumber;

  RowBottleGroupListPage(
      this._userID, this._fridgeID, this._fridgeName, this._rowNumber);

  @override
  _RowBottleGroupListPageState createState() => _RowBottleGroupListPageState();
}

class _RowBottleGroupListPageState extends State<RowBottleGroupListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fridge: ${widget._fridgeName}, Row: ${widget._rowNumber}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection("users")
              .document(widget._userID)
              .collection("fridges")
              .document(widget._fridgeID)
              .collection("rows")
              .document(widget._rowNumber)
              .collection("bottlegroups")
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container();
            return RowBottleGroupList(snapshot.data.documents);
          }),
    );
  }
}

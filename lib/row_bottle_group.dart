import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'fridge.dart';
import 'fridge_row.dart';
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
          return BottleListItem(
              bottle: Bottle.fromSnapshot(widget._documents[index]));
        });
  }
}

class RowBottleGroupListView extends StatefulWidget {
  final String _userID;
  final Fridge _fridge;
  final FridgeRow _row;

  // TODO implement back button
  final Function _back;

  RowBottleGroupListView(this._userID, this._fridge, this._row, this._back);

  @override
  _RowBottleGroupListViewState createState() => _RowBottleGroupListViewState();
}

class _RowBottleGroupListViewState extends State<RowBottleGroupListView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection("users")
          .document(widget._userID)
          .collection("fridges")
          .document(widget._fridge.uid)
          .collection("rows")
          .document(widget._row.number.toString())
          .collection("bottlegroups")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        return RowBottleGroupList(snapshot.data.documents);
      },
    );
  }
}

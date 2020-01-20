import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'fridge.dart';
import 'fridge_row.dart';
import 'bottle.dart';

class RowBottleGroupListView extends StatefulWidget {
  final String _userID;
  final Fridge _fridge;
  final FridgeRow _row;
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
        return Scaffold(
          appBar: AppBar(
            leading: FlatButton(
              child: Icon(Icons.arrow_back),
              onPressed: widget._back,
            ),
            title: Text('${widget._fridge.name} fridge, row ${widget._row.number}'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.only(top: 20.0),
            // data is a DocumentSnapshot
            itemCount: snapshot.data.documents.length,
            //The `itemBuilder` callback will be called only with indices greater than
            //or equal to zero and less than `itemCount`.
            itemBuilder: (context, index) {
              return BottleListItem(
                  bottle: Bottle.fromSnapshot(snapshot.data.documents[index]));
            },
          ),
        );
      },
    );
  }
}

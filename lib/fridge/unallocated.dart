import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gods_wine_locator/common/bottle.dart';

class UnallocatedBottleListView extends StatefulWidget {
  final String _userID;
  final bool _showAddButton;
  final Function _addBottleToFridgeRow;

  UnallocatedBottleListView(
      this._userID, this._addBottleToFridgeRow, this._showAddButton);

  @override
  _UnallocatedBottleListViewState createState() =>
      _UnallocatedBottleListViewState();
}

class _UnallocatedBottleListViewState extends State<UnallocatedBottleListView> {
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
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 20.0),
              // data is a DocumentSnapshot
              itemCount: snapshot.data.documents.length,
              //The `itemBuilder` callback will be called only with indices greater than
              //or equal to zero and less than `itemCount`.
              itemBuilder: (context, index) {
                final _bottle =
                    Bottle.fromSnapshot(snapshot.data.documents[index]);
                if (_bottle.count <= 0) return Container();
                return BottleListItem(
                  bottle: _bottle,
                  trailing: widget._showAddButton
                      ? RaisedButton(
                          // TODO(lexi) change the add icon to something better.
                          child: Icon(
                            Icons.add,
                            color: Colors.indigoAccent,
                          ),
                          onPressed: () =>
                              widget._addBottleToFridgeRow(_bottle, 1),
                        )
                      : Container(),
                );
              },
            ),
          );
        });
  }
}

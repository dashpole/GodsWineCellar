import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gods_wine_cellar/common/bottle.dart';
import 'fridges.dart';
import 'rows.dart';

class RowBottleListView extends StatefulWidget {
  final String _userID;
  final Fridge _fridge;
  final FridgeRow _row;
  final Function() _navigateBack;
  final Function(Bottle, int) _removeBottleFromFridgeRow;

  RowBottleListView(this._userID, this._fridge, this._row, this._navigateBack,
      this._removeBottleFromFridgeRow);

  @override
  _RowBottleListViewState createState() => _RowBottleListViewState();
}

class _RowBottleListViewState extends State<RowBottleListView> {
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
          .collection("bottles")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        return Scaffold(
          appBar: AppBar(
            leading: FlatButton(
              child: Icon(Icons.arrow_back),
              onPressed: widget._navigateBack,
            ),
            title: Text(
                '${widget._fridge.name} fridge, row ${widget._row.number}'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.only(top: 20.0),
            itemCount: snapshot.data.documents.length,
            //The `itemBuilder` callback will be called only with indices greater than
            //or equal to zero and less than `itemCount`.
            itemBuilder: (context, index) {
              Bottle _bottle =
                  Bottle.fromSnapshot(snapshot.data.documents[index]);
              return BottleListItem(
                bottle: _bottle,
                trailing: RaisedButton(
                  // TODO: Change this to a dropdown to EITHER consume or add to unallocated
                  child: Icon(
                    Icons.remove_circle,
                    color: Colors.indigoAccent,
                  ),
                  onPressed: () async {
                    try {
                      await widget._removeBottleFromFridgeRow(_bottle, 1);
                    } catch (e) {
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString()),
                      ));
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gods_wine_cellar/common/bottle.dart';

// UnallocatedBottleListView displays a list of unallocated wines
class UnallocatedBottleListView extends StatefulWidget {
  final String _userID;

  // _addBottleToFridgeRow makes the required calls to the database to move _count_ bottle(s) from the unallocated list to a row in a fridge
  final Function(Bottle, int) _addBottleToFridgeRow;

  // If true, allow users to move wines out of the unallocated list to a fridge
  final bool _showAddButton;

  UnallocatedBottleListView(
      this._userID, this._addBottleToFridgeRow, this._showAddButton);

  @override
  _UnallocatedBottleListViewState createState() =>
      _UnallocatedBottleListViewState();
}

class _UnallocatedBottleListViewState extends State<UnallocatedBottleListView> {
  @override
  Widget build(BuildContext context) {
    // Update the list of bottles displayed based on the unallocated bottles in the database
    return StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection("users")
            .document(widget._userID)
            .collection("unallocated")
            .orderBy('winery')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();
          // Use SizedBox to restrict the maximum height of the unallocated list on the screen
          return SizedBox(
            height: 200.0,
            // Use a Scaffold so that we can display errors with showSnackBar
            child: Scaffold(
              body: ListView.builder(
                padding: const EdgeInsets.only(top: 20.0),
                itemCount: snapshot.data.documents.length,
                //The `itemBuilder` callback will be called only with indices greater than
                //or equal to zero and less than `itemCount`.
                itemBuilder: (context, index) {
                  final _bottle =
                      Bottle.fromSnapshot(snapshot.data.documents[index]);
                  if (_bottle.count <= 0) return Container();
                  // BottleListItem handles displaying basic wine info. BottleListItem allows for adding additional pieces to that item - such as an Edit button.
                  // The Edit button on the left to allow users to edit/delete wine in this list.
                  return BottleListItem(
                    bottle: _bottle,
                    trailing: widget._showAddButton
                        ? RaisedButton(
                            // TODO(lexi) change the add icon to something better.
                            child: Icon(
                              Icons.add,
                              color: Colors.indigoAccent,
                            ),
                            onPressed: () async {
                              try {
                                await widget._addBottleToFridgeRow(_bottle, 1);
                              } catch (e) {
                                Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text(e.toString()),
                                ));
                              }
                            },
                          )
                        : Container(),
                  );
                },
              ),
            ),
          );
        });
  }
}

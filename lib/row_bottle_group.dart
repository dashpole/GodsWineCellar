import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'bottle.dart';

class RowBottleGroup {
  final Bottle _bottle;
  final int _count;

  RowBottleGroup.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot.data['count'] != null),
        _count = snapshot.data['count'],
        _bottle = Bottle.fromSnapshot(snapshot);

  @override
  String toString() => "Wine<${_bottle.toString()}:$_count>";
}

class RowBottleGroupUpdateService {
  final CollectionReference _collection;

  RowBottleGroupUpdateService(String userID, String fridgeID, String rowNumber)
      : _collection = Firestore.instance
            .collection("users")
            .document(userID)
            .collection("fridges")
            .document(fridgeID)
            .collection("rows")
            .document(rowNumber)
            .collection("bottlegroups");

  Future addRowBottleGroup(Bottle bottle, int count) async {
    Map<String, dynamic> data = bottle.data;
    data['count'] = count;
    return await _collection.document(bottle.uid).setData(data);
  }
}

class RowBottleGroupList extends StatefulWidget {
  final List<DocumentSnapshot> _documents;
  final RowBottleGroupUpdateService _updateService;

  RowBottleGroupList(
      this._documents, String userID, String fridgeID, String rowNumber)
      : _updateService =
            RowBottleGroupUpdateService(userID, fridgeID, rowNumber);

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
          return _buildRowBottleGroupItem(
              context, widget._documents[index], widget._updateService);
        });
  }

  Widget _buildRowBottleGroupItem(BuildContext context, DocumentSnapshot data,
      RowBottleGroupUpdateService rowBottleGroupUpdateService) {
    final _rowBottleGroup = RowBottleGroup.fromSnapshot(data);
    return BottleListItem(bottle: _rowBottleGroup._bottle);
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
            return RowBottleGroupList(snapshot.data.documents, widget._userID,
                widget._fridgeID, widget._rowNumber);
          }),
    );
  }
}

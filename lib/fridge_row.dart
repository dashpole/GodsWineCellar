import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'row_bottle_group.dart';
import 'fridge.dart';

class FridgeRow {
  final int _number;
  final int _capacity;
  final String _uid;

  // Load FridgeRow from a FridgeRow Document ("snapshot")
  // Create object in memory to hold a fridgeRow
  FridgeRow.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot.data['number'] != null),
        assert(snapshot.data['capacity'] != null),
        _number = snapshot.data['number'],
        _capacity = snapshot.data['capacity'],
        _uid = snapshot.documentID;

  @override
  String toString() => "FridgeRow<$_number:$_capacity>";
}

class FridgeRowUpdateService {
  final CollectionReference _collection;

  FridgeRowUpdateService(String userID, String fridgeID)
      : _collection = Firestore.instance
            .collection("users")
            .document(userID)
            .collection("fridges")
            .document(fridgeID)
            .collection("rows");

  Future addFridgeRow(int number, int capacity) async {
    return await _collection
        .document('$number')
        .setData({'number': number, 'capacity': capacity});
  }
}

class FridgeRowList extends StatefulWidget {
  final List<DocumentSnapshot> _documents;
  final FridgeRowUpdateService _updateService;
  final String _userID;
  final Fridge _fridge;

  FridgeRowList(this._documents, this._userID, this._fridge)
      : _updateService = FridgeRowUpdateService(_userID, _fridge.uid);

  @override
  _FridgeRowListState createState() => _FridgeRowListState();
}

class _FridgeRowListState extends State<FridgeRowList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.only(top: 20.0),
        // data is a DocumentSnapshot
        itemCount: widget._documents.length,
        //The `itemBuilder` callback will be called only with indices greater than
        //or equal to zero and less than `itemCount`.
        itemBuilder: (context, index) {
          return _buildFridgeRowItem(context, widget._documents[index],
              widget._fridge, widget._updateService);
        });
  }

  Widget _buildFridgeRowItem(BuildContext context, DocumentSnapshot data,
      Fridge fridge, FridgeRowUpdateService fridgeRowUpdateService) {
    final _fridgeRow = FridgeRow.fromSnapshot(data);

    return Padding(
      key: ValueKey(_fridgeRow._uid),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text("Fridge Row Number: ${_fridgeRow._number}"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RowBottleGroupListPage(
                  widget._userID,
                  fridge.uid,
                  fridge.name,
                  _fridgeRow._number.toString(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FridgeRowListPage extends StatefulWidget {
  final String _userID;
  final Fridge _fridge;

  FridgeRowListPage(this._userID, this._fridge);

  @override
  _FridgeRowListPageState createState() => _FridgeRowListPageState();
}

class _FridgeRowListPageState extends State<FridgeRowListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fridge: ${widget._fridge.name}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection("users")
              .document(widget._userID)
              .collection("fridges")
              .document(widget._fridge.uid)
              .collection("rows")
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container();
            return FridgeRowList(
                snapshot.data.documents, widget._userID, widget._fridge);
          }),
    );
  }
}

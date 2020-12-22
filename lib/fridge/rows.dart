import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gods_wine_cellar/main.dart';
import 'fridges.dart';

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

  FridgeRow.fromComponents(int number, int capacity, String uid)
      : assert(number != null),
        assert(capacity != null),
        assert(uid != null),
        _number = number,
        _capacity = capacity,
        _uid = uid;

  int get number {
    return _number;
  }

  int get capacity {
    return _capacity;
  }

  String get uid {
    return _uid;
  }

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

class FridgeRowListView extends StatefulWidget {
  final String _userID;
  final Fridge _fridge;

  FridgeRowListView(this._userID, this._fridge);

  @override
  _FridgeRowListViewState createState() => _FridgeRowListViewState();
}

class _FridgeRowListViewState extends State<FridgeRowListView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection("users")
          .document(widget._userID)
          .collection("fridges")
          .document(widget._fridge.uid)
          .collection("rows")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        // Convert the List<DocumentSnapshot> to a List<FridgeRows> using map().
        // Map takes in a function that is applied to each list element.
        List<FridgeRow> rows = snapshot.data.documents
            .map((DocumentSnapshot a) => FridgeRow.fromSnapshot(a))
            .toList();
        // Sort the rows by the row number
        rows.sort((FridgeRow a, b) => a.number.compareTo(b.number));
        return Scaffold(
          appBar: AppBar(
            leading: FlatButton(
              child: Icon(Icons.arrow_back),
              onPressed: MainBody.of(context).navigateBackInFridgeView,
            ),
            title: Text('${widget._fridge.name} fridge'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.only(top: 20.0),
            itemCount: rows.length,
            //The `itemBuilder` callback will be called only with indices greater than
            //or equal to zero and less than `itemCount`.
            itemBuilder: (context, index) {
              final _fridgeRow = rows[index];
              return Padding(
                key: ValueKey(_fridgeRow._uid),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: ListTile(
                    title: Text("Fridge Row Number: ${_fridgeRow._number}"),
                    onTap: () => (MainBody.of(context)
                        .navigateToRow(widget._fridge, _fridgeRow)),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gods_wine_cellar/main.dart';
import 'rows.dart';

class Fridge {
  final String _name;
  final String _uid;

  // Load Fridge from a Fridge Document ("snapshot")
  // Create object in memory to hold a fridge
  Fridge.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot.data['name'] != null),
        _name = snapshot.data['name'],
        _uid = snapshot.documentID;

  Fridge.fromComponents(String name, String uid)
      : assert(name != null),
        assert(uid != null),
        _name = name,
        _uid = uid;

  @override
  String toString() => "Fridge<$_name>";

  String get uid {
    return _uid;
  }

  String get name {
    return _name;
  }
}

class FridgeUpdateService {
  // _collection is the collection of fridges, set in the constructor
  final CollectionReference _collection;
  final String _userID;

  FridgeUpdateService(String userID)
      : _collection = Firestore.instance
            .collection("users")
            .document(userID)
            .collection("fridges"),
        _userID = userID;

  // addFridge adds a new fridge
  Future addFridge(String name, int numRows, int rowCapacity) async {
    DocumentReference newFridge = _collection.document();
    await newFridge.setData({'name': name});
    final FridgeRowUpdateService fridgeRowUpdateService =
        FridgeRowUpdateService(_userID, newFridge.documentID);
    // add rows to the fridge
    for (var i = 0; i < numRows; i++) {
      fridgeRowUpdateService.addFridgeRow(i, rowCapacity);
    }
  }

  Future deleteFridge(Fridge fridge) async {
    return await _collection.document(fridge._uid).delete();
  }
}

// the form to be filled out to add a new Fridge
class FridgeForm extends StatefulWidget {
  final TextEditingController _nameController,
      _numRowsController,
      _rowCapController;
  final GlobalKey<FormState> _formKey;

  @override
  FridgeFormState createState() {
    return FridgeFormState();
  }

  FridgeForm(this._nameController, this._numRowsController,
      this._rowCapController, this._formKey);
}

class FridgeFormState extends State<FridgeForm> {
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: widget._formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              child: TextFormField(
                autofocus: true,
                controller: widget._nameController,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter a fridge name';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Fridge Name',
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
            ),
            Padding(
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: widget._numRowsController,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter a number of rows';
                  }
                  if (!(int.tryParse(value) is int)) {
                    return 'Please enter a number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Number of Rows',
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
            ),
            Padding(
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: widget._rowCapController,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter a row capacity';
                  }
                  if (!(int.tryParse(value) is int)) {
                    return 'Please enter a number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Row Capacity',
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
            )
          ],
        ),
      ),
    );
  }
}

class FridgeListView extends StatefulWidget {
  final String _userID;
  final FridgeUpdateService _updateService;

  FridgeListView(this._userID) : _updateService = FridgeUpdateService(_userID);

  @override
  _FridgeListViewState createState() => _FridgeListViewState();
}

class _FridgeListViewState extends State<FridgeListView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection("users")
          .document(widget._userID)
          .collection("fridges")
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        //FridgeList requires: a list of fridge documents, the user's ID, and the fridge navigation function
        return ListView.builder(
          padding: const EdgeInsets.only(top: 20.0),
          itemCount: snapshot.data.documents.length + 1,
          //The `itemBuilder` callback will be called only with indices greater than
          //or equal to zero and less than `itemCount`.
          itemBuilder: (context, index) {
            if (index == snapshot.data.documents.length) {
              return Padding(
                key: ValueKey("Add a fridge"),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.add_box,
                      color: Colors.deepPurple,
                    ),
                    title: Text("Add a fridge"),
                    onTap: () {
                      // onTap, show an AlertDialog that allows users to add a fridge
                      TextEditingController _nameController =
                          TextEditingController();
                      TextEditingController _numRowsController =
                          TextEditingController();
                      TextEditingController _rowCapController =
                          TextEditingController();

                      return showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Add Your Fridge"),
                            content: FridgeForm(
                                _nameController,
                                _numRowsController,
                                _rowCapController,
                                this._formKey),
                            actions: <Widget>[
                              MaterialButton(
                                elevation: 3.0,
                                child: Text('Submit'),
                                onPressed: () async {
                                  if (_formKey.currentState.validate()) {
                                    await widget._updateService.addFridge(
                                      _nameController.text.toString(),
                                      int.parse(_numRowsController.text),
                                      int.parse(_rowCapController.text),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                },
                              )
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            }
            Fridge _fridge =
                Fridge.fromSnapshot(snapshot.data.documents[index]);
            return Padding(
              key: ValueKey(_fridge._uid),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: ListTile(
                  title: Text(_fridge._name),
                  onLongPress: () => showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Confirm Delete Fridge"),
                          content: Text(
                              "Are you sure you want to delete your fridge? \n"
                              "This will delete all wines in your fridge."),
                          actions: <Widget>[
                            FlatButton(
                              child: Text('Yes'),
                              textColor: Colors.red,
                              onPressed: () async {
                                await widget._updateService
                                    .deleteFridge(_fridge);
                                Navigator.of(context).pop();
                              },
                            ),
                            FlatButton(
                              child: Text('Cancel'),
                              textColor: Colors.grey,
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          ],
                        );
                      }),
                  onTap: () => (MainBody.of(context).navigateToFridge(_fridge)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

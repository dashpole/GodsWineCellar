import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'fridge_row.dart';

class Fridge {
  final String name;
  final DocumentReference reference;
  final String uid;

  // Load Fridge from a Fridge Document ("snapshot")
  // Create object in memory to hold a fridge
  Fridge.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot.data['name'] != null),
        reference = snapshot.reference,
        name = snapshot.data['name'],
        uid = snapshot.documentID;

  @override
  String toString() => "Fridge<$name>";
}

class FridgeUpdateService {
  final CollectionReference fridgeCollection;
  final String userID;

  FridgeUpdateService(String userID)
      : fridgeCollection = Firestore.instance
            .collection("users")
            .document(userID)
            .collection("fridges"),
        userID = userID;

  Future addFridge(String name, int numRows, int rowCapacity) async {
    DocumentReference newFridge = fridgeCollection.document();
    await newFridge.setData({'name': name});
    final FridgeRowUpdateService fridgeRowUpdateService =
        FridgeRowUpdateService(userID, newFridge.documentID);
    for (var i = 0; i < numRows; i++) {
      fridgeRowUpdateService.addFridgeRow(i, rowCapacity);
    }
  }

  Future deleteFridge(Fridge fridge) async {
    return await fridgeCollection.document(fridge.uid).delete();
  }

//  Future updateBottle(Bottle old, String name, String winery) async {
//    Map<String, dynamic> data = {};
//    if (name != old.name) {
//      data['name'] = name;
//    }
//    if (winery != old.winery) {
//      data['winery'] = winery;
//    }
//    if (data.isEmpty) {
//      return;
//    }
//    return await bottleCollection.document(old.uid).updateData(data);
//  }
}

class FridgeForm extends StatefulWidget {
  final TextEditingController fridgeNameController;
  final TextEditingController fridgeNumRowsController;
  final TextEditingController fridgeRowCapController;
  final GlobalKey<FormState> _formKey;

  @override
  FridgeFormState createState() {
    return FridgeFormState();
  }

  FridgeForm(this.fridgeNameController, this.fridgeNumRowsController,
      this.fridgeRowCapController, this._formKey);
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
                controller: widget.fridgeNameController,
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
                controller: widget.fridgeNumRowsController,
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
                controller: widget.fridgeRowCapController,
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

class FridgeList extends StatefulWidget {
  final List<DocumentSnapshot> documents;
  final FridgeUpdateService fridgeUpdateService;

  FridgeList(this.documents, String userID)
      : fridgeUpdateService = FridgeUpdateService(userID);

  @override
  _FridgeListState createState() => _FridgeListState();
}

class _FridgeListState extends State<FridgeList> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20.0),
      // data is a DocumentSnapshot
      itemCount: widget.documents.length + 1,
      //The `itemBuilder` callback will be called only with indices greater than
      //or equal to zero and less than `itemCount`.
      itemBuilder: (context, index) {
        if (index == widget.documents.length) {
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
                // onTap, execute the _addFridgeDialog function
                onTap: () => _addFridgeDialog(context),
              ),
            ),
          );
        }
        return _buildFridgeItem(
            context, widget.documents[index], widget.fridgeUpdateService);
      },
    );
  }

  Widget _buildFridgeItem(BuildContext context, DocumentSnapshot data,
      FridgeUpdateService fridgeUpdateService) {
    final fridge = Fridge.fromSnapshot(data);

// Build a list of bottle items
    return Padding(
      key: ValueKey(fridge.uid),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(fridge.name),
          onLongPress: () => showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Confirm Delete Fridge"),
                  content:
                      Text("Are you sure you want to delete your fridge? \n"
                          "This will delete all wines in your fridge."),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Yes'),
                      textColor: Colors.red,
                      onPressed: () async {
                        await fridgeUpdateService.deleteFridge(fridge);
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
        ),
      ),
    );
  }

  _addFridgeDialog(BuildContext context) {
    TextEditingController fridgeNameController = TextEditingController();
    TextEditingController fridgeNumRowsController = TextEditingController();
    TextEditingController fridgeRowCapController = TextEditingController();

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Add Your Fridge"),
            content: FridgeForm(fridgeNameController, fridgeNumRowsController,
                fridgeRowCapController, this._formKey),
            actions: <Widget>[
              MaterialButton(
                elevation: 3.0,
                child: Text('Submit'),
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    await widget.fridgeUpdateService.addFridge(
                        fridgeNameController.text.toString(),
                        int.parse(fridgeNumRowsController.text),
                        int.parse(fridgeRowCapController.text));
                    Navigator.of(context).pop();
                  }
                },
              )
            ],
          );
        });
  }
}

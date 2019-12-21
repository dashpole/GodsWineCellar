import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BottleList extends StatefulWidget {
  final List<DocumentSnapshot> documents;
  final BottleUpdateService bottleUpdateService;

  BottleList(this.documents, String userID)
      : bottleUpdateService = BottleUpdateService(userID);

  @override
  _BottleListState createState() => _BottleListState();
}

class _BottleListState extends State<BottleList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20.0),
      // data is a DocumentSnapshot
      itemCount: widget.documents.length,
      itemBuilder: (context, index) {
        return _buildBottleItem(
            context, widget.documents[index], widget.bottleUpdateService);
      },
    );
  }

  Widget _buildBottleItem(BuildContext context, DocumentSnapshot data,
      BottleUpdateService bottleUpdateService) {
    final wine = Bottle.fromSnapshot(data);

// Build a list of bottle items
    return Padding(
      key: ValueKey(wine.uid),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(wine.name),
          subtitle: Text(wine.winery),
          trailing: PopupMenuButton(
            icon: Icon(Icons.menu),
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem>[
                PopupMenuItem(
                    value: "delete",
                    child: ListTile(
                      title: Text("Delete"),
                      trailing: Icon(Icons.delete),
                      onTap: () {
                        Navigator.pop(context);
                        bottleUpdateService.deleteBottle(wine);
                      },
                    )),
                PopupMenuItem(
                    value: "edit",
                    child: ListTile(
                      title: Text("Edit"),
                      trailing: Icon(Icons.edit),
                      onTap: () {
                        Navigator.pop(context);
                        createEditWineDialog(context, wine);
                      },
                    ))
              ];
            },
          ),
        ),
      ),
    );
  }

  createEditWineDialog(BuildContext context, Bottle bottle) {
    TextEditingController bottleNameController = TextEditingController();
    bottleNameController.text = bottle.name;
    TextEditingController bottleWineryController = TextEditingController();
    bottleWineryController.text = bottle.winery;
    TextEditingController bottleLocation = TextEditingController();
    bottleLocation.text = "Default Location";
    GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Edit Your Wine"),
            content: BottleForm(bottleNameController, bottleWineryController,
                bottleLocation, _formKey),
            actions: <Widget>[
              MaterialButton(
                elevation: 5.0,
                child: Text('Submit'),
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    await widget.bottleUpdateService.updateBottle(
                        bottle,
                        bottleNameController.text.toString(),
                        bottleWineryController.text.toString());
                    Navigator.pop(context);
                  }
                },
              )
            ],
          );
        });
  }
}

class BottleForm extends StatefulWidget {
  final TextEditingController bottleNameController;
  final TextEditingController bottleWineryController;
  final TextEditingController bottleLocation;
  final GlobalKey<FormState> _formKey;

  @override
  BottleFormState createState() {
    return BottleFormState();
  }

  BottleForm(this.bottleNameController, this.bottleWineryController,
      this.bottleLocation, this._formKey);
}

class BottleFormState extends State<BottleForm> {
  //@override
  //void dispose () {
  //  widget.bottleNameController.dispose();
  //  widget.bottleWineryController.dispose();
  //  super.dispose();
  //}

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
                controller: widget.bottleNameController,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter a bottle name';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Wine Name',
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
            ),
            Padding(
              child: TextFormField(
                controller: widget.bottleWineryController,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter a bottle winery';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Winery',
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
            ),
            Padding(
              child: TextFormField(
                controller: widget.bottleLocation,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter a bottle location';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Location',
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
            ),
          ],
        ),
      ),
    );
  }
}

class Bottle {
  final String name;
  final String winery;
  final DocumentReference reference;
  final String uid;

  Bottle.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot.data['name'] != null),
        assert(snapshot.data['winery'] != null),
        reference = snapshot.reference,
        name = snapshot.data['name'],
        winery = snapshot.data['winery'],
        uid = snapshot.documentID;

  @override
  String toString() => "Wine<$name:$winery>";
}

class BottleUpdateService {
  final CollectionReference bottleCollection;

  BottleUpdateService(String userID)
      : bottleCollection = Firestore.instance
            .collection("users")
            .document(userID)
            .collection("wines");

  Future addBottle(String name, String winery, String location) async {
    return await bottleCollection
        .document()
        .setData({'name': name, 'winery': winery, 'location': location});
  }

  Future deleteBottle(Bottle bottle) async {
    return await bottleCollection.document(bottle.uid).delete();
  }

  Future updateBottle(Bottle old, String name, String winery) async {
    Map<String, dynamic> data = {};
    if (name != old.name) {
      data['name'] = name;
    }
    if (winery != old.winery) {
      data['winery'] = winery;
    }
    if (data.isEmpty) {
      return;
    }
    return await bottleCollection.document(old.uid).updateData(data);
  }
}

class AddBottleButton extends StatefulWidget {
  final BottleUpdateService bottleUpdateService;

  final String name = "test wine name";
  final String winery = "test winery";

  AddBottleButton(String userID)
      : bottleUpdateService = BottleUpdateService(userID);

  @override
  _AddBottleButtonState createState() => _AddBottleButtonState();
}

// Given a State of type AddBottleButton, define how it is displayed on the
// screen through the build function
class _AddBottleButtonState extends State<AddBottleButton> {
  final _formKey = GlobalKey<FormState>();

  createAddWineDialog(BuildContext context) {
    TextEditingController bottleNameController = TextEditingController();
    TextEditingController bottleWineryController = TextEditingController();
    TextEditingController bottleLocationController = TextEditingController();

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Add Your Wine"),
            content: BottleForm(bottleNameController, bottleWineryController,
                bottleLocationController, this._formKey),
            actions: <Widget>[
              MaterialButton(
                elevation: 3.0,
                child: Text('Submit'),
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    await widget.bottleUpdateService.addBottle(
                        bottleNameController.text.toString(),
                        bottleWineryController.text.toString(),
                        bottleLocationController.text.toString());
                    Navigator.of(context).pop();
                  }
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        createAddWineDialog(context);
      },
    );
  }
}

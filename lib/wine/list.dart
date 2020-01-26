import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gods_wine_locator/common/bottle.dart';

// WineListView displays all the wines a user has in their cellar
class WineListView extends StatefulWidget {
  final String _userID;
  final BottleUpdateService _updateService;

  WineListView(this._userID) : _updateService = BottleUpdateService(_userID);

  @override
  _WineListViewState createState() => _WineListViewState();
}

class _WineListViewState extends State<WineListView> {
  @override
  Widget build(BuildContext context) {
    // We use a StreamBuilder to rebuild the list of wines whenever the list in the database changes
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection("users")
          .document(widget._userID)
          .collection("wines")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        // If the user doesn't have any wine, display a helpful message
        if (snapshot.data.documents.length == 0)
          return Container(
            child: Center(
              child: Text(
                "Welcome to your wine cellar! \nClick the + button below to add wine.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        // Display the users wine list
        return ListView.builder(
            padding: const EdgeInsets.only(top: 20.0),
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) {
              final _wine = Bottle.fromSnapshot(snapshot.data.documents[index]);
              // BottleListItem handles displaying basic wine info. BottleListItem allows for adding additional pieces to that item - such as an Edit button.
              // The Edit button on the left to allow users to edit/delete wine in this list.
              return BottleListItem(
                bottle: _wine,
                // Edit Button brings up a pop-up menu with delete and edit
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
                              widget._updateService.deleteBottle(_wine);
                            },
                          )),
                      PopupMenuItem(
                        value: "edit",
                        child: ListTile(
                          title: Text("Edit"),
                          trailing: Icon(Icons.edit),
                          // Clicking edit brings up a dialogue to allow specifying the changes to make to the wine
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (context) {
                                return EditBottleDialog(
                                    widget._updateService, _wine);
                              },
                            );
                          },
                        ),
                      ),
                    ];
                  },
                ),
              );
            });
      },
    );
  }
}

// EditBottleDialog displays an AlertDialog that prompts the user to edit a specified wine
class EditBottleDialog extends StatefulWidget {
  final Bottle _bottle;
  final BottleUpdateService _updateService;

  // Initialize the editable Text fields with the name, winery, location, and count respectively.
  EditBottleDialog(this._updateService, this._bottle);

  @override
  _EditBottleDialogState createState() => _EditBottleDialogState(_bottle);
}

class _EditBottleDialogState extends State<EditBottleDialog> {
  TextEditingController _nameController;
  TextEditingController _wineryController;
  TextEditingController _locationController;
  TextEditingController _countController;
  final _formKey = GlobalKey<FormState>();

  _EditBottleDialogState(Bottle _bottle)
      : _nameController = TextEditingController(text: _bottle.name),
        _wineryController = TextEditingController(text: _bottle.winery),
        _locationController = TextEditingController(text: _bottle.location),
        _countController =
            TextEditingController(text: _bottle.count.toString());

  // Keep track of the most recent error encountered during submission so we can display it to users.
  String _submitErr = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Your Wine"),
      // BottleForm handles displaying and doing some validation (e.g. format validation) on the fields in the edit dialog.
      content: BottleForm(_nameController, _wineryController,
          _locationController, _countController, _formKey),
      actions: <Widget>[
        // Display the error if it is set (else display empty Container)
        _submitErr.length == 0
            ? Container()
            : Container(
                height: 100,
                width: 240,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Container(width: 16),
                    Flexible(
                      child: Text(
                        _submitErr,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
        MaterialButton(
          elevation: 5.0,
          child: Text('Submit'),
          onPressed: () async {
            if (_formKey.currentState.validate()) {
              // Try submitting.  If it succeeds, close the edit dialog.  If it fails, display the error.
              try {
                await widget._updateService.updateBottleInfo(
                  widget._bottle.uid,
                  _nameController.text,
                  _wineryController.text,
                  _locationController.text,
                  int.parse(_countController.text),
                );
                Navigator.of(context).pop();
              } catch (e) {
                setState(() {
                  _submitErr = e.toString();
                });
              }
            }
          },
        )
      ],
    );
  }
}

class BottleForm extends StatefulWidget {
  final TextEditingController _nameController;
  final TextEditingController _wineryController;
  final TextEditingController _locationController;
  final TextEditingController _countController;
  final GlobalKey<FormState> _formKey;

  @override
  BottleFormState createState() {
    return BottleFormState();
  }

  BottleForm(this._nameController, this._wineryController,
      this._locationController, this._countController, this._formKey);
}

class BottleFormState extends State<BottleForm> {
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: widget._formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              child: TextFormField(
                controller: widget._wineryController,
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
                autofocus: true,
                controller: widget._nameController,
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
                controller: widget._locationController,
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
            Padding(
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: widget._countController,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter a number of bottles';
                  }
                  if (!(int.tryParse(value) is int)) {
                    return 'Please enter a number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Count',
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

class AddBottleDialog extends StatefulWidget {
  final BottleUpdateService _updateService;

  AddBottleDialog(String userID) : _updateService = BottleUpdateService(userID);

  @override
  _AddBottleDialogState createState() => _AddBottleDialogState();
}

class _AddBottleDialogState extends State<AddBottleDialog> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _wineryController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _countController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _submitErr = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Your Wine"),
      content: BottleForm(_nameController, _wineryController,
          _locationController, _countController, this._formKey),
      actions: <Widget>[
        _submitErr.length == 0
            ? Container()
            : Container(
                height: 100,
                width: 240,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Container(width: 16),
                    Flexible(
                      child: Text(
                        _submitErr,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
        MaterialButton(
          elevation: 3.0,
          child: Text('Submit'),
          onPressed: () async {
            if (_formKey.currentState.validate()) {
              try {
                await widget._updateService.addBottle(
                  _nameController.text,
                  _wineryController.text,
                  _locationController.text,
                  int.parse(_countController.text),
                );
                Navigator.of(context).pop();
              } catch (e) {
                setState(() {
                  _submitErr = e.toString();
                });
              }
            }
          },
        )
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottle.dart';

class BottleList extends StatefulWidget {
  final List<DocumentSnapshot> _documents;
  final BottleUpdateService _updateService;

  BottleList(this._documents, String userID)
      : _updateService = BottleUpdateService(userID);

  @override
  _BottleListState createState() => _BottleListState();
}

class _BottleListState extends State<BottleList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20.0),
      // data is a DocumentSnapshot
      itemCount: widget._documents.length,
      itemBuilder: (context, index) {
        return _buildBottleItem(
            context, widget._documents[index], widget._updateService);
      },
    );
  }

  Widget _buildBottleItem(BuildContext context, DocumentSnapshot data,
      BottleUpdateService bottleUpdateService) {
    final _wine = Bottle.fromSnapshot(data);

// Build a list of bottle items
    return BottleListItem(
      bottle: _wine,
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
                    bottleUpdateService.deleteBottle(_wine);
                  },
                )),
            PopupMenuItem(
              value: "edit",
              child: ListTile(
                title: Text("Edit"),
                trailing: Icon(Icons.edit),
                onTap: () {
                  Navigator.pop(context);
                  createEditWineDialog(context, _wine);
                },
              ),
            ),
          ];
        },
      ),
    );
  }

  createEditWineDialog(BuildContext context, Bottle bottle) {
    TextEditingController _nameController =
        TextEditingController(text: bottle.name);
    TextEditingController _wineryController =
        TextEditingController(text: bottle.winery);
    TextEditingController _locationController =
        TextEditingController(text: bottle.location);
    TextEditingController _countController =
        TextEditingController(text: bottle.count.toString());
    GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Your Wine"),
          content: BottleForm(_nameController, _wineryController,
              _locationController, _countController, _formKey),
          actions: <Widget>[
            MaterialButton(
              elevation: 5.0,
              child: Text('Submit'),
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  await widget._updateService.updateBottle(
                    bottle,
                    _nameController.text,
                    _wineryController.text,
                    _locationController.text,
                    int.parse(_countController.text),
                  );
                  Navigator.pop(context);
                }
              },
            )
          ],
        );
      },
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

class AddBottleButton extends StatefulWidget {
  final BottleUpdateService _updateService;

  AddBottleButton(String userID) : _updateService = BottleUpdateService(userID);

  @override
  _AddBottleButtonState createState() => _AddBottleButtonState();
}

// Given a State of type AddBottleButton, define how it is displayed on the
// screen through the build function
class _AddBottleButtonState extends State<AddBottleButton> {
  final _formKey = GlobalKey<FormState>();

  createAddWineDialog(BuildContext context) {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _wineryController = TextEditingController();
    TextEditingController _locationController = TextEditingController();
    TextEditingController _countController = TextEditingController();

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Add Your Wine"),
            content: BottleForm(_nameController, _wineryController,
                _locationController, _countController, this._formKey),
            actions: <Widget>[
              MaterialButton(
                elevation: 3.0,
                child: Text('Submit'),
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    await widget._updateService.addBottle(
                      _nameController.text,
                      _wineryController.text,
                      _locationController.text,
                      int.parse(_countController.text),
                    );
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

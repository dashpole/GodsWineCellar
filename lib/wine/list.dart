import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gods_wine_locator/common/bottle.dart';

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
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection("users")
          .document(widget._userID)
          .collection("wines")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        return ListView.builder(
          padding: const EdgeInsets.only(top: 20.0),
          // data is a DocumentSnapshot
          itemCount: snapshot.data.documents.length,
          itemBuilder: (context, index) {
            return _buildBottleItem(
                context, snapshot.data.documents[index], widget._updateService);
          },
        );
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
                  showDialog(
                    context: context,
                    builder: (context) {
                      return EditBottleDialog(bottleUpdateService, _wine);
                    },
                  );
                },
              ),
            ),
          ];
        },
      ),
    );
  }
}

class EditBottleDialog extends StatefulWidget {
  final Bottle _bottle;
  final BottleUpdateService _updateService;
  final TextEditingController _nameController;
  final TextEditingController _wineryController;
  final TextEditingController _locationController;
  final TextEditingController _countController;

  EditBottleDialog(this._updateService, this._bottle)
      : _nameController = TextEditingController(text: _bottle.name),
        _wineryController = TextEditingController(text: _bottle.winery),
        _locationController = TextEditingController(text: _bottle.location),
        _countController =
            TextEditingController(text: _bottle.count.toString());

  @override
  _EditBottleDialogState createState() => _EditBottleDialogState();
}

class _EditBottleDialogState extends State<EditBottleDialog> {
  final _formKey = GlobalKey<FormState>();
  String _submitErr = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Your Wine"),
      content: BottleForm(widget._nameController, widget._wineryController,
          widget._locationController, widget._countController, _formKey),
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
          elevation: 5.0,
          child: Text('Submit'),
          onPressed: () async {
            if (_formKey.currentState.validate()) {
              try {
                await widget._updateService.updateBottleInfo(
                  widget._bottle.uid,
                  widget._nameController.text,
                  widget._wineryController.text,
                  widget._locationController.text,
                  int.parse(widget._countController.text),
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

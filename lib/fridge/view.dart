import 'package:flutter/material.dart';
import 'package:gods_wine_locator/common/bottle.dart';
import 'rows.dart';
import 'bottles.dart';
import 'fridges.dart';
import 'unallocated.dart';
import 'dart:math';

class FridgeView extends StatefulWidget {
  final String _userID;
  final BottleUpdateService _bottleUpdateService;

  FridgeView(this._userID):
  _bottleUpdateService = BottleUpdateService(_userID);

  @override
  _FridgeViewState createState() => _FridgeViewState();
}

class _FridgeViewState extends State<FridgeView> {
  int _selectedIndex = 0;
  Fridge _fridge;
  FridgeRow _row;

  void _back() {
    // decrease _selectedIndex by 1, but take max so it can't go negative
    setState(() => [0, _selectedIndex = _selectedIndex - 1].reduce(max));
  }

  void _goToFridge(Fridge _newFridge) {
    setState(() {
      _fridge = _newFridge;
      _selectedIndex = 1;
    });
  }

  void _goToRow(Fridge _newFridge, FridgeRow _newRow) {
    setState(() {
      _fridge = _newFridge;
      _row = _newRow;
      _selectedIndex = 2;
    });
  }

  void _addBottleToFridgeRow(Bottle unallocatedBottle, int count) {
    widget._bottleUpdateService.moveToFridge(unallocatedBottle, _fridge, _row, count);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: <Widget>[
            FridgeListView(widget._userID, _goToFridge),
            FridgeRowListView(widget._userID, _fridge, _back, _goToRow),
            RowBottleListView(widget._userID, _fridge, _row, _back),
          ][_selectedIndex],
        ),
        ExpansionTile(
          title: Text("Unallocated Wines"),
          children: <Widget>[
            UnallocatedBottleListView(widget._userID, _addBottleToFridgeRow, _selectedIndex == 2),
          ],
        ),
        Container(height: 20),
      ],
    );
  }
}

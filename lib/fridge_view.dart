import 'package:flutter/material.dart';
import 'fridge_row.dart';
import 'row_bottle_group.dart';
import 'fridge.dart';
import 'unallocated_list.dart';
import 'dart:math';

class FridgePage extends StatefulWidget {
  final String _userID;

  FridgePage(this._userID);

  @override
  _FridgePageState createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: <Widget>[
            FridgeListView(widget._userID, _goToFridge),
            FridgeRowListView(widget._userID, _fridge, _back, _goToRow),
            RowBottleGroupListView(widget._userID, _fridge, _row, _back),
          ][_selectedIndex],
        ),
        ExpansionTile(
          title: Text("Unallocated Wines"),
          children: <Widget>[
            UnallocatedBottleListPage(widget._userID),
          ],
        ),
        Container(height: 20),
      ],
    );
  }
}

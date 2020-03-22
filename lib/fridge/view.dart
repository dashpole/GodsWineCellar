import 'package:flutter/material.dart';
import 'package:gods_wine_cellar/common/bottle.dart';
import 'rows.dart';
import 'bottles.dart';
import 'fridges.dart';
import 'unallocated.dart';
import 'dart:math';

class FridgeView extends StatefulWidget {
  final String _userID;
  final BottleUpdateService _bottleUpdateService;

  FridgeView(this._userID)
      : _bottleUpdateService = BottleUpdateService(_userID);

  @override
  _FridgeViewState createState() => _FridgeViewState();
}

class _FridgeViewState extends State<FridgeView> {
  //_selectedIndex refers to the selected view from the list of possible views (FridgeList, FridgeRow, RowBottle)
  int _selectedIndex = 0;
  Fridge _fridge;
  FridgeRow _row;

  void _navigateBack() {
    // decrease _selectedIndex by 1, but take max so it can't go negative
    setState(() => _selectedIndex = [0, _selectedIndex - 1].reduce(max));
  }

  // navigate to the individual fridge view
  void _navigateToFridge(Fridge _newFridge) {
    setState(() {
      _fridge = _newFridge;
      _selectedIndex = 1;
    });
  }

  // navigate to an individual fridge row, which contains bottles
  void _navigateToRow(Fridge _newFridge, FridgeRow _newRow) {
    setState(() {
      _fridge = _newFridge;
      _row = _newRow;
      _selectedIndex = 2;
    });
  }

  // adds a bottle to the current fridge row from the unallocated bottles list
  Future<void> _addBottlesToFridgeRow(
      Bottle unallocatedBottle, int count) async {
    await widget._bottleUpdateService
        .moveToFridge(unallocatedBottle.uid, _fridge, _row, count);
  }

  // moves a bottle from the current fridge row to the unallocated bottles list
  Future<void> _removeBottlesFromFridgeRow(
      Bottle fridgeRowBottle, int count) async {
    await widget._bottleUpdateService
        .removeFromFridge(fridgeRowBottle.uid, _fridge, _row, count);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: <Widget>[
            //list of possible pages/ views
            FridgeListView(widget._userID, _navigateToFridge),
            FridgeRowListView(
                widget._userID, _fridge, _navigateBack, _navigateToRow),
            RowBottleListView(widget._userID, _fridge, _row, _navigateBack,
                _removeBottlesFromFridgeRow),
          ][_selectedIndex],
        ),
        ExpansionTile(
          // Unallocated list view that is hidden at the bottom, until expanded
          title: Text("Unallocated Wines"),
          children: <Widget>[
            UnallocatedBottleListView(
                widget._userID, _addBottlesToFridgeRow, _selectedIndex == 2),
          ],
        ),
        Container(height: 20),
      ],
    );
  }
}

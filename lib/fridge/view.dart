import 'package:flutter/material.dart';
import 'package:gods_wine_cellar/common/bottle.dart';
import 'rows.dart';
import 'bottles.dart';
import 'fridges.dart';
import 'unallocated.dart';

class FridgeView extends StatefulWidget {
  final String _userID;
  final BottleUpdateService _bottleUpdateService;
  final int _selectedIndex;
  final Fridge _fridge;
  final FridgeRow _row;

  FridgeView(this._userID, this._selectedIndex, this._fridge, this._row)
      : _bottleUpdateService = BottleUpdateService(_userID);

  @override
  _FridgeViewState createState() => _FridgeViewState();
}

class _FridgeViewState extends State<FridgeView> {
  // adds a bottle to the current fridge row from the unallocated bottles list
  Future<void> _addBottlesToFridgeRow(Bottle unallocatedBottle) async {
    await widget._bottleUpdateService
        .moveToFridge(unallocatedBottle.uid, widget._fridge, widget._row, 1);
  }

  // moves a bottle from the current fridge row to the unallocated bottles list
  Future<void> _removeBottlesFromFridgeRow(Bottle fridgeRowBottle) async {
    await widget._bottleUpdateService
        .removeFromFridge(fridgeRowBottle.uid, widget._fridge, widget._row, 1);
  }

  // moves a bottle from the current fridge row to the unallocated bottles list
  Future<void> _drinkBottleFromFridge(Bottle fridgeRowBottle) async {
    await widget._bottleUpdateService.drinkBottleFromFridge(
        fridgeRowBottle.uid, widget._fridge, widget._row);
  }

  // moves a bottle from the current fridge row to the unallocated bottles list
  Future<void> _drinkUnallocatedBottle(Bottle bottle) async {
    await widget._bottleUpdateService.drinkUnallocatedBottle(bottle.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: <Widget>[
            //list of possible pages/ views
            FridgeListView(widget._userID),
            FridgeRowListView(widget._userID, widget._fridge),
            RowBottleListView(widget._userID, widget._fridge, widget._row,
                _removeBottlesFromFridgeRow, _drinkBottleFromFridge),
          ][widget._selectedIndex],
        ),
        ExpansionTile(
          // Unallocated list view that is hidden at the bottom, until expanded
          title: Text("Unallocated Wines"),
          children: <Widget>[
            UnallocatedBottleListView(widget._userID, _addBottlesToFridgeRow,
                _drinkUnallocatedBottle, widget._selectedIndex == 2),
          ],
        ),
        Container(height: 20),
      ],
    );
  }
}

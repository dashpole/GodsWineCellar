import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gods_wine_locator/fridge/fridges.dart';
import 'package:gods_wine_locator/fridge/rows.dart';

class BottleListItem extends StatelessWidget {
  final Bottle bottle;
  final Widget trailing;

  const BottleListItem({
    this.trailing,
    this.bottle,
  }) : assert(bottle != null);

  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey(bottle._uid),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(bottle._name),
          subtitle: Text(bottle._winery),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'x${bottle._count}',
                textScaleFactor: 1.5,
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0)),
              (trailing == null) ? Container() : trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class Bottle {
  final String _name;
  final String _winery;
  final String _location;
  final int _count;
  final String _uid;

  String get uid {
    return _uid;
  }

  String get name {
    return _name;
  }

  String get winery {
    return _winery;
  }

  String get location {
    return _location;
  }

  int get count {
    return _count;
  }

  Map<String, dynamic> get data {
    return {
      'name': _name,
      'winery': _winery,
      'location': _location,
      'count': _count
    };
  }

  Map<String, dynamic> diff(
      String name, String winery, String location, int count) {
    Map<String, dynamic> data = diffInfo(name, winery, location);
    if (count != _count) {
      data['count'] = count;
    }
    return data;
  }

  Map<String, dynamic> diffInfo(String name, String winery, String location) {
    Map<String, dynamic> data = {};
    if (name != _name) {
      data['name'] = name;
    }
    if (winery != _winery) {
      data['winery'] = winery;
    }
    if (location != _location) {
      data['location'] = location;
    }
    return data;
  }

  Bottle.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot.data['name'] != null),
        assert(snapshot.data['winery'] != null),
        assert(snapshot.data['location'] != null),
        assert(snapshot.data['count'] != null),
        _name = snapshot.data['name'],
        _winery = snapshot.data['winery'],
        _location = snapshot.data['location'],
        _count = snapshot.data['count'],
        _uid = snapshot.documentID;

  @override
  String toString() => "Wine<$_name:$_winery>";
}

class BottleUpdateService {
  final CollectionReference _winesCollection,
      _fridgesCollection,
      _unallocatedCollection;

  BottleUpdateService(String userID)
      : _winesCollection = Firestore.instance
            .collection("users")
            .document(userID)
            .collection("wines"),
        _fridgesCollection = Firestore.instance
            .collection("users")
            .document(userID)
            .collection("fridges"),
        _unallocatedCollection = Firestore.instance
            .collection("users")
            .document(userID)
            .collection("unallocated");

  Future<void> addBottle(
      String name, String winery, String location, int count) async {
    QuerySnapshot matchesQuery = await _winesCollection
        .where('name', isEqualTo: name)
        .where('winery', isEqualTo: winery)
        .getDocuments();
    bool alreadyExists = matchesQuery.documents.length > 0;
    if (alreadyExists) {
      throw ("Wine already exists");
    }

    Map<String, dynamic> data = {
      'name': name,
      'winery': winery,
      'location': location,
      'count': count
    };
    final String newId = _winesCollection.document().documentID;
    var batch = Firestore.instance.batch();
    batch.setData(_unallocatedCollection.document(newId), data);
    batch.setData(_winesCollection.document(newId), data);
    return await batch.commit();
  }

  Future deleteBottle(Bottle bottle) async {
    var batch = Firestore.instance.batch();
    QuerySnapshot fridges = await _fridgesCollection.getDocuments();
    await Future.forEach(fridges.documents, (DocumentSnapshot fridge) async {
      QuerySnapshot rows =
          await fridge.reference.collection("rows").getDocuments();
      await Future.forEach(rows.documents, (DocumentSnapshot row) async {
        QuerySnapshot bottles =
            await row.reference.collection("bottles").getDocuments();
        List<DocumentSnapshot> documents = bottles.documents;
        documents
            .retainWhere((rowBottle) => rowBottle.documentID == bottle.uid);
        await Future.forEach(documents, (DocumentSnapshot document) {
          batch.delete(document.reference);
        });
      });
    });
    batch.delete(_winesCollection.document(bottle._uid));
    batch.delete(_unallocatedCollection.document(bottle._uid));
    return await batch.commit();
  }

  Future moveToFridge(Bottle unallocatedBottle, Fridge fridge, FridgeRow row,
      int numToMove) async {
    var batch = Firestore.instance.batch();
    if (numToMove > unallocatedBottle.count) {
      // TODO Can there be a race condition here?
      throw ("Can't move $numToMove bottles, since you only have ${unallocatedBottle.count} unallocated");
    }

    // Add the bottles to the rowBottleGroup
    DocumentReference rowBottleGroupReference = _fridgesCollection
        .document(fridge.uid)
        .collection("rows")
        .document(row.number.toString())
        .collection("bottles")
        .document(unallocatedBottle.uid);
    DocumentSnapshot rowBottleGroupDocument =
        await rowBottleGroupReference.get();
    int countInRow = numToMove;
    if (rowBottleGroupDocument.exists)
      countInRow += Bottle.fromSnapshot(rowBottleGroupDocument).count;
    if (countInRow > row.capacity)
      throw ("Can't move $numToMove bottle(s) because there are ${countInRow - numToMove - row.capacity} spots available in the row");
    Map<String, dynamic> rowBottleData = unallocatedBottle.data;
    rowBottleData['count'] = countInRow;
    batch.setData(rowBottleGroupReference, rowBottleData);

    // Remove the bottles from the unallocated list
    Map<String, dynamic> unallocatedData = {
      'count': unallocatedBottle.count - numToMove,
    };
    batch.updateData(_unallocatedCollection.document(unallocatedBottle.uid),
        unallocatedData);
    return await batch.commit();
  }

  Future updateBottleInfo(Bottle wineListBottle, String newName,
      String newWinery, String newLocation, int newCount) async {
    var batch = Firestore.instance.batch();
    if (newCount < 0) {
      throw ("You must set a positive number of bottles.");
    }

    // Update the main wine list with all modified information, including count.
    Map<String, dynamic> wineListDiff =
        wineListBottle.diff(newName, newWinery, newLocation, newCount);
    if (wineListDiff.isEmpty) {
      return;
    }
    batch.updateData(
        _winesCollection.document(wineListBottle._uid), wineListDiff);

    // Check to make sure unallocated isn't negative after the change
    int deltaCount = newCount - wineListBottle.count;
    DocumentSnapshot unallocatedDocument =
        await _unallocatedCollection.document(wineListBottle._uid).get();
    Bottle unallocatedBottle = Bottle.fromSnapshot(unallocatedDocument);
    int newUnallocatedCount = unallocatedBottle.count + deltaCount;
    if (newUnallocatedCount < 0) {
      // TODO should this check happen in a transaction instead of a batch?
      // In theory, there is a race condition here...
      throw ("Not enough unallocated wine to decrease bottles by ${-deltaCount}");
    }
    Map<String, dynamic> unallocatedDiff = unallocatedBottle.diff(
        newName, newWinery, newLocation, newUnallocatedCount);
    batch.updateData(
        _unallocatedCollection.document(wineListBottle._uid), unallocatedDiff);

    // Update all of the bottles in fridges, but do not update the count in
    // fridge rows.
    Map<String, dynamic> infoData =
        wineListBottle.diffInfo(newName, newWinery, newLocation);
    if (infoData.isNotEmpty) {
      QuerySnapshot fridges = await _fridgesCollection.getDocuments();
      await Future.forEach(fridges.documents, (DocumentSnapshot fridge) async {
        QuerySnapshot rows =
            await fridge.reference.collection("rows").getDocuments();
        await Future.forEach(rows.documents, (DocumentSnapshot row) async {
          QuerySnapshot bottles =
              await row.reference.collection("bottles").getDocuments();
          List<DocumentSnapshot> documents = bottles.documents;
          documents.retainWhere(
              (rowBottle) => rowBottle.documentID == wineListBottle.uid);
          await Future.forEach(documents, (DocumentSnapshot document) {
            batch.updateData(document.reference, infoData);
          });
        });
      });
    }
    return await batch.commit();
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gods_wine_cellar/fridge/fridges.dart';
import 'package:gods_wine_cellar/fridge/rows.dart';

// BottleListItem displays a list item with information about a bottle.  It
// allows customizing the trailing widget at the right for adding buttons, etc.
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

  // addBottle creates a new bottle in the database.  It adds the bottle to the
  // wine list and the unallocated list.
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
    // Use a batch for deletions even though there are race conditions.
    // getDocuments is not supported in transactions; only get(document) works.
    var batch = Firestore.instance.batch();
    batch.setData(_unallocatedCollection.document(newId), data);
    batch.setData(_winesCollection.document(newId), data);
    return await batch.commit();
  }

  // deleteBottle removes all occurrences of a bottle from the database,
  // including from the wine list, unallocated list, and all bottles in fridges.
  Future deleteBottle(Bottle bottle) async {
    // Use a batch for deletions even though there are race conditions.
    // getDocuments is not supported in transactions; only get(document) works.
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

  // moveToFridge removes numToMove bottles from the unallocated list and add
  // them to the fridge list.
  Future moveToFridge(String unallocatedBottleUid, Fridge fridge, FridgeRow row,
      int numToMove) async {
    return await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot unallocatedBottleSnapshot =
          await tx.get(_unallocatedCollection.document(unallocatedBottleUid));
      Bottle unallocatedBottle = Bottle.fromSnapshot(unallocatedBottleSnapshot);
      if (numToMove > unallocatedBottle.count) {
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
          await tx.get(rowBottleGroupReference);
      int countInRow = numToMove;
      if (rowBottleGroupDocument.exists)
        countInRow += Bottle.fromSnapshot(rowBottleGroupDocument).count;
      if (countInRow > row.capacity)
        throw ("Can't move $numToMove bottle(s) because there are ${countInRow - numToMove - row.capacity} spots available in the row");
      Map<String, dynamic> rowBottleData = unallocatedBottle.data;
      rowBottleData['count'] = countInRow;
      tx.set(rowBottleGroupReference, rowBottleData);

      // Remove the bottles from the unallocated list
      Map<String, dynamic> unallocatedData = {
        'count': unallocatedBottle.count - numToMove,
      };
      tx.update(_unallocatedCollection.document(unallocatedBottle.uid),
          unallocatedData);
    });
  }

  // removeFromFridge removes numToMove bottles from the specified FridgeRow,
  // and adds them to the unallocated list.
  Future removeFromFridge(String fridgeRowBottleUid, Fridge fridge,
      FridgeRow row, int numToMove) async {
    return await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot fridgeRowBottleSnapshot = await tx.get(_fridgesCollection
          .document(fridge.uid)
          .collection("rows")
          .document(row.number.toString())
          .collection("bottles")
          .document(fridgeRowBottleUid));
      Bottle fridgeRowBottle = Bottle.fromSnapshot(fridgeRowBottleSnapshot);
      if (numToMove > fridgeRowBottle.count) {
        throw ("Can't remove $numToMove bottles, since you only have ${fridgeRowBottle.count} in the row");
      }

      // Remove the bottle from the row
      int newAllocatedBottleCount = fridgeRowBottle.count - numToMove;
      DocumentReference rowBottleReference = _fridgesCollection
          .document(fridge.uid)
          .collection("rows")
          .document(row.number.toString())
          .collection("bottles")
          .document(fridgeRowBottle.uid);
      if (newAllocatedBottleCount == 0)
        tx.delete(rowBottleReference);
      else
        tx.update(rowBottleReference, {'count': newAllocatedBottleCount});

      // Add the bottles to the unallocated list
      DocumentReference unallocatedReference =
          _unallocatedCollection.document(fridgeRowBottle._uid);
      DocumentSnapshot unallocatedDocument = await unallocatedReference.get();
      int newUnallocatedCount = numToMove;
      if (unallocatedDocument.exists)
        newUnallocatedCount += Bottle.fromSnapshot(unallocatedDocument).count;
      tx.update(unallocatedReference, {'count': newUnallocatedCount});
    });
  }

  // updateBottleInfo updates the information for a group of bottles, and
  // ensures the changes are applied to all bottles in the database, including
  // wine list, unallocated list, and bottles in fridges.  Updates to the count
  // are treated as adding/removing bottles from the unallocated list.  This
  // means the count of bottles in fridge rows is not changed, and the change in
  // the number of bottles is added to the unallocated list.
  Future updateBottleInfo(String bottleUid, String newName, String newWinery,
      String newLocation, int newCount) async {
    return await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot wineListBottleSnapshot =
          await tx.get(_winesCollection.document(bottleUid));
      Bottle wineListBottle = Bottle.fromSnapshot(wineListBottleSnapshot);
      if (newCount < 0) {
        throw ("You must set a positive number of bottles.");
      }

      // Check to make sure unallocated isn't negative after the change.
      int deltaCount = newCount - wineListBottle.count;
      DocumentSnapshot unallocatedDocument =
          await tx.get(_unallocatedCollection.document(bottleUid));
      Bottle unallocatedBottle = Bottle.fromSnapshot(unallocatedDocument);
      int newUnallocatedCount = unallocatedBottle.count + deltaCount;
      if (newUnallocatedCount < 0) {
        throw ("Not enough unallocated wine to decrease bottles by ${-deltaCount}");
      }

      // Update the main wine list with all modified information, including count.
      Map<String, dynamic> wineListDiff =
          wineListBottle.diff(newName, newWinery, newLocation, newCount);
      if (wineListDiff.isEmpty) {
        return;
      }
      tx.update(_winesCollection.document(bottleUid), wineListDiff);

      // Update the unallocated list with the new information, including the
      // count we just computed.
      Map<String, dynamic> unallocatedDiff = unallocatedBottle.diff(
          newName, newWinery, newLocation, newUnallocatedCount);
      tx.update(_unallocatedCollection.document(bottleUid), unallocatedDiff);

      // Update information for all of the bottles in fridges, but do not update
      // the count.
      Map<String, dynamic> infoData =
          wineListBottle.diffInfo(newName, newWinery, newLocation);
      if (infoData.isNotEmpty) {
        // List all fridges
        QuerySnapshot fridges = await _fridgesCollection.getDocuments();
        // For each fridge...
        await Future.forEach(fridges.documents,
            (DocumentSnapshot fridge) async {
          // List all rows
          QuerySnapshot rows =
              await fridge.reference.collection("rows").getDocuments();
          // For each row...
          await Future.forEach(rows.documents, (DocumentSnapshot row) async {
            // Update the bottle information if it is in the row
            DocumentSnapshot bottle = await row.reference
                .collection("bottles")
                .document(bottleUid)
                .get();
            if (bottle.exists) {
              tx.update(bottle.reference, infoData);
            }
          });
        });
      }
    });
  }
}

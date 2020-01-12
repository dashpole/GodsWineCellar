import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    if (count != _count) {
      data['count'] = count;
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
  final CollectionReference _winesCollection, _fridgesCollection;

  BottleUpdateService(String userID)
      : _winesCollection = Firestore.instance
            .collection("users")
            .document(userID)
            .collection("wines"),
        _fridgesCollection = Firestore.instance
            .collection("users")
            .document(userID)
            .collection("fridges");

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
    return await _winesCollection.document().setData(
        {'name': name, 'winery': winery, 'location': location, 'count': count});
  }

  Future deleteBottle(Bottle bottle) async {
    // TODO: Delete all instances in fridges
    return await _winesCollection.document(bottle._uid).delete();
  }

  Future updateBottle(Bottle old, String name, String winery, String location,
      int count) async {
    Map<String, dynamic> data = old.diff(name, winery, location, count);
    if (data.isEmpty) {
      return;
    }

    // Update all of the bottles in fridges
    // TODO: Don't update count in fridges!
    var batch = Firestore.instance.batch();
    QuerySnapshot fridges = await _fridgesCollection.getDocuments();
    await Future.forEach(fridges.documents, (DocumentSnapshot fridge) async {
      QuerySnapshot rows =
          await fridge.reference.collection("rows").getDocuments();
      await Future.forEach(rows.documents, (DocumentSnapshot row) async {
        QuerySnapshot bottles =
            await row.reference.collection("bottlegroups").getDocuments();
        List<DocumentSnapshot> documents = bottles.documents;
        documents.retainWhere((rowBottle) => rowBottle.documentID == old.uid);
        await Future.forEach(documents, (DocumentSnapshot document) {
          batch.updateData(document.reference, data);
        });
      });
    });

    // Update the main wine list.
    batch.updateData(_winesCollection.document(old._uid), data);
    return await batch.commit();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Fridge {
  final String name;
  final DocumentReference reference;
  final String uid;

  // Load Fridge from a Fridge Document ("snapshot")
  // Create object in memory to hold a fridge
  Fridge.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot.data['name'] != null),
        reference = snapshot.reference,
        name = snapshot.data['name'],
        uid = snapshot.documentID;

  @override
  String toString() => "Fridge<$name>";
}

class FridgeUpdateService {
  final CollectionReference fridgeCollection;

  FridgeUpdateService(String userID)
      : fridgeCollection = Firestore.instance.collection("users").document(userID).collection("fridges");

  Future addFridge(String name) async {
    return await fridgeCollection
        .document()
        .setData({'name': name});
  }

  Future deleteFridge(Fridge fridge) async {
    return await fridgeCollection.document(fridge.uid).delete();
  }

//  Future updateBottle(Bottle old, String name, String winery) async {
//    Map<String, dynamic> data = {};
//    if (name != old.name) {
//      data['name'] = name;
//    }
//    if (winery != old.winery) {
//      data['winery'] = winery;
//    }
//    if (data.isEmpty) {
//      return;
//    }
//    return await bottleCollection.document(old.uid).updateData(data);
//  }
}
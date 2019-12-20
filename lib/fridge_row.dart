import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FridgeRow {
  final Int8 number;
  final Int8 capacity;
  final DocumentReference reference;
  final String uid;

  // Load FridgeRow from a FridgeRow Document ("snapshot")
  // Create object in memory to hold a fridgeRow
  FridgeRow.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot.data['number'] != null),
        reference = snapshot.reference,
        number = snapshot.data['number'],
        capacity = snapshot.data['capacity'],
        uid = snapshot.documentID;

  @override
  String toString() => "FridgeRow<$number:$capacity>";
}

class FridgeRowUpdateService {
  final CollectionReference fridgeRowCollection;

  FridgeRowUpdateService(String userID, String fridgeID)
      : fridgeRowCollection = Firestore.instance.collection("users").
  document(userID).collection("fridges").document(fridgeID).collection("rows");

  Future addFridgeRow(Int8 number, Int8 capacity) async {
    return await fridgeRowCollection
        .document()
        .setData({'number': number, 'capacity': capacity});
  }

//  Future deleteFridgeRow(FridgeRow fridgeRow) async {
//    return await fridgeRowCollection.document(fridgeRow.uid).delete();
//  }

}
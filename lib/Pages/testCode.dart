// //testing code, ignore this
// import 'package:chatappdemo1/services/database.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class testcode extends StatefulWidget {
//   const testcode({super.key});

//   @override
//   State<testcode> createState() => _testcodeState();
// }

// class _testcodeState extends State<testcode> {
//   //search icon boolean, when clicked it will be set to true
//   bool search = false;

//   var querySearchResult = [];
//   var temporarySearchResult = [];

//   initialSearch(value) {
//     if (value.length == 0) {
//       setState(() {
//         querySearchResult = [];
//         temporarySearchResult = [];
//       });
//     } else {
//       setState(() {
//         search = true;
//       });
//       if (querySearchResult.isEmpty && value.length == 1) {
//         DatabaseMethods().Search(value).then((QuerySnapshot docs) {
//           for (int i = 0; i < docs.docs.length; ++i) {
//             querySearchResult.add(docs.docs[1].data());
//           }
//         });
//       } else {
//         temporarySearchResult = [];
//         querySearchResult.forEach((element) {
//           if (element['Username']) {
//             temporarySearchResult.add(element);
//           }
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }

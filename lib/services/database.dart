//functions related to database methods

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

//integrates data to database
class DatabaseMethods {
  //upload photo
  Future<String?> uploadUserProfilePhoto(File imageFile) async {
    try {
      String userId = await SharedPreference().getUserID() as String;
      String fileName = 'profile_image_$userId.jpg';

      //upload image to Firebase Storage
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref('profile_image_$userId.jpg')
          .putFile(imageFile);
      // Get the download URL
      String photoURL = await snapshot.ref.getDownloadURL();
      //update users photo URL in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .update({'Photo': photoURL});
      //refresh the user to get the updated user data
      await FirebaseAuth.instance.currentUser!.reload();

      return photoURL;
    } catch (e) {
      print('Error uploading profile photo: $e');
      return null;
    }
  }

  //get chatrooms
  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String? myUsername = await SharedPreference().getUserName();
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .orderBy("time", descending: true)
        .where("users", arrayContains: myUsername!)
        .snapshots();
  }

  //get user data from collection for replacing the chatroom id with the actual id
  Future<QuerySnapshot> getUserInfo(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("Username", isEqualTo: username)
        .get();
  }

  //get chat room msgs
  Future<Stream<QuerySnapshot>> getChatroomMessages(chatroomIds) async {
    //returns all the msgs by order
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatroomIds)
        .collection("chats")
        .orderBy("time", descending: true)
        .snapshots();
  }

  //function update messages
  updateLastMessageSent(
      String chatroomId, Map<String, dynamic> lastMessageInfoMap) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatroomId)
        .update(lastMessageInfoMap);
  }

  //add message function to firebase
  Future addMessage(String chatRoomId, String messageId,
      Map<String, dynamic> messageDataMap) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .set(messageDataMap);
  }

  //create chat room
  createChatRoom(
      String chatRoomId, Map<String, dynamic> chatRoomDataMap) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
    if (snapshot.exists) {
      return true;
    } else {
      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .set(chatRoomDataMap);
    }
  }

  //getfriends photo when searching
  Future<String?> getFriendPhotoURL(String friendName) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .where("Username", isEqualTo: friendName)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        String? photoURL = querySnapshot.docs.first.get("Photo");
        return photoURL;
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting photo URL: $e");
      return null;
    }
  }

  //function to get user friends and store them to a list
  Future<List<String>> getUserFriends() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    List<String> friendsList = [];

    querySnapshot.docs
        .forEach((DocumentSnapshot<Map<String, dynamic>> document) {
      // Check if the 'friends' field exists and is an array in the document
      if (document.data()!.containsKey('friends') &&
          document['friends'] is List<dynamic>) {
        List<dynamic> friends = document['friends'];
        friendsList.addAll(friends.map((friend) => friend.toString()));
      }
    });

    return friendsList;
  }

  //function to check if a friend request has been already sent
  Future<bool> checkFriendRequestExist(
      String senderId, String recipientId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection("friendRequests")
        .where("senderId", isEqualTo: senderId)
        .where("recipientId", isEqualTo: recipientId)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  //check friends request status
  Future<String> checkFriendRequestStatus(
      String senderId, String recipientId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("friendRequests")
          .where("senderId", isEqualTo: senderId)
          .where("recipientId", isEqualTo: recipientId)
          .get();

      //check if there is a document in the query result
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot docSnapshot = querySnapshot.docs[0];

        //check the status of the friend request
        String status = docSnapshot.get("status") ?? "";
        return status;
      }
      return "Document is Empty";
      //no document found, implicitly return null (void)
    } catch (e) {
      print("Error checking friend request status: $e");
      return "Exception Error";
    }
  }

  //function to accept a friend request
  Future<void> acceptFriendRequest(String senderId, String recipientId) async {
    try {
      //get sender's username
      String? senderUsername = await getUsernameByUserId(senderId);

      //get recipient's username
      String? recipientUsername = await getUsernameByUserId(recipientId);

      if (senderUsername != null && recipientUsername != null) {
        //update sender's friends collection with recipient's username
        DocumentReference senderDoc =
            FirebaseFirestore.instance.collection("users").doc(senderId);
        await senderDoc.update({
          'friends': FieldValue.arrayUnion([recipientUsername])
        });

        //update recipient's friends collection with sender's username
        DocumentReference recipientDoc =
            FirebaseFirestore.instance.collection("users").doc(recipientId);
        await recipientDoc.update({
          'friends': FieldValue.arrayUnion([senderUsername])
        });

        //updates the friend request entry
        await FirebaseFirestore.instance
            .collection("friendRequests")
            .where("senderId", isEqualTo: senderId)
            .where("recipientId", isEqualTo: recipientId)
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) {
            doc.reference.update({'status': 'accepted'});
          });
        });

        // TODO: Update local friends list if needed
      } else {
        //handle the case where usernames are not available
        print(
            "Error: Usernames not found for senderId: $senderId or recipientId: $recipientId");
      }
    } catch (e) {
      print("Error accepting friend request: $e");
      // Handle the error as needed
    }
  }

  //function to reject a friend request
  Future<void> rejectFriendRequest(String senderId, String recipientId) async {
    try {
      //delete the friend request from the collection
      await FirebaseFirestore.instance
          .collection("friendRequests")
          .where("senderId", isEqualTo: senderId)
          .where("recipientId", isEqualTo: recipientId)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.update({'status': 'rejected'});
          //doc.reference.delete();
        });
      });
      //TO-DO, update the status in case we want to keep a record
      //of rejected friend requests in a separate collection.
      //we add a 'status' field and set it to 'rejected'.
    } catch (e) {
      print("error rejecting friend request: $e");
      // You might want to throw an exception or handle the error in a way that suits your application
    }
  }

  //function to get friend requests based on userId
  Future<List<String>> getFriendRequests() async {
    String userId = await SharedPreference().getUserID() as String;

    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance
            .collection("friendRequests")
            .where("recipientId", isEqualTo: userId)
            .where("status", isEqualTo: "pending") //more conditions if needed
            .get();

    List<String> friendRequests = [];

    for (QueryDocumentSnapshot<Map<String, dynamic>>? documentSnapshot
        in querySnapshot.docs) {
      if (documentSnapshot != null) {
        String senderId = documentSnapshot.data()!['senderId'];
        String? senderUsername = await getUsernameByUserId(senderId);
        if (senderUsername != null) {
          friendRequests.add(senderUsername);
        } else {
          friendRequests.add("Unknown");
        }
      }
    }

    return friendRequests;
  }

  //maping user details to firebase
  Future addUserDetails(
      Map<String, dynamic> userInformationMap, String id) async {
    // Add 'friends' field to the user details map
    userInformationMap['friends'] = [];
    //uploads the map to firebase, called from sign up
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInformationMap);
  }

  //send a friend request
  Future<void> sendFriendRequest(String senderId, String recipientId) async {
    await FirebaseFirestore.instance.collection("friendRequests").add({
      'senderId': senderId,
      'recipientId': recipientId,
      'status': 'pending', // more statuses needed
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  //fetch user data from Firestore database
  Future<QuerySnapshot> getUserbyEmail(String email) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("Email", isEqualTo: email)
        .get();
  }

  //fetch userid from database by username
  Future<String?> getUserIdByUsername(String username) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("Username", isEqualTo: username)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    } else {
      return null;
    }
  }

  //function to get username based on user ID
  Future<String?> getUsernameByUserId(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(userId)
              .get();

      if (documentSnapshot.exists) {
        String? username = documentSnapshot.data()!['Username'];
        print("Username for userID: $userId is $username");
        return username;
      } else {
        print("User document does not exist for userID: $userId");
        return null;
      }
    } catch (e) {
      print("Error fetching username for userID: $userId, Error: $e");
      return null;
    }
  }

  // Function to get usernames based on user IDs
  Future<List<String>> getUsernameByUserIds(List<String> userIds) async {
    List<String> usernames = [];

    for (String userId in userIds) {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(userId)
              .get();

      if (documentSnapshot.exists) {
        String username = documentSnapshot.data()!['username'];
        usernames.add(username);
      }
    }

    return usernames;
  }
}

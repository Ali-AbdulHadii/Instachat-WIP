//functions related to database methods

import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

//integrates data to database
class DatabaseMethods {
  // Function to get all friend usernames of a user
  Future<List<String>> getFriendUsernames(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(userId)
              .get();

      if (documentSnapshot.exists) {
        List<dynamic>? friendsList = documentSnapshot.data()?['friends'];

        if (friendsList != null) {
          List<String> friendUsernames = friendsList
              .map((friend) => friend['username'] as String)
              .toList();
          return friendUsernames;
        }
      }
    } catch (e) {
      print("Error fetching friend usernames: $e");
    }

    // Return an empty list if there is an error or no friends
    return [];
  }

  Future<List<String>> fetchFriendsFromFirebase() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('friends').get();

      List<String> friends = querySnapshot.docs
          .map((doc) => doc.data()!['username'] as String)
          .toList();

      return friends;
    } catch (e) {
      print('Error fetching friends from Firebase: $e');
      return [];
    }
  }

  Future<List<String>> searchFriends(String searchText) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection("users")
        .where("Username", isGreaterThanOrEqualTo: searchText)
        .where("Username", isLessThan: searchText + 'z')
        .get();

    List<String> friends = [];

    for (QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot
        in querySnapshot.docs) {
      if (documentSnapshot != null) {
        String friendId = documentSnapshot.id;
        //logic to check if the user is already friends or if you want to include only non-friends.
        friends.add(friendId);
      }
    }
    return friends;
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

  //function to accept a friend request
  Future<void> acceptFriendRequest(String senderId, String recipientId) async {
    try {
      // Get sender's username
      String? senderUsername = await getUsernameByUserId(senderId);

      // Get recipient's username
      String? recipientUsername = await getUsernameByUserId(recipientId);

      if (senderUsername != null && recipientUsername != null) {
        // Update sender's friends collection with recipient's username
        DocumentReference senderDoc =
            FirebaseFirestore.instance.collection("users").doc(senderId);
        await senderDoc.update({
          'friends': FieldValue.arrayUnion([recipientUsername])
        });

        // Update recipient's friends collection with sender's username
        DocumentReference recipientDoc =
            FirebaseFirestore.instance.collection("users").doc(recipientId);
        await recipientDoc.update({
          'friends': FieldValue.arrayUnion([senderUsername])
        });

        // Remove the friend request entry
        await FirebaseFirestore.instance
            .collection("friendRequests")
            .where("senderId", isEqualTo: senderId)
            .where("recipientId", isEqualTo: recipientId)
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) {
            doc.reference.delete();
          });
        });

        // TODO: Update local friends list if needed
      } else {
        // Handle the case where usernames are not available
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
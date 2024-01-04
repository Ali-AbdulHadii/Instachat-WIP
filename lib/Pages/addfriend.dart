import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:flutter/material.dart';
import 'package:chatappdemo1/services/database.dart';

class AddFriend extends StatefulWidget {
  const AddFriend({Key? key});

  @override
  State<AddFriend> createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  TextEditingController _friendUsername = TextEditingController();
  List<String> friendRequests = [];

  @override
  void initState() {
    super.initState();
    updateFriendRequestsList();
  }

  String friendUsername = "";
  String senderId = "";
  String recipientId = "";

  Future<void> addFriend() async {
    // Get the entered friend's username
    String friendUsername = _friendUsername.text;

    if (friendUsername.isEmpty) {
      // Show a snack bar if the username is empty
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Enter a valid username"),
      ));
    } else {
      try {
        // Get sender and recipient IDs
        senderId = await SharedPreference().getUserID() as String;
        recipientId = await DatabaseMethods()
            .getUserIdByUsername(friendUsername) as String;

        // Get local friends
        Set<String> localFriends = await SharedPreference().getFriendsList();

        // Check if already friends
        if (localFriends.contains(recipientId)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("You are already friends with $friendUsername"),
          ));
        } else {
          // Check if friend request already sent
          bool requestExists = await DatabaseMethods()
              .checkFriendRequestExist(senderId, recipientId);

          if (requestExists) {
            // Show a snack bar if the request has already been sent
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Friend request has already been sent"),
            ));
            updateFriendRequestsList();
          } else {
            // Send friend request and update the list
            await DatabaseMethods().sendFriendRequest(senderId, recipientId);
            updateFriendRequestsList();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Friend request sent successfully")),
            );
          }
        }
      } catch (t) {
        // Show a snack bar if username not found
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Username not found"),
        ));
      }
    }
  }

  Future<void> updateFriendRequestsList() async {
    try {
      // Fetch friend requests and update the list
      List<String> newFriendRequests =
          await DatabaseMethods().getFriendRequests();
      setState(() {
        friendRequests = newFriendRequests;
      });
    } catch (e) {
      print("Error fetching friend requests: $e");
    }
  }

  void acceptFriendRequest(String friendUsername) async {
    try {
      //get sender and friend IDs
      String? senderId = await SharedPreference().getUserID() as String?;
      String? friendId = await DatabaseMethods()
          .getUserIdByUsername(friendUsername) as String?;

      if (senderId == null || friendId == null) {
        //show a snack bar if unable to get user ID
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to get user ID")),
        );
        return;
      }

      //accept friend request and update local friends list
      await DatabaseMethods().acceptFriendRequest(senderId, friendId);
      Set<String> localFriends = await (SharedPreference().getFriendsList());
      localFriends.add(friendId);
      await SharedPreference().setFriendsList(localFriends.toList());
      updateFriendRequestsList();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend request accepted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting friend request: $e")),
      );
    }
  }

  void rejectFriendRequest(String friendUsername) async {
    try {
      // Get sender and friend IDs
      String senderId = await SharedPreference().getUserID() as String;
      String friendId =
          await DatabaseMethods().getUserIdByUsername(friendUsername) as String;

      // Logic to remove or update the friend request status

      // Update the friend requests list after rejecting
      updateFriendRequestsList();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Friend request rejected"),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error rejecting friend request: $e"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade600,
        title: Text(
          "Add friend",
          style: TextStyle(fontFamily: "Montserrat-R", fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20),
        child: Column(
          children: [
            SizedBox(height: 18),
            Text(
              "Enter Friend's Username",
              style: TextStyle(fontFamily: "Montserrat-R", fontSize: 18),
            ),
            SizedBox(height: 16),
            Container(
              width: MediaQuery.of(context).size.width,
              child: TextField(
                controller: _friendUsername,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
                  contentPadding: EdgeInsets.all(10),
                  hintText: 'Username',
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                addFriend();
              },
              child: Text(
                "Send Friend Request",
                style: TextStyle(fontFamily: "Montserrat-R", fontSize: 18),
              ),
            ),
            SizedBox(height: 40),
            Container(
              child: Text(
                "Friend Requests",
                style: TextStyle(fontFamily: "Montserrat-R", fontSize: 18),
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: friendRequests.length,
              itemBuilder: (context, index) {
                String friendUsername = friendRequests[index];
                return ListTile(
                  title: Text(friendRequests[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          acceptFriendRequest(friendUsername);
                        },
                        icon: Icon(Icons.add_circle_outline),
                      ),
                      IconButton(
                        onPressed: () {
                          rejectFriendRequest(friendUsername);
                        },
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
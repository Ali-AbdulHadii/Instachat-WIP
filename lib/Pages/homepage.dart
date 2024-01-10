import 'package:chatappdemo1/Pages/chat.dart';
import 'package:chatappdemo1/Pages/setting.dart';
import 'package:chatappdemo1/services/database.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chatappdemo1/Pages/addfriend.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({Key? key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //for changing widget state
  bool search = false;
  //storing info for chatroom
  String? myUserName, myProfilePhoto, myEmail, fullName, myId;
  //for search functions
  //this one stores the friends list
  List<String> localFriends = [];
  //this one stores the query search result
  List<String> filteredFriends = [];
  bool isMounted = false;
  //stream var
  Stream? streamChatRooms;
  //chatroomid
  getChatIdbyUsername(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  //widget to get the list of all chats
  Widget ChatRoomsList() {
    return StreamBuilder(
        stream: streamChatRooms,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.data.docs.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    DocumentSnapshot docSnapshot = snapshot.data.docs[index];
                    return ChatRoomListTiles(
                        chatRoomId: docSnapshot.id,
                        lastMessage: docSnapshot["lastMessage"],
                        myUsername: myUserName!,
                        time: docSnapshot["lastMessageSendTs"]);
                  })
              : Center(
                  child: CircularProgressIndicator(),
                );
        });
  }

  @override
  void initState() {
    super.initState();
    //Initialize the state when the widget is created
    isMounted = true;
    onLoad();
  }

  @override
  void dispose() {
    //set isMounted to false when the widget is disposed
    isMounted = false;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This method will be called when dependencies change,
    // including when navigating back to this screen.
    if (isMounted) {
      getSharedPref();
      setState(() {});
    }
  }

  //load user data from shared preferences
  void onLoad() async {
    //gets local data
    await getSharedPref();
    //stores all the chatrooms fetched from forebase database in database methods file
    streamChatRooms = await DatabaseMethods().getChatRooms();
    if (isMounted) {
      initLocalFriends();
    }
    if (isMounted) {
      setState(() {});
    }

    // Add the following code to refresh local friends when navigating back
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (isMounted) {
        initLocalFriends();
        setState(() {});
      }
    });
  }

  //get user data from shared preference
  getSharedPref() async {
    myUserName = await SharedPreference().getUserName() as String;
    myProfilePhoto = await SharedPreference().getUserPhoto() as String;
    myEmail = await SharedPreference().getUserEmail() as String;
    myId = await SharedPreference().getUserID() as String;
    setState(() {});
  }

  void initLocalFriends() async {
    //check if the local friends list is already populated

    //fetch the friends list from Firebase
    List<String> firebaseFriends = await DatabaseMethods().getUserFriends();

    //save the friends list to SharedPreferences
    await SharedPreference().setFriendsList(firebaseFriends);

    //update the localFriends state
    setState(() {
      localFriends = firebaseFriends;
      print('Local friends: $localFriends');
    });
  }

  List<String> filterFriendsList(String searchQuery) {
    List<String> filteredList = localFriends
        .where((friend) =>
            friend.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    print('Search Query: $searchQuery');
    print('Filtered Friends: $filteredList');

    setState(() {
      filteredFriends = filteredList;
    });

    return filteredList;
  }

  List<String> emptyList = [];
  void initialSearch(String value) async {
    setState(() {
      search = true;
    });

    if (value.isEmpty) {
      //set result to empty
      setState(() {
        filteredFriends = emptyList;
      });
    } else {
      //if there's a search query, filter the friends list
      filterFriendsList(value);
    }
  }

  List<String> filterFriends(String name) {
    setState(() {
      filteredFriends = localFriends
          .where((friend) => friend.toLowerCase().contains(name.toLowerCase()))
          .toList();
    });
    return filteredFriends;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber,
              Colors.orange,
              Colors.red,
              Colors.purple,
              Colors.deepPurple.shade700
            ],
          ),
        ),
        child: Column(
          children: [
            //top Row with Search and App Name
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, top: 45),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //search bar when activated
                  search
                      ? Expanded(
                          child: TextField(
                            onChanged: (value) {
                              //search function

                              initialSearch(value);
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search Username',
                              hintStyle: TextStyle(
                                fontFamily: "Montserrat-R",
                                fontSize: 18,
                                color: Colors.black38,
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: "Montserrat-R",
                              fontSize: 18,
                            ),
                          ),
                        )
                      //app Name when not searching
                      : Text(
                          'Instachat',
                          style: TextStyle(
                            fontFamily: 'FuturaLight',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  //search Icon
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            search = !search;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent,
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          child: Icon(
                            Icons.search,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.black,
                          size: 30,
                        ),
                        onSelected: (value) {
                          if (value == 'settings') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => settings(
                                  fullname: fullName,
                                  profileURL: myProfilePhoto,
                                  userName: myUserName,
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value:
                                'settings', // <-- Corrected value to match the one in onSelected
                            child: Text(
                              'Settings',
                              style: TextStyle(
                                  fontSize: 16, fontFamily: "Montserrat-R"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            //container for Chat Entries
            Container(
                margin: EdgeInsets.only(top: 5),
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                width: MediaQuery.of(context).size.width,
                height: search
                    ? MediaQuery.of(context).size.height / 1.19
                    : MediaQuery.of(context).size.height / 1.15,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: search ? buildSearchResultList() : ChatRoomsList()),
          ],
        ),
      ),
      //floating Action Button for Adding Friends
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //navigate to the AddFriend page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddFriend()),
          );
        },
        backgroundColor: Colors.deepPurpleAccent,
        child: Icon(Icons.person_add),
      ),
    );
  }

  //widgets for one chat entry
  Widget buildChatEntry(String username, String chatText, String imagePath,
      String time, int messageCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //user Profile Image
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            imagePath,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 16.0),
        //chat Information
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.0),
            //username
            Text(
              username,
              style: TextStyle(
                fontFamily: 'FuturaLight',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            //chat Text
            Text(
              chatText,
              style: TextStyle(
                fontFamily: 'Montserrat-R',
                fontSize: 18,
                color: Colors.black45,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        Spacer(),
        //time and Message Count
        Column(
          children: [
            Text(time),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.purpleAccent,
                borderRadius: BorderRadius.circular(90),
              ),
              child: Text(
                ' $messageCount ',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildSearchResultList() {
    return ListView.builder(
      padding: EdgeInsets.only(left: 5, right: 5),
      primary: false,
      shrinkWrap: true,
      itemCount: filteredFriends.length,
      itemBuilder: (context, index) {
        String friendName = filteredFriends[index];
        return ListTile(
          title: Text(friendName),
          onTap: () async {
            //handle tapping on the search result, open chat
            var chatId = getChatIdbyUsername(myUserName!, friendName);
            Map<String, dynamic> chatDataMap = {
              "users": [myUserName, friendName]
            };
            await DatabaseMethods().createChatRoom(chatId, chatDataMap);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatSection(
                          userName: friendName,
                          profileURL: DatabaseMethods()
                              .getFriendPhotoURL(friendName)
                              .toString(),
                        )));
          },
        );
      },
    );
  }
}

class ChatRoomListTiles extends StatefulWidget {
  final String lastMessage, chatRoomId, myUsername, time;
  ChatRoomListTiles(
      {required this.chatRoomId,
      required this.lastMessage,
      required this.myUsername,
      required this.time});
  @override
  State<ChatRoomListTiles> createState() => _ChatRoomListState();
}

class _ChatRoomListState extends State<ChatRoomListTiles> {
  String profilePhotoURL = "", username = "", id = "";
  getUserInfo() async {
    try {
      username = widget.chatRoomId
          .replaceAll("_", "")
          .replaceAll(widget.myUsername, "");

      QuerySnapshot querySnapshot =
          await DatabaseMethods().getUserInfo(username.toLowerCase());

      print("Query snapshot size: ${querySnapshot.size}");

      // Check if there are any documents in the query result
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot firstDoc = querySnapshot.docs[0];
        profilePhotoURL = firstDoc.get("Photo") ?? "";
        id = firstDoc.get("id") ?? "";
        username = firstDoc.get("Username") ?? "";
        setState(() {});
      } else {
        // Handle the case where no documents are found
        print("No documents found for user $username");
        // Set default values
        profilePhotoURL =
            "https://www.shutterstock.com/image-vector/default-avatar-profile-icon-social-600nw-1677509740.jpg"; // Provide a default URL or an empty string
        id = "Unknown"; // Provide a default ID or an empty string
        username = "Unknown";
        setState(() {});
      }
    } catch (e) {
      print("Error in getUserInfo: $e");
      // Handle the error as needed
    }
  }

  @override
  void initState() {
    getUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatSection(
                      userName: username,
                      profileURL: profilePhotoURL,
                    )));
      },
      child: Container(
        margin: EdgeInsets.only(left: 5, right: 5, top: 15, bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            profilePhotoURL == ""
                ? ClipRRect(
                    //placeholder
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      "https://www.shutterstock.com/image-vector/default-avatar-profile-icon-social-600nw-1677509740.jpg",
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                :
                //user Profile Image
                ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      profilePhotoURL,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
            SizedBox(width: 16.0),
            //chat Information
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.0),
                //username
                Text(
                  username,
                  style: TextStyle(
                    fontFamily: 'FuturaLight',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                //chat Text
                Container(
                  width: MediaQuery.of(context).size.width / 3,
                  child: Text(
                    widget.lastMessage,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Montserrat-R',
                      fontSize: 18,
                      color: Colors.black45,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            Spacer(),
            //time and Message Count
            Column(
              children: [
                Text(widget.time),
                SizedBox(height: 10),
                //TO DO LIST
                // Container(
                //   padding: EdgeInsets.all(5),
                //   decoration: BoxDecoration(
                //     color: Colors.purpleAccent,
                //     borderRadius: BorderRadius.circular(90),
                //   ),
                //   child: Text(
                //     ' $messageCount ',
                //     style: TextStyle(fontSize: 16),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

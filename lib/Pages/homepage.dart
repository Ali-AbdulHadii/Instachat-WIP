import 'package:chatappdemo1/services/database.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:flutter/material.dart';
import 'package:chatappdemo1/Pages/addfriend.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({Key? key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool search = false;
  String? userName, profilePhoto, email;
  List<String> localFriends = [];
  List<String> filteredFriends = [];
  bool isMounted = false;
  @override
  void initState() {
    super.initState();
    // Initialize the state when the widget is created
    isMounted = true;
    onLoad();
  }

  @override
  void dispose() {
    // Set isMounted to false when the widget is disposed
    isMounted = false;
    super.dispose();
  }

  // Load user data from shared preferences
  void onLoad() async {
    print("Loading data...");
    await getSharedPref();
    if (isMounted) {
      initLocalFriends();
    }
    print("Data loaded successfully!");
    if (isMounted) {
      setState(() {});
    }
  }

  // Get user data from shared preferences
  getSharedPref() async {
    userName = await SharedPreference().getUserName();
    profilePhoto = await SharedPreference().getUserPhoto();
    email = await SharedPreference().getUserEmail();
    setState(() {});
  }

  void initLocalFriends() async {
    print('Loading data...');

    // Fetch the friends list from Firebase
    List<String> firebaseFriends =
        await DatabaseMethods().fetchFriendsFromFirebase();
    print('Friends from Firebase: $firebaseFriends');
    // Save the friends list locally
    await SharedPreference().setFriendsList(firebaseFriends);

    print('Data loaded successfully!');
    print('Local friends: $firebaseFriends');

    // Set the localFriends state
    setState(() {
      localFriends = firebaseFriends;
    });
  }

// Change the return type of getFriendsList to Set<String>
  Future<Set<String>> getFriendsList() async {
    final prefs = await SharedPreferences.getInstance();
    // Return the Set<String> directly
    return prefs.getStringList('friends')?.toSet() ?? {};
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

  void initialSearch(String value) async {
    if (value.length == 0) {
      setState(() {
        localFriends = [];
      });
    }
    setState(() {
      search = true;
    });
    filterFriendsList(value);
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
            colors: [Colors.orange, Colors.red, Colors.deepPurple],
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
              child: search
                  ? buildSearchResultList()
                  : ListView(
                      children: [
                        //chat Entries
                        buildChatEntry('Alio Abdul', 'Hey Saleh',
                            'images/pptest1.jpg', '12:00 PM', 1),
                        SizedBox(height: 10),
                        buildChatEntry('Ahmed', 'Hey Saleh',
                            'images/pptest1.jpg', '10:00 PM', 79),
                        //add more chat entries as needed
                      ],
                    ),
            ),
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
          onTap: () {
            //handle tapping on the search result, open chat.
            print('Tapped on search result: $friendName');
          },
        );
      },
    );
  }
}
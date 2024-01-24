import 'dart:async';
import 'package:chatappdemo1/services/database.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:chatappdemo1/Pages/homepage.dart';

class ChatSection extends StatefulWidget {
  String? userName, profileURL, displayName;
  ChatSection(
      {required this.userName,
      required this.profileURL,
      required this.displayName});

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection> {
  //controller
  TextEditingController _messageController = TextEditingController();
  //storing info
  String? myUsername, myProfilePhoto, myEmail, messageId, chatroomId;
  //stream message
  Stream? messageStream;

  //friends userId, stream friend status
  String? friendUserId, friendStatus = "";
  StreamSubscription<DocumentSnapshot>? friendStatusSubscription;
  void getAndListenFriendStatus() async {
    friendUserId =
        await DatabaseMethods().getUserIdByUsername(widget.userName!);
    friendStatusSubscription =
        DatabaseMethods().userStatusStream(friendUserId!).listen((event) {
      if (event.exists) {
        dynamic data = event.data();
        //check if data is not null and has the status field
        if (data != null && data['status'] != null) {
          setState(() {
            friendStatus = data['status'] as String;
          });
        }
      }
    });
  }

  getSharePrefs() async {
    myUsername = await SharedPreference().getUserName();
    myProfilePhoto = await SharedPreference().getUserPhoto();
    myEmail = await SharedPreference().getUserEmail();
    chatroomId = getChatIdbyUsername(widget.userName!, myUsername!);
  }

  //chatroomid
  getChatIdbyUsername(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  //randomID generator
  String? randomID() {
    DateTime now = DateTime.now();

    String formattedDate = DateFormat('yyMMddkkmm').format(now);

    final String messageId = math.Random().nextInt(10 + 90).toString();
    final DateTime messageTimestamp = DateTime.now();
    String messageDateFormat = DateFormat('h:mma').format(messageTimestamp);
    return (formattedDate + messageId + messageDateFormat);
  }

  Widget chatMessageTile(String message, bool SentByMe) {
    return Row(
      mainAxisAlignment:
          SentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomRight:
                      SentByMe ? Radius.circular(0) : Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft:
                      SentByMe ? Radius.circular(20) : Radius.circular(0),
                ),
                color: SentByMe ? Colors.amber : Colors.orange),
            child: Text(
              message,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "Montserrat-R",
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget chatMessage() {
    return StreamBuilder(
        stream: messageStream,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  padding: EdgeInsets.only(bottom: 90, top: 130),
                  itemCount: snapshot.data.docs.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    DocumentSnapshot docSnapshot = snapshot.data.docs[index];
                    return chatMessageTile(docSnapshot["message"],
                        myUsername == docSnapshot["sentBy"]);
                  })
              : Center(
                  child: CircularProgressIndicator(),
                );
        });
  }

  //get and set msgs
  getAndSetMessage() async {
    messageStream = await DatabaseMethods().getChatroomMessages(chatroomId);
    //await DatabaseMethods().resetUnreadCounter(widget.userName!);
    //setstate
    if (mounted) {
      setState(() {});
    }
  }

  //function to send the message
  addMessage(bool sendIconPressed) {
    if (_messageController.text != "") {
      String message = _messageController.text;
      _messageController.text = "";

      DateTime now = DateTime.now();
      String formattedDate = DateFormat('h:mma').format(now);
      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sentBy": myUsername,
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": myProfilePhoto,
        "isRead": false,
      };
      //generate randomID for msgs
      messageId ??= randomID();
      //call addmessage function from databasemethods.dart
      DatabaseMethods()
          .addMessage(chatroomId!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": message,
          "lastMessageSendTs": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUsername,
          "unreadCounter_$myUsername": FieldValue.increment(1),
        };
        DatabaseMethods()
            .updateLastMessageSent(chatroomId!, lastMessageInfoMap);
        if (sendIconPressed) {
          messageId = null;
        }
      });
    }
  }

  //load user data from shared preferences
  void onLoad() async {
    await getSharePrefs();
    await getAndSetMessage();
    setState(() {});
    getAndListenFriendStatus();
    startHeartbeat(widget.userName!);
  }

  //init state
  @override
  void initState() {
    super.initState();
    onLoad();
    startCrashDetection(widget.userName!);
  }

  @override
  void dispose() {
    friendStatusSubscription?.cancel();
    super.dispose();
  }

  //dummy timer
  Timer timeoutTimer = Timer(Duration(seconds: 0), () {});

  //heatbeat function
  void startHeartbeat(String userName) {
    const Duration heartbeatInterval =
        Duration(seconds: 7); //interval, can be changed as needed

    Timer.periodic(
      heartbeatInterval,
      (timer) async {
        //get the users status
        String? userStatus = await DatabaseMethods().getUserStatus(userName);

        //check if the status is not "" before updating to "online"
        if (userStatus != "" && userStatus!.isNotEmpty) {
          await DatabaseMethods().updateUserStatus(userName, "online");
        }
      },
    );
  }

  //crashDetection mechanisim
  Future<void> startCrashDetection(String userName) async {
    const Duration timeoutDuration =
        Duration(seconds: 10); //timeout, adjusted as needed

    void resetTimeout() async {
      timeoutTimer.cancel();
      timeoutTimer = Timer(timeoutDuration, () async {
        //user has crashed or gone offline
        await DatabaseMethods().updateUserStatus(userName, "");
      });
    }

    resetTimeout(); // Initial reset

    //listen to user status changes
    await DatabaseMethods().userStatusStream(userName).listen((snapshot) {
      //reset the timeout whenever an update is received
      resetTimeout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        //instachat main colors
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
        padding: EdgeInsets.only(top: 50.0),
        child: Stack(
          children: [
            Container(
              //main messages container
              margin: EdgeInsets.only(top: 60.0),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 1.12,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.amber,
                    Colors.orange,
                    Colors.red,
                    Colors.purple,
                    Colors.deepPurple.shade700
                  ]),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5))),
              child: chatMessage(),
            ),
            Padding(
              //top bar for returning, profile picture, and username
              padding: const EdgeInsets.only(left: 10.0, bottom: 50),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    //button
                    children: [
                      Container(
                        padding: EdgeInsets.only(top: 10, left: 5),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Home()));
                          },
                          child: Icon(
                            Icons.arrow_back_ios_new_outlined,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 20.0),
                  Column(children: [
                    Container(
                      child: CircleAvatar(
                        maxRadius: 25,
                        backgroundImage: NetworkImage(widget.profileURL!),
                      ),
                    ),
                  ]),
                  SizedBox(
                    width: 12.0,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName!,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                            fontFamily: "Montserrat-R"),
                      ),
                      Row(
                        children: [
                          Text(
                            widget.displayName!,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                                fontFamily: "Montserrat-R"),
                          ),
                          SizedBox(width: 16),
                          Text(
                            "$friendStatus",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontFamily: "Montserrat-R",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            //the messaging input controller is here
            Container(
              margin: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              alignment: Alignment.bottomCenter,
              child: Material(
                elevation: 1.0,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Send a Message",
                          hintStyle: TextStyle(
                              color: Colors.black,
                              fontFamily: "Montserrat-R",
                              fontSize: 16),
                          suffixIcon: GestureDetector(
                              onTap: () {
                                addMessage(true);
                              },
                              child: Icon(
                                Icons.send_rounded,
                                color: Colors.black,
                              ))),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

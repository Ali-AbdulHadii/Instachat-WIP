import 'package:chatappdemo1/services/database.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:chatappdemo1/Pages/homepage.dart';

class ChatSection extends StatefulWidget {
  String? userName, profileURL;
  ChatSection({required this.userName, required this.profileURL});

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

  //friends userId
  String? friendUserId;

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
  }

  //init state
  @override
  void initState() {
    super.initState();
    onLoad();
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
        padding: EdgeInsets.only(top: 60.0),
        child: Stack(
          children: [
            Container(
              //main messages container
              margin: EdgeInsets.only(top: 50.0),
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
              padding: const EdgeInsets.only(left: 10.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => Home()));
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new_outlined,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 20.0),
                  Container(
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(widget.profileURL!),
                    ),
                  ),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text(
                    widget.userName!,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                        fontFamily: "Montserrat-R"),
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

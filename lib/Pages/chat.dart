import 'package:flutter/material.dart';

class ChatSection extends StatefulWidget {
  const ChatSection({super.key});

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomInset: false,
      backgroundColor: Colors.deepPurple,
      //overflow singlechild scroll maybe
      body: Container(
        //main container
        margin: EdgeInsets.only(top: 50),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              //this is for the profile pic and name, getting back to the home page
              //last seen will be implemented later
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
                  SizedBox(width: 15),
                  //profile image, will be change to network image later on
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'images/pptest1.jpg',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 9),
                  //recipent name
                  Text(
                    'Alio Abdul',
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: 20,
                        fontFamily: 'Monstserrat-R',
                        fontWeight: FontWeight.normal),
                  )
                ],
              ),
            ),
            SizedBox(height: 10),
            //the messaging widget is here
            //how to implement two different msgs?
            Expanded(
              //when scrolling hide the keyboard
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (_) {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: SingleChildScrollView(
                  child: Container(
                    //responsive design here
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 1.15,
                    padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white60,
                    ),
                    child: Column(
                      children: [
                        //messages are here
                        Container(
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width / 2),
                          alignment: Alignment.bottomLeft,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5),
                              bottomLeft: Radius.circular(5),
                              bottomRight: Radius.circular(0),
                            ),
                          ),
                          child: Text(
                            'Hey',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Monsterrat-R',
                                fontSize: 18),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        //sender message
                        Container(
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.only(
                              right: MediaQuery.of(context).size.width / 2),
                          alignment: Alignment.bottomLeft,
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5),
                              bottomLeft: Radius.circular(0),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                          child: Text(
                            'Hey',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Monsterrat-R',
                                fontSize: 18),
                          ),
                        ),
                        Spacer(),
                        //text Input is here
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                          elevation: 5,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 5),
                            padding: EdgeInsets.only(left: 30),
                            decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'kslajgflkjsf',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                          fontSize: 16, color: Colors.white70),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(5),
                                  margin: EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurpleAccent,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

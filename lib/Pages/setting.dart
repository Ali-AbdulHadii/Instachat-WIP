import 'dart:io';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:chatappdemo1/services/database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class settings extends StatefulWidget {
  //const settings({super.key});
  String? userName, profileURL, fullname;
  settings(
      {required this.userName,
      required this.profileURL,
      required this.fullname});

  @override
  State<settings> createState() => _settingsState();
}

class _settingsState extends State<settings> {
  //store the selected image
  File? _image;
  Key circleAvatarKey = GlobalKey();
  //choosing the image and uploading it
  Future _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Show a Snackbar to indicate that the image has been uploaded
      final snackBar = SnackBar(
        content: Text('Image uploaded'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      //upload sleteced image to firebase
      String? profilePhotoURL =
          await DatabaseMethods().uploadUserProfilePhoto(_image!);
      await SharedPreference().setUserPhoto(profilePhotoURL!);
      if (profilePhotoURL != null) {
        // Update the widget's profileURL with the new download URL
        setState(() {
          widget.profileURL = profilePhotoURL;
        });

        // Force a rebuild of the CircleAvatar by creating a new Key
        Key newKey = Key(profilePhotoURL);
        circleAvatarKey = newKey;
        //show snackbar to indicate the image has been uploaded
        final uploadSnackBar = SnackBar(
          content: Text("Image Uploaded"),
          duration: Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(uploadSnackBar);
      } else {
        //hnadle case
        final uploadErrorsnackBar = SnackBar(
          content: Text("Failed to upload image"),
          duration: Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(uploadErrorsnackBar);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Montserrat-R', fontSize: 20),
        ),
        backgroundColor: Colors.amber.shade600,
        centerTitle: true,
      ),
      body: Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(top: 30),
                child: CircleAvatar(
                  key: Key(widget.profileURL ?? ''),
                  radius: 50,
                  backgroundImage: NetworkImage(widget.profileURL!),
                ),
              ),
              SizedBox(height: 10),
              Container(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Edit"),
                          content: Column(
                            children: [
                              ListTile(
                                title: Text('Camera'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                title: Text('Gallery'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.gallery);
                                },
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    'Edit',
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: "Montserrat-R",
                        fontSize: 14,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

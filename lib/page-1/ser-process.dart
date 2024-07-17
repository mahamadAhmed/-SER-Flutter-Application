import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ser/screens/login-page.dart';
import 'package:ser/screens/main-page.dart';
import 'package:ser/utils.dart';
import 'Result.dart';
import 'history.dart';
import 'profile.dart';

class ProcessPage extends StatefulWidget {
  final File audiofile;
  const ProcessPage({Key? key, required this.audiofile}) : super(key: key);

  @override
  State<ProcessPage> createState() => _ProcessPageState();
}

class _ProcessPageState extends State<ProcessPage> {
  int _currentIndex = 1;
  String? finalEmotion = 'N/A';
  List<String> emotionList = [];
  int uploadCounter = 0;
  // ignore: unused_field
  String _filePath = "";

  @override
  void initState() {
    super.initState();
    saveFileLocallyAndSend();
  }

  Future<void> saveFileLocallyAndSend() async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      // Define a unique file path in the application documents directory
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final localFile = File('${directory.path}/saved_audio_$timestamp.wav');
      // Copy the provided audio file to the local file
      await widget.audiofile.copy(localFile.path);

      // Print the file details
      print('File Path: ${localFile.path}');
      print('File Size: ${await localFile.length()} bytes');

      // Update the state to display the file path
      setState(() {
        _filePath = localFile.path;
      });

      // Send the local file to the API
      await sendFileToAPI(localFile);
    } catch (e) {
      print('Error saving file locally: $e');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    }
  }

  Future<void> sendFileToAPI(File file) async {
    String apiUrl = 'https://web-production-76517.up.railway.app/predict';

    try {
      // Check the MIME type of the audio file
      final mimeType = lookupMimeType(file.path);
      print('MIME Type: $mimeType');

      // Create a multipart request
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await file.readAsBytes(),
          filename: 'saved_audio.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        print("API Response: $responseString");

        final data = jsonDecode(responseString);

        if (data.containsKey('final_emotion') &&
            data.containsKey('predicted_emotions')) {
          String finalEmotion = data['final_emotion'];
          List<dynamic> predictedEmotions = data['predicted_emotions'];

          setState(() {
            this.finalEmotion = finalEmotion;
            emotionList = List<String>.from(predictedEmotions);
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(
                finalEmotion: finalEmotion,
                predictedEmotions: emotionList,
              ),
            ),
          );
        } else {
          print('API Response does not contain expected data.');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        }
      } else {
        print(
            'Failed to send file to API. Status Code: ${response.statusCode}');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      }
    } catch (e) {
      print('Error sending file to API: $e');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;
    return Scaffold(
      backgroundColor: Color(0xff06030b),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(17 * fem, 41 * fem, 14 * fem, 35 * fem),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(
                          0 * fem, 0 * fem, 0 * fem, 3 * fem),
                      width: double.infinity,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              margin: EdgeInsets.fromLTRB(
                                  0 * fem, 0 * fem, 121.12 * fem, 0.68 * fem),
                              width: 21.88 * fem,
                              height: 21.32 * fem,
                              child: Icon(
                                Icons.arrow_back,
                                size: 21.88 * fem,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.fromLTRB(
                                0 * fem, 0 * fem, 95 * fem, 1 * fem),
                            child: RichText(
                              text: TextSpan(
                                text: 'SER',
                                style: TextStyle(
                                  fontSize: 24 * ffem,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            child: PopupMenuButton<int>(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 1,
                                  child: ListTile(
                                    leading: Icon(Icons.person),
                                    title: Text('Profile'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 2,
                                  child: ListTile(
                                    leading: Icon(Icons.logout),
                                    title: Text('Logout'),
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 1:
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ProfilePage()));
                                    break;
                                  case 2:
                                    FirebaseAuth.instance.signOut();
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => LoginPage()));
                                    break;
                                }
                              },
                              child: Icon(
                                Icons.account_circle,
                                size: 40 * fem,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 500 * fem,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 50 * fem,
                            top: 100 * fem,
                            child: Align(
                              child: SizedBox(
                                width: 250 * fem,
                                height: 250 * fem,
                                child: Image.asset(
                                  'assets/page-1/images/https-lottiefilescom-animations-processing-dthfbbdo2i.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 50 * fem,
                            top: 350 * fem,
                            child: Container(
                              width: 244 * fem,
                              height: 100 * fem,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    margin: EdgeInsets.fromLTRB(
                                        0 * fem, 0 * fem, 0 * fem, 23 * fem),
                                    child: Text(
                                      'Processing',
                                      textAlign: TextAlign.center,
                                      style: SafeGoogleFont(
                                        'Inter',
                                        fontSize: 32 * ffem,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2125 * ffem / fem,
                                        color: Color(0xff30e8ff),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 15,
                                  ),
                                  Container(
                                    child: LoadingAnimationWidget.waveDots(
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey, width: 0.1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            switch (index) {
              case 0:
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MainPage()));
                break;
              case 1:
                break;
              case 2:
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HistoryPage()));
                break;
              case 3:
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ProfilePage()));
                break;
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic),
              label: 'SER',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: TextStyle(color: Colors.blue),
          unselectedLabelStyle: TextStyle(color: Colors.grey),
          backgroundColor: Colors.white,
          elevation: 5,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 14,
          unselectedFontSize: 14,
        ),
      ),
    );
  }
}

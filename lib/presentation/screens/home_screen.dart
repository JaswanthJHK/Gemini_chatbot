import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
      id: "1",
      firstName: "Gemini",
      profileImage:
          "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 16, 16, 16),
        title: Text("GEMINI"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(
          onPressed: () {
            _sendImage();
          },
          icon: const Icon(
            Icons.image_outlined,
          ),
        ),
      ]),
      messageOptions: const MessageOptions(
        currentUserContainerColor: Color.fromARGB(255, 22, 65, 100),
        currentUserTextColor: Colors.white,
      ),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }

      gemini
          .streamGenerateContent(
        question,
        images: images,
      )
          .listen(
        (event) {
          ChatMessage? lastMessage = messages.firstOrNull;
          if (lastMessage != null && lastMessage.user == geminiUser) {
            lastMessage = messages.removeAt(0);
            String response = event.content?.parts?.fold(
                  "",
                  (previous, current) => "$previous${current.text}",
                ) ??
                " ";
            lastMessage.text += response;
            setState(
              () {
                messages = [lastMessage!, ...messages];
                ;
              },
            );
          } else {
            String response = event.content?.parts?.fold(
                  "",
                  (previous, current) => "$previous${current.text}",
                ) ??
                " ";
            ChatMessage message = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response,
            );
            setState(
              () {
                messages = [message, ...messages];
              },
            );
          }
        },
      );
    } catch (e) {
      print(e);
    }
  }

  void _sendImage() async {
    ImagePicker pickimage = ImagePicker();
    XFile? file = await pickimage.pickImage(
      source: ImageSource.gallery,
    );

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this picture",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: " ",
            type: MediaType.image,
          ),
        ],
      );
      _sendMessage(chatMessage);
    }
  }
}

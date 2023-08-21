import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

// For the testing purposes, you should probably use https://pub.dev/packages/uuid.
String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');

  final List<int> ids = [0];
  final List<String> answers = [""];

  void _makequest() async {
    var url = Uri.parse('http://3.113.1.111/makequest');
    var response = await http.post(
      url,
      body: {
        "token": "token",
      },
    );
    Map<String, dynamic> jsonMap = json.decode(response.body);

    ids[0] = jsonMap["id"];

    print(response.body);
  }

  void _postimage(String token, List<int> bytes) async {
    var url = Uri.parse('http://3.113.1.111/postimage');
    var request = http.MultipartRequest('POST', url);
    final httpImage =
        http.MultipartFile.fromBytes('image', bytes, filename: 'myImage.png');
    request.files.add(httpImage);
    request.fields["id"] = ids[0].toString();
    request.fields["token"] = token;
    final response = await request.send();
    print('Response status: ${response.statusCode}');
  }

  Future<String> _quest(String token, String question) async {
    var url = Uri.parse('http://3.113.1.111/quest');
    var response = await http.post(
      url,
      body: {
        "id": ids[0].toString(),
        "token": token,
        "question": question,
      },
    );
    print('Response status: ${response.statusCode}');
    print(response.body);

    Map<String, dynamic> jsonMap = json.decode(utf8.decode(response.bodyBytes));

    final answer = jsonMap["answer"];

    return answer;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Chat(
          theme: MediaQuery.of(context).platformBrightness == Brightness.light
              ? const DefaultChatTheme()
              : const DarkChatTheme(),
          messages: _messages,
          onAttachmentPressed: _handleAttachmentPressed,
          onMessageTap: _handleMessageTap,
          onPreviewDataFetched: _handlePreviewDataFetched,
          onSendPressed: _handleSendPressed,
          user: _user,
        ),
      );

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(
                height: 17,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'Photo',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      //imageQuality: 70,
      //maxWidth: 1440,
      source: ImageSource.camera,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: randomString(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _makequest();
      _addMessage(message);
      _postimage('token', bytes);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: message.text,
    );
    String question = message.text;

    final answer = await _quest('token', question);
    _addMessage(textMessage);

    print(ids[0]);
    print(answer);

    const machine = types.User(id: 'machine');

    final textAnswer = types.TextMessage(
      author: machine,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: answer.toString(),
    );

    _addMessage(textAnswer);
  }
}

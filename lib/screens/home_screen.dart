import 'package:flutter/material.dart';

import '../chat_message.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<AnimatedListState> _animListKey =
      GlobalKey<AnimatedListState>();
  final TextEditingController _textEditingController = TextEditingController();

  final List<String> _chats = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(220, 255, 255, 255),
        foregroundColor: Colors.blue,
        title: const Text(
          "Image GPT",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedList(
              key: _animListKey,
              reverse: true,
              itemBuilder: _buildItem,
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 15.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    decoration: const InputDecoration(
                        hintText: "What's your question?"),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                IconButton(
                  iconSize: 40,
                  color: Colors.blue,
                  onPressed: () {
                    _handleSubmitted(_textEditingController.text);
                  },
                  icon: const Icon(Icons.send_rounded),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(context, index, animation) {
    return ChatMessage(
      txt: _chats[index],
      animation: animation,
    );
  }

  void _handleSubmitted(String text) {
    _textEditingController.clear();
    _chats.insert(0, text);
    _animListKey.currentState?.insertItem(0);
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ChatScreen(),
  ));
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<String> generateResponse(String messages) async {
    const apiKey = "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";
    const apiUrl = "https://api.openai.com/v1/engines/gpt-3.5-turbo/completions";
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: json.encode({
        "prompt": "You are a chatbot. $messages", // Update the prompt as needed
        "max_tokens": 50, // Adjust the number of tokens as needed
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final text = jsonResponse['choices'][0]['text'];
      return text;
    } else {
      throw Exception('Failed to load response');
    }
  }

  void _sendMessage() async {
    final input = _textController.text;
    if (input.isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: input,
            chatMessageType: ChatMessageType.user,
          ),
        );
        isLoading = true;
      });

      _textController.clear();

      try {
        final response = await generateResponse(input);
        setState(() {
          isLoading = false;
          _messages.add(
            ChatMessage(
              text: response,
              chatMessageType: ChatMessageType.bot,
            ),
          );
        });

        _scrollDown();
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        // Handle error
        print("Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI ChatBot"),
        backgroundColor: const Color.fromRGBO(238, 197, 207, 1.0),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF343541),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];

                  return ChatMessageWidget(
                    text: message.text,
                    chatMessageType: message.chatMessageType,
                  );
                },
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: Colors.white),
                      controller: _textController,
                      decoration: const InputDecoration(
                        fillColor: Color(0xFF444654),
                        filled: true,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (!isLoading)
                    Container(
                      color: const Color(0xFF444654),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Color.fromRGBO(142, 142, 160, 1),
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final ChatMessageType chatMessageType;

  ChatMessage({
    required this.text,
    required this.chatMessageType,
  });
}

enum ChatMessageType {
  user,
  bot,
}

class ChatMessageWidget extends StatelessWidget {
  final String text;
  final ChatMessageType chatMessageType;

  const ChatMessageWidget({
    required this.text,
    required this.chatMessageType,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: chatMessageType == ChatMessageType.user
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: chatMessageType == ChatMessageType.user
                ? Colors.blue
                : Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

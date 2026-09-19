import 'package:flutter/material.dart';
import 'lib/screens/chat_screen.dart';

void main() {
  runApp(const LocalLlamaApp());
}

class LocalLlamaApp extends StatelessWidget {
  const LocalLlamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local Llama',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
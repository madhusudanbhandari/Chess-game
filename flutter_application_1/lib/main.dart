import 'package:flutter/material.dart';
import 'chess_board.dart';

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple Chess',
      home: Scaffold(
        appBar: AppBar(title: const Text('Simple Chess Game')),
        body: Center(child: ChessBoard()),
      ),
    );
  }
}

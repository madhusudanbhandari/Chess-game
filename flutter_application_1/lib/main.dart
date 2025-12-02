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
      title: 'Simple Chess Game',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Simple Chess Game')),
        body: const SafeArea(child: Center(child: ChessBoard())),
      ),
    );
  }
}

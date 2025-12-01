import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChessBoard extends StatefulWidget {
  @override
  _ChessBoardState createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  List<List<String?>> board = List.generate(8, (i) => List.filled(8, null));

  int? selectedRow;
  int? selectedCol;

  // Stack for undo functionality
  List<Map<String, dynamic>> moveHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    // Pawns
    for (int i = 0; i < 8; i++) {
      board[1][i] = 'bp';
      board[6][i] = 'wp';
    }

    // Rooks
    board[0][0] = 'br';
    board[0][7] = 'br';
    board[7][0] = 'wr';
    board[7][7] = 'wr';

    // Knights
    board[0][1] = 'bn';
    board[0][6] = 'bn';
    board[7][1] = 'wn';
    board[7][6] = 'wn';

    // Bishops
    board[0][2] = 'bb';
    board[0][5] = 'bb';
    board[7][2] = 'wb';
    board[7][5] = 'wb';

    // Queens
    board[0][3] = 'bq';
    board[7][3] = 'wq';

    // Kings
    board[0][4] = 'bk';
    board[7][4] = 'wk';
  }

  bool _isLegalMove(
    String piece,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    String color = piece[0]; // 'w' or 'b'
    String type = piece[1]; // 'p','r','n','b','q','k'

    int rowDiff = toRow - fromRow;
    int colDiff = toCol - fromCol;

    // Target piece color
    String? target = board[toRow][toCol];
    if (target != null && target[0] == color) return false;

    switch (type) {
      case 'p': // Pawn
        int dir = color == 'w' ? -1 : 1;
        // Move forward
        if (colDiff == 0 && board[toRow][toCol] == null) {
          if (rowDiff == dir) return true;
          if ((fromRow == 1 && color == 'b' || fromRow == 6 && color == 'w') &&
              rowDiff == 2 * dir &&
              board[fromRow + dir][fromCol] == null)
            return true;
        }
        // Capture
        if ((colDiff == 1 || colDiff == -1) &&
            rowDiff == dir &&
            board[toRow][toCol] != null)
          return true;
        return false;

      case 'r': // Rook
        if (rowDiff == 0 || colDiff == 0) {
          int rStep = rowDiff == 0 ? 0 : rowDiff ~/ rowDiff.abs();
          int cStep = colDiff == 0 ? 0 : colDiff ~/ colDiff.abs();
          int r = fromRow + rStep, c = fromCol + cStep;
          while (r != toRow || c != toCol) {
            if (board[r][c] != null) return false;
            r += rStep;
            c += cStep;
          }
          return true;
        }
        return false;

      case 'n': // Knight
        if ((rowDiff.abs() == 2 && colDiff.abs() == 1) ||
            (rowDiff.abs() == 1 && colDiff.abs() == 2))
          return true;
        return false;

      case 'b': // Bishop
        if (rowDiff.abs() == colDiff.abs()) {
          int rStep = rowDiff ~/ rowDiff.abs();
          int cStep = colDiff ~/ colDiff.abs();
          int r = fromRow + rStep, c = fromCol + cStep;
          while (r != toRow) {
            if (board[r][c] != null) return false;
            r += rStep;
            c += cStep;
          }
          return true;
        }
        return false;

      case 'q': // Queen
        if (rowDiff.abs() == colDiff.abs() || rowDiff == 0 || colDiff == 0) {
          int rStep = rowDiff == 0
              ? 0
              : (rowDiff ~/ (rowDiff.abs() != 0 ? rowDiff.abs() : 1));
          int cStep = colDiff == 0
              ? 0
              : (colDiff ~/ (colDiff.abs() != 0 ? colDiff.abs() : 1));
          int r = fromRow + rStep, c = fromCol + cStep;
          while (r != toRow || c != toCol) {
            if (board[r][c] != null) return false;
            r += rStep;
            c += cStep;
          }
          return true;
        }
        return false;

      case 'k': // King
        if (rowDiff.abs() <= 1 && colDiff.abs() <= 1) return true;
        return false;
    }

    return false;
  }

  void _onTileTap(int row, int col) {
    setState(() {
      if (selectedRow == null && board[row][col] != null) {
        // Select a piece
        selectedRow = row;
        selectedCol = col;
      } else if (selectedRow != null) {
        String? piece = board[selectedRow!][selectedCol!];
        if (piece != null &&
            _isLegalMove(piece, selectedRow!, selectedCol!, row, col)) {
          // Save move for undo
          moveHistory.add({
            'fromRow': selectedRow!,
            'fromCol': selectedCol!,
            'toRow': row,
            'toCol': col,
            'piece': piece,
            'captured': board[row][col],
          });

          // Move piece
          board[row][col] = piece;
          board[selectedRow!][selectedCol!] = null;
        }
        selectedRow = null;
        selectedCol = null;
      }
    });
  }

  void _undoMove() {
    if (moveHistory.isEmpty) return;
    setState(() {
      var lastMove = moveHistory.removeLast();
      board[lastMove['fromRow']][lastMove['fromCol']] = lastMove['piece'];
      board[lastMove['toRow']][lastMove['toCol']] = lastMove['captured'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Board container with max width to prevent overflow
          Container(
            width: 480, // fixed board width
            height: 480, // fixed board height
            child: Column(
              children: List.generate(8, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(8, (col) {
                      bool isSelected =
                          selectedRow == row && selectedCol == col;
                      Color color = (row + col) % 2 == 0
                          ? Colors.brown[300]!
                          : Colors.white;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onTileTap(row, col),
                          child: Container(
                            color: isSelected ? Colors.green : color,
                            child: board[row][col] != null
                                ? Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: SvgPicture.asset(
                                      'assets/images/${board[row][col]}.svg',
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _undoMove, child: const Text('Undo Move')),
        ],
      ),
    );
  }
}

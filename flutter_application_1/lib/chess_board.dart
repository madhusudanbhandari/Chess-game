import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChessBoard extends StatefulWidget {
  const ChessBoard({super.key});

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  // 8x8 board, each entry is null or like 'wp' (white pawn), 'bk' (black king).
  late List<List<String?>> board;

  int? selectedRow;
  int? selectedCol;
  List<List<int>> legalMoves = []; // list of [row, col] for highlighted moves

  // Undo history stack: each item holds move info
  final List<Map<String, dynamic>> moveHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    board = List.generate(8, (_) => List.filled(8, null));

    // Black major pieces (row 0)
    board[0][0] = 'br';
    board[0][1] = 'bn';
    board[0][2] = 'bb';
    board[0][3] = 'bq';
    board[0][4] = 'bk';
    board[0][5] = 'bb';
    board[0][6] = 'bn';
    board[0][7] = 'br';

    // Black pawns (row 1)
    for (int c = 0; c < 8; c++) board[1][c] = 'bp';

    // White pawns (row 6)
    for (int c = 0; c < 8; c++) board[6][c] = 'wp';

    // White major pieces (row 7)
    board[7][0] = 'wr';
    board[7][1] = 'wn';
    board[7][2] = 'wb';
    board[7][3] = 'wq';
    board[7][4] = 'wk';
    board[7][5] = 'wb';
    board[7][6] = 'wn';
    board[7][7] = 'wr';

    selectedRow = null;
    selectedCol = null;
    legalMoves = [];
    moveHistory.clear();
  }

  // Basic legal-move checker (no castling, no en-passant, no check detection, no promotion UI)
  bool _isLegalMove(
    String piece,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    if (fromRow == toRow && fromCol == toCol) return false;
    String color = piece[0]; // 'w' or 'b'
    String type = piece[1]; // 'p','r','n','b','q','k'

    // Can't capture same color
    String? target = board[toRow][toCol];
    if (target != null && target[0] == color) return false;

    int dr = toRow - fromRow;
    int dc = toCol - fromCol;

    switch (type) {
      case 'p': // Pawn
        int dir = color == 'w' ? -1 : 1;
        // Single forward
        if (dc == 0 && dr == dir && board[toRow][toCol] == null) return true;
        // Double forward from starting rank
        if (dc == 0 &&
            dr == 2 * dir &&
            board[toRow][toCol] == null &&
            board[fromRow + dir][fromCol] == null &&
            ((color == 'w' && fromRow == 6) ||
                (color == 'b' && fromRow == 1))) {
          return true;
        }
        // Capture diagonally
        if (dr == dir && (dc == 1 || dc == -1) && board[toRow][toCol] != null)
          return true;
        return false;

      case 'r': // Rook
        if (dr != 0 && dc != 0) return false;
        int stepR = dr == 0 ? 0 : (dr ~/ dr.abs());
        int stepC = dc == 0 ? 0 : (dc ~/ dc.abs());
        int r = fromRow + stepR;
        int c = fromCol + stepC;
        while (r != toRow || c != toCol) {
          if (board[r][c] != null) return false;
          r += stepR;
          c += stepC;
        }
        return true;

      case 'n': // Knight
        if ((dr.abs() == 2 && dc.abs() == 1) ||
            (dr.abs() == 1 && dc.abs() == 2))
          return true;
        return false;

      case 'b': // Bishop
        if (dr.abs() != dc.abs()) return false;
        int stepRb = dr ~/ dr.abs();
        int stepCb = dc ~/ dc.abs();
        int rb = fromRow + stepRb;
        int cb = fromCol + stepCb;
        while (rb != toRow && cb != toCol) {
          if (board[rb][cb] != null) return false;
          rb += stepRb;
          cb += stepCb;
        }
        return true;

      case 'q': // Queen
        if (dr == 0 || dc == 0 || dr.abs() == dc.abs()) {
          int stepRq = dr == 0 ? 0 : (dr ~/ (dr.abs() != 0 ? dr.abs() : 1));
          int stepCq = dc == 0 ? 0 : (dc ~/ (dc.abs() != 0 ? dc.abs() : 1));
          int rq = fromRow + stepRq;
          int cq = fromCol + stepCq;
          while (rq != toRow || cq != toCol) {
            if (board[rq][cq] != null) return false;
            rq += stepRq;
            cq += stepCq;
          }
          return true;
        }
        return false;

      case 'k': // King (one square any direction)
        if (dr.abs() <= 1 && dc.abs() <= 1) return true;
        return false;
    }
    return false;
  }

  // Return all legal moves for a piece at (row,col)
  List<List<int>> _getLegalMoves(String piece, int row, int col) {
    final List<List<int>> moves = [];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (_isLegalMove(piece, row, col, r, c)) moves.add([r, c]);
      }
    }
    return moves;
  }

  void _onTileTap(int row, int col) {
    setState(() {
      // If no selection yet and there's a piece, select it and compute legal moves
      if (selectedRow == null) {
        if (board[row][col] != null) {
          selectedRow = row;
          selectedCol = col;
          legalMoves = _getLegalMoves(board[row][col]!, row, col);
        }
        return;
      }

      // If a piece is selected, check if tapped tile is one of legal moves
      bool tappedIsLegal = legalMoves.any((m) => m[0] == row && m[1] == col);
      if (tappedIsLegal && selectedRow != null && selectedCol != null) {
        final movedPiece = board[selectedRow!][selectedCol!];
        // record for undo
        moveHistory.add({
          'fromRow': selectedRow!,
          'fromCol': selectedCol!,
          'toRow': row,
          'toCol': col,
          'piece': movedPiece,
          'captured': board[row][col],
        });

        // perform move
        board[row][col] = movedPiece;
        board[selectedRow!][selectedCol!] = null;
      }

      // Clear selection & legal moves whether move happened or not
      selectedRow = null;
      selectedCol = null;
      legalMoves = [];
    });
  }

  void _undoMove() {
    if (moveHistory.isEmpty) return;
    setState(() {
      final last = moveHistory.removeLast();
      int fromRow = last['fromRow'];
      int fromCol = last['fromCol'];
      int toRow = last['toRow'];
      int toCol = last['toCol'];
      String piece = last['piece'];
      String? captured = last['captured'];

      board[fromRow][fromCol] = piece;
      board[toRow][toCol] = captured;
      // clear selection/possible moves
      selectedRow = null;
      selectedCol = null;
      legalMoves = [];
    });
  }

  void _resetBoard() {
    setState(() {
      _initializeBoard();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fixed board dimension (Option A)
    const double boardSize = 480.0;
    final double tileSize = boardSize / 8.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Control buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _undoMove, child: const Text('Undo')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _resetBoard,
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
        // Board container
        Center(
          child: FittedBox(
            child: ClipRect(
              child: Container(
                width: 480,
                height: 480,
                child: Column(
                  children: List.generate(8, (row) {
                    return Expanded(
                      child: Row(
                        children: List.generate(8, (col) {
                          bool isSelected =
                              selectedRow == row && selectedCol == col;
                          bool isLegalMoveTile = legalMoves.any(
                            (m) => m[0] == row && m[1] == col,
                          );

                          Color baseColor = (row + col) % 2 == 0
                              ? Colors.brown[300]!
                              : Colors.white;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _onTileTap(row, col),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green
                                      : isLegalMoveTile
                                      ? Colors.yellow.withOpacity(0.6)
                                      : baseColor,
                                ),
                                child: board[row][col] != null
                                    ? Padding(
                                        padding: const EdgeInsets.all(6.0),
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
            ),
          ),
        ),
      ],
    );
  }
}

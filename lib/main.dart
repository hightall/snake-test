import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Snake',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.lightGreenAccent,
        ),
      ),
      home: const SnakeGame(),
    );
  }
}

enum Direction { up, down, left, right }

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int _rows = 20;
  static const int _columns = 20;
  static const Duration _tickDuration = Duration(milliseconds: 180);

  final Random _random = Random();
  final FocusNode _focusNode = FocusNode();

  late List<Point<int>> _snake;
  late Point<int> _food;
  Direction _direction = Direction.right;
  Timer? _timer;
  bool _isGameOver = false;
  int _score = 0;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startGame() {
    _timer?.cancel();
    _snake = <Point<int>>[
      Point<int>(_columns ~/ 2, _rows ~/ 2),
      Point<int>(_columns ~/ 2 - 1, _rows ~/ 2),
      Point<int>(_columns ~/ 2 - 2, _rows ~/ 2),
    ];
    _direction = Direction.right;
    _isGameOver = false;
    _score = 0;
    _generateFood();
    _timer = Timer.periodic(_tickDuration, (_) => _updateGame());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    setState(() {});
  }

  void _generateFood() {
    final Set<Point<int>> occupied = Set<Point<int>>.from(_snake);
    if (occupied.length == _rows * _columns) {
      // The board is full - the player wins.
      _timer?.cancel();
      setState(() {
        _isGameOver = true;
        _highScore = max(_highScore, _score);
      });
      return;
    }
    Point<int> potential;
    do {
      potential = Point<int>(
        _random.nextInt(_columns),
        _random.nextInt(_rows),
      );
    } while (occupied.contains(potential));
    _food = potential;
  }

  void _updateGame() {
    if (_isGameOver) {
      return;
    }
    final Point<int> newHead = _nextHeadPosition();
    if (!_isValidPosition(newHead) || _snake.contains(newHead)) {
      _timer?.cancel();
      setState(() {
        _isGameOver = true;
        _highScore = max(_highScore, _score);
      });
      return;
    }

    setState(() {
      _snake.insert(0, newHead);
      if (newHead == _food) {
        _score += 10;
        _generateFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  Point<int> _nextHeadPosition() {
    final Point<int> head = _snake.first;
    switch (_direction) {
      case Direction.up:
        return Point<int>(head.x, head.y - 1);
      case Direction.down:
        return Point<int>(head.x, head.y + 1);
      case Direction.left:
        return Point<int>(head.x - 1, head.y);
      case Direction.right:
        return Point<int>(head.x + 1, head.y);
    }
  }

  bool _isValidPosition(Point<int> point) {
    return point.x >= 0 &&
        point.x < _columns &&
        point.y >= 0 &&
        point.y < _rows;
  }

  void _changeDirection(Direction newDirection) {
    if (_isGameOver) {
      return;
    }
    if ((newDirection == Direction.left && _direction == Direction.right) ||
        (newDirection == Direction.right && _direction == Direction.left) ||
        (newDirection == Direction.up && _direction == Direction.down) ||
        (newDirection == Direction.down && _direction == Direction.up)) {
      return;
    }
    setState(() {
      _direction = newDirection;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _changeDirection(Direction.up);
        break;
      case LogicalKeyboardKey.arrowDown:
        _changeDirection(Direction.down);
        break;
      case LogicalKeyboardKey.arrowLeft:
        _changeDirection(Direction.left);
        break;
      case LogicalKeyboardKey.arrowRight:
        _changeDirection(Direction.right);
        break;
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (details.delta.dy < -1) {
      _changeDirection(Direction.up);
    } else if (details.delta.dy > 1) {
      _changeDirection(Direction.down);
    }
  }

  void _handleHorizontalDrag(DragUpdateDetails details) {
    if (details.delta.dx < -1) {
      _changeDirection(Direction.left);
    } else if (details.delta.dx > 1) {
      _changeDirection(Direction.right);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Flutter Snake'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Restart',
            onPressed: _startGame,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            _ScoreBoard(score: _score, highScore: _highScore),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double dimension =
                      min(constraints.maxWidth, constraints.maxHeight);
                  return Center(
                    child: SizedBox(
                      width: dimension,
                      height: dimension,
                      child: Focus(
                        focusNode: _focusNode,
                        autofocus: true,
                        onKeyEvent: _handleKeyEvent,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: _handleVerticalDrag,
                          onHorizontalDragUpdate: _handleHorizontalDrag,
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.shade700,
                                    width: 2,
                                  ),
                                ),
                              ),
                              CustomPaint(
                                painter: _BoardPainter(
                                  rows: _rows,
                                  columns: _columns,
                                  snake: List<Point<int>>.unmodifiable(_snake),
                                  food: _food,
                                  isGameOver: _isGameOver,
                                ),
                              ),
                              if (_isGameOver)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const Text(
                                          'Game Over',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Score: $_score',
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(height: 12),
                                        FilledButton.icon(
                                          onPressed: _startGame,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Play again'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Text(
                'Swipe or use arrow keys to control the snake. Eat the food and avoid hitting the walls or yourself!',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startGame,
        icon: const Icon(Icons.play_arrow),
        label: Text(_isGameOver ? 'Restart' : 'Reset'),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.rows,
    required this.columns,
    required this.snake,
    required this.food,
    required this.isGameOver,
  });

  final int rows;
  final int columns;
  final List<Point<int>> snake;
  final Point<int> food;
  final bool isGameOver;

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / columns;
    final double cellHeight = size.height / rows;

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= columns; i++) {
      final double dx = i * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (int i = 0; i <= rows; i++) {
      final double dy = i * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final Paint foodPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    final Rect foodRect = Rect.fromLTWH(
      food.x * cellWidth,
      food.y * cellHeight,
      cellWidth,
      cellHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        foodRect.deflate(cellWidth * 0.15),
        Radius.circular(cellWidth * 0.2),
      ),
      foodPaint,
    );

    final Paint snakeBodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Colors.greenAccent, Colors.green],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final Paint snakeHeadPaint = Paint()
      ..color = Colors.lightGreenAccent.shade700
      ..style = PaintingStyle.fill;

    for (int i = snake.length - 1; i >= 0; i--) {
      final Point<int> segment = snake[i];
      final Rect rect = Rect.fromLTWH(
        segment.x * cellWidth,
        segment.y * cellHeight,
        cellWidth,
        cellHeight,
      ).deflate(cellWidth * 0.15);
      if (i == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cellWidth * 0.25)),
          snakeHeadPaint,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cellWidth * 0.3)),
          snakeBodyPaint,
        );
      }
    }

    if (isGameOver) {
      final Paint overlayPaint = Paint()
        ..color = Colors.black.withOpacity(0.2);
      canvas.drawRect(Offset.zero & size, overlayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return !listEquals(oldDelegate.snake, snake) ||
        oldDelegate.food != food ||
        oldDelegate.isGameOver != isGameOver;
  }
}

class _ScoreBoard extends StatelessWidget {
  const _ScoreBoard({
    required this.score,
    required this.highScore,
  });

  final int score;
  final int highScore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _ScoreTile(
          label: 'Score',
          value: score,
          icon: Icons.restaurant,
          color: Colors.lightGreenAccent,
        ),
        _ScoreTile(
          label: 'Best',
          value: highScore,
          icon: Icons.emoji_events,
          color: Colors.amberAccent,
        ),
      ],
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade850,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Matching Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CardMatchingGame(),
    );
  }
}

// The main widget for the game
class CardMatchingGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Matching Game'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GameState>(context, listen: false).resetGame();
            },
          ),
        ],
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          return Stack(
            children: [
              GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: gameState.cards.length,
                itemBuilder: (context, index) {
                  return CardWidget(
                    isFaceUp: gameState.cards[index].isFaceUp,
                    frontDesign: gameState.cards[index].frontDesign,
                    onTap: () {
                      gameState.selectCard(index);
                    },
                  );
                },
              ),
              if (gameState.isGameWon)
                Center(
                  child: AlertDialog(
                    title: Text('Congratulations!'),
                    content: Text('You matched all the pairs!'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Provider.of<GameState>(context, listen: false)
                              .resetGame();
                          Navigator.of(context).pop();
                        },
                        child: Text('Play Again'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Game State Management
class GameState with ChangeNotifier {
  List<CardModel> cards = [];
  int? firstSelectedIndex;
  bool isGameWon = false;

  GameState() {
    _initializeCards();
  }

  void _initializeCards() {
    isGameWon = false;
    // Create pairs of matching cards and shuffle them
    List<String> frontDesigns = [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'
    ];

    cards = frontDesigns
        .expand((design) => [
              CardModel(frontDesign: design, backDesign: 'assets/card_back.png'),
              CardModel(frontDesign: design, backDesign: 'assets/card_back.png')
            ])
        .toList();
    cards.shuffle();
    firstSelectedIndex = null;
    notifyListeners();
  }

  void selectCard(int index) {
    if (cards[index].isFaceUp || firstSelectedIndex == index) return;

    cards[index].isFaceUp = true;
    notifyListeners();

    if (firstSelectedIndex == null) {
      firstSelectedIndex = index;
    } else {
      if (cards[firstSelectedIndex!].frontDesign == cards[index].frontDesign) {
        firstSelectedIndex = null;
        checkWinCondition();
      } else {
        Future.delayed(Duration(seconds: 1), () {
          cards[firstSelectedIndex!].isFaceUp = false;
          cards[index].isFaceUp = false;
          firstSelectedIndex = null;
          notifyListeners();
        });
      }
    }
  }

  void checkWinCondition() {
    // Check if all cards are face-up
    if (cards.every((card) => card.isFaceUp)) {
      isGameWon = true;
      notifyListeners();
    }
  }

  void resetGame() {
    _initializeCards();
  }
}

// Card Model
class CardModel {
  final String frontDesign;
  final String backDesign;
  bool isFaceUp;

  CardModel({
    required this.frontDesign,
    required this.backDesign,
    this.isFaceUp = false,
  });
}

// Card Widget with flip animation
class CardWidget extends StatelessWidget {
  final bool isFaceUp;
  final String frontDesign;
  final VoidCallback onTap;

  CardWidget({
    required this.isFaceUp,
    required this.frontDesign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final flipAnimation = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: flipAnimation,
            child: child,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.rotationY(isFaceUp ? 0 : pi),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: isFaceUp
            ? Container(
                key: ValueKey(true),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 116, 8, 162),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    frontDesign,
                    style: TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
              )
            : Container(
                key: ValueKey(false),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Image.asset('assets/card_back.png'),
                ),
              ),
      ),
    );
  }
}

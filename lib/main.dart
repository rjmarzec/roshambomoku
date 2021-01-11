import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grid_button/flutter_grid_button.dart';
import 'package:flip_card/flip_card.dart';
import 'dart:math' as math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Roshambomok'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<IconData> _pieceIcons = [
    null,
    Icons.cloud,
    Icons.description,
    Icons.content_cut,
  ];
  final math.Random _randomGen = math.Random();

  // keep track of what piece (if any) is placed on which tile
  List<int> _buttonStates;

  // keep track of scores and who's turn it is currently
  int _turnNumber;
  int _blueScore;
  int _redScore;
  final int maxScore = 2000;

  // variables related to which blue piece is coming up next and the
  //  cards that display the information to the players
  GlobalKey<FlipCardState> _bluePieceController;
  Widget _frontBluePieceCard;
  Widget _backBluePieceCard;
  int _nextBluePiece;

  // variables related to which red piece is coming up next and the
  //  cards that display the information to the players
  GlobalKey<FlipCardState> _redPieceController;
  Widget _frontRedPieceCard;
  Widget _backRedPieceCard;
  int _nextRedPiece;

  _MyHomePageState() {
    _bluePieceController = GlobalKey<FlipCardState>();
    _redPieceController = GlobalKey<FlipCardState>();

    // this is a bit of a poor way to reinitialize variables, but this way
    //  allows me to reset the entire game using setState(), which is nice
    _resetVariables();
  }

  _resetVariables() {
    // reset scores
    _turnNumber = 0;
    _blueScore = 0;
    _redScore = 0;

    // clear the board
    _buttonStates = new List<int>(36);
    for (int i = 0; i < 36; i++) {
      _buttonStates[i] = 0;
    }

    // pick a random piece for red and blue to start off with
    _pickNextPiece(true);
    _pickNextPiece(false);

    // setup the next piece cards for red and blue. the back card we create
    //  here should never to be able to be seen, but we initialize it anyways
    //  to avoid any funkiness
    _frontBluePieceCard = _buildCard(_nextBluePiece, true);
    _backBluePieceCard = _buildCard(_nextBluePiece, true);
    _frontRedPieceCard = _buildCard(_nextRedPiece, false);
    _backRedPieceCard = _buildCard(_nextRedPiece, false);
  }

  Card _buildCard(int iconNumber, bool isBlue) {
    if (isBlue) {
      return Card(
        child: Icon(_pieceIcons[iconNumber]),
        color: Colors.lightBlueAccent[100],
      );
    } else {
      return Card(
        child: Icon(_pieceIcons[iconNumber]),
        color: Colors.redAccent[100],
      );
    }
  }

  Transform _getIcon(int iconNumber) {
    int iconAngle;
    Color iconColor;
    IconData iconImage;

    if (iconNumber > 0) {
      iconAngle = 90;
      iconColor = Colors.blue;
      iconImage = _pieceIcons[iconNumber];
    } else if (iconNumber < 0) {
      iconAngle = -90;
      iconColor = Colors.red;
      iconImage = _pieceIcons[iconNumber * -1];
    } else {
      iconAngle = 0;
      iconColor = Colors.white;
      iconImage = null;
    }

    return Transform.rotate(
      angle: iconAngle * math.pi / 180,
      child: Icon(
        iconImage,
        color: iconColor,
        size: 36.0,
      ),
    );
  }

  List<List<GridButtonItem>> _buildGrid() {
    List<List<GridButtonItem>> grid = [];
    for (int i = 0; i < 6; i++) {
      List<GridButtonItem> gridRow = [];
      for (int j = 0; j < 6; j++) {
        int index = i * 6 + j;
        gridRow.add(GridButtonItem(
          value: index,
          child: Center(
            child: _getIcon(_buttonStates[index]),
          ),
        ));
      }
      grid.add(gridRow);
    }
    return grid;
  }

  void _updateTile(int val) {
    int relativeTurn = _turnNumber % 4;
    // if the turn is a multiple of 2, it is the blue player's turn
    if (relativeTurn % 2 == 0) {
      // if there is no piece there, we can place it without issue. otherwise,
      //  let the player place at that location only if their piece beats the
      //  one already at the spot they are trying to place
      if (_buttonStates[val] == 0 ||
          _buttonStates[val] == -1 && _nextBluePiece == 2 ||
          _buttonStates[val] == -2 && _nextBluePiece == 3 ||
          _buttonStates[val] == -3 && _nextBluePiece == 1) {
        // place the piece at the location pressed and score the board
        setState(() {
          _buttonStates[val] = _nextBluePiece;
          _updateScore();
        });

        // randomize the next piece that will be selected
        _pickNextPiece(true);

        // we need to handle flipping the blue card different based on whether
        //  the front or back is currently shown, and we can which we are on
        //  based on whether or the relative turn timer. if the relative turn
        //  is 0, the front card is showing, so we need to change the back card
        //  to show the next piece when it flips
        if (relativeTurn == 0) {
          _backBluePieceCard = _buildCard(_nextBluePiece, true);
        } else {
          _frontBluePieceCard = _buildCard(_nextBluePiece, true);
        }

        // flip the blue card over
        _bluePieceController.currentState.toggleCard();

        // update the turn number since one was successfully done
        _turnNumber++;
      }
    } else {
      // if there is no piece there, we can place it without issue. otherwise,
      //  let the player place at that location only if their piece beats the
      //  one already at the spot they are trying to place
      if (_buttonStates[val] == 0 ||
          _buttonStates[val] == 1 && _nextRedPiece == 2 ||
          _buttonStates[val] == 2 && _nextRedPiece == 3 ||
          _buttonStates[val] == 3 && _nextRedPiece == 1) {
        // place the piece at the location pressed and score the board
        setState(() {
          _buttonStates[val] = _nextRedPiece * -1;
          _updateScore();
        });

        // randomize the next piece that will be selected
        _pickNextPiece(false);

        // we need to handle flipping the blue card different based on whether
        //  the front or back is currently shown, and we can which we are on
        //  based on whether or the relative turn timer. if the relative turn
        //  is 0, the front card is showing, so we need to change the back card
        //  to show the next piece when it flips
        if (relativeTurn == 1) {
          _backRedPieceCard = _buildCard(_nextRedPiece, false);
        } else {
          _frontRedPieceCard = _buildCard(_nextRedPiece, false);
        }

        // flip the red card over
        _redPieceController.currentState.toggleCard();

        // update the turn number since one was successfully done
        _turnNumber++;
      }
    }
  }

  void _pickNextPiece(bool isBlue) {
    if (isBlue) {
      _nextBluePiece = _randomGen.nextInt(3) + 1;
    } else {
      _nextRedPiece = _randomGen.nextInt(3) + 1;
    }
  }

  void _updateScore() {}

  void _displayHelp() {
    print("help");
    _redPieceController.currentState.toggleCard();
    //_bluePieceController.forward();
  }

  void _displayReset() {
    // this should bring up a box to ask if the players want to reset
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Transform.rotate(
                        angle: math.pi,
                        child: FlipCard(
                          flipOnTouch: false,
                          key: _bluePieceController,
                          direction: FlipDirection.VERTICAL,
                          front: _frontBluePieceCard,
                          back: _backBluePieceCard,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            _resetVariables();
                          });
                        },
                        child: Icon(
                          Icons.refresh,
                          size: 36.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: GridButton(
                  onPressed: (dynamic val) {
                    setState(() {
                      _updateTile(val);
                    });
                  },
                  items: _buildGrid(),
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: FloatingActionButton(
                        onPressed: () => _displayHelp(),
                        child: Icon(
                          Icons.help,
                          size: 36.0,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: FlipCard(
                        flipOnTouch: false,
                        key: _redPieceController,
                        direction: FlipDirection.VERTICAL,
                        front: _frontRedPieceCard,
                        back: _backRedPieceCard,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

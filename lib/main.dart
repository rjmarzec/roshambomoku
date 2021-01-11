import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grid_button/flutter_grid_button.dart';
import 'package:flip_card/flip_card.dart';
import 'package:animated_rotation/animated_rotation.dart';
import 'dart:math' as math;

void main() => runApp(MyApp());

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

  // keep track of what piece (if any) is placed on which tile in terms of
  //  which piece is placed on which tile
  List<int> _buttonStates;

  // keep track of scores and who's turn it is currently
  int _turnNumber;
  int _blueScore;
  int _redScore;
  final int maxScore = 2000;

  // variables related to which blue piece is coming up next and the
  //  cards that display the information to the players
  final GlobalKey<FlipCardState> _bluePieceController =
      GlobalKey<FlipCardState>();
  Widget _frontBluePieceCard;
  Widget _backBluePieceCard;
  int _nextBluePiece;

  // variables related to which red piece is coming up next and the
  //  cards that display the information to the players
  final GlobalKey<FlipCardState> _redPieceController =
      GlobalKey<FlipCardState>();
  Widget _frontRedPieceCard;
  Widget _backRedPieceCard;
  int _nextRedPiece;

  // keep track of the angle the arrow in the background should point
  int _arrowRotationAngle;

  _MyHomePageState() {
    // probably not the best way to initialize variables, but clean enough
    _doReset();
  }

  Widget _buildCard(int iconNumber, bool isBlue) {
    List<Color> cardColors;
    List<double> cardStops;
    double cardAngle;

    if (isBlue) {
      cardColors = [
        Colors.blue[500],
        Colors.blue[500],
        Colors.blueAccent[100],
        Colors.blueAccent[100],
      ];
      cardStops = [0, _blueScore / maxScore, _blueScore / maxScore, 1];
      cardAngle = math.pi / 2;
    } else {
      cardColors = [
        Colors.redAccent[100],
        Colors.redAccent[100],
        Colors.red[500],
        Colors.red[500],
      ];
      cardStops = [0, 1 - _redScore / maxScore, 1 - _redScore / maxScore, 1];
      cardAngle = -math.pi / 2;
    }

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            stops: cardStops,
            begin: FractionalOffset.bottomLeft,
            end: FractionalOffset.topRight,
            colors: cardColors,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Container(
            child: Transform.rotate(
              angle: cardAngle,
              child: Icon(
                _pieceIcons[iconNumber],
                color: Colors.white,
                size: 64.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Transform _buildGridIcon(int iconNumber) {
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
            child: _buildGridIcon(_buttonStates[index]),
          ),
        ));
      }
      grid.add(gridRow);
    }
    return grid;
  }

  void _placePiece(int val) {
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
          _updateScore(true);
        });

        // randomize the next piece that will be selected
        _generateNextPiece(true);

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

        // rotate the pointer to point to the next player's card
        _arrowRotationAngle += 180;
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
          _updateScore(false);
        });

        // randomize the next piece that will be selected
        _generateNextPiece(false);

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

        // rotate the pointer to point to the next player's card
        _arrowRotationAngle += 180;
      }
    }
  }

  void _generateNextPiece(bool isBlue) {
    if (isBlue) {
      _nextBluePiece = _randomGen.nextInt(3) + 1;
    } else {
      _nextRedPiece = _randomGen.nextInt(3) + 1;
    }
  }

  void _updateScore(bool isBlue) {
    if (isBlue) {
      _blueScore += 400;
    } else {
      _redScore += 400;
    }
  }

  void _displayHelp() {
    // bring up a menu explaining how the game is played
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("How to play"),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                "Welcome to Roshambomok, a game where Tic-Tak-Toe meets " +
                    "five-in-a-row.\n\nPlayers take turn placing pieces " +
                    "on empty spots on the board, gaining points each turn" +
                    "based on how long lines of their pieces are.\n",
                textAlign: TextAlign.center,
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.album,
                      color: Colors.red,
                    ),
                    Icon(Icons.cloud),
                    Icon(Icons.description),
                    Icon(Icons.content_cut),
                    Icon(
                      Icons.album,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.arrow_downward),
                  ],
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.album,
                      color: Colors.blue,
                    ),
                    Icon(Icons.content_cut),
                    Icon(Icons.cloud),
                    Icon(Icons.description),
                    Icon(
                      Icons.album,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
              Text(
                "\nHowever, if your piece beats their's in rock-paper-" +
                    "scissors, you can replace their piece as well.\n\nCan " +
                    "you outsmart your opponent to reach 2000 points first?" +
                    "\n\nGood luck!",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text("Ok"),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  void _displayReset() {
    // ask the player if they want to reset the game and reset if necessary
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Restart the game?"),
        actions: <Widget>[
          FlatButton(
            child: Text("No"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          FlatButton(
            child: Text("Yes"),
            onPressed: () {
              setState(() {
                // flip the cards back to showing the front putting this code
                //  block into doReset() breaks the app on run
                if (!_bluePieceController.currentState.isFront) {
                  _bluePieceController.currentState.toggleCard();
                }
                if (!_redPieceController.currentState.isFront) {
                  _redPieceController.currentState.toggleCard();
                }
                _doReset();
              });
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  void _doReset() {
    // reset scores
    _turnNumber = 0;
    _blueScore = 0;
    _redScore = 0;

    // TEMPORARY FOR CHECKING WORKING GRADIENTS
    _blueScore = 200;
    _redScore = 0;

    // clear the board
    _buttonStates = new List<int>(36);
    for (int i = 0; i < 36; i++) {
      _buttonStates[i] = 0;
    }

    // pick a random piece for red and blue to start off with
    _generateNextPiece(true);
    _generateNextPiece(false);

    // setup the next piece cards for red and blue. the back card we create
    //  here should never to be able to be seen, but we initialize it anyways
    //  to avoid any funkiness
    _frontBluePieceCard = _buildCard(_nextBluePiece, true);
    _backBluePieceCard = _buildCard(_nextBluePiece, true);
    _frontRedPieceCard = _buildCard(_nextRedPiece, false);
    _backRedPieceCard = _buildCard(_nextRedPiece, false);

    // reset the rotation of arrow in the background
    _arrowRotationAngle = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: <Widget>[
          _buildBackground(),
          _buildScoreText(),
          _buildPlayArea(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Center(
      child: Transform.rotate(
        angle: -math.pi / 12,
        child: AnimatedRotation(
          angle: _arrowRotationAngle,
          child: Container(
            child: Icon(
              Icons.arrow_upward,
              size: 256,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreText() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Center(
              child: Transform.rotate(
                angle: math.pi / 2,
                child: Text(
                  _blueScore.toString(),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Transform.rotate(
                angle: -math.pi / 2,
                child: Text(
                  _redScore.toString(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayArea() {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Container(),
              ),
              Expanded(
                flex: 6,
                child: Transform.rotate(
                  angle: 0,
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
                flex: 3,
                child: FloatingActionButton(
                  onPressed: () => _displayReset(),
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
                _placePiece(val);
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
                flex: 3,
                child: FloatingActionButton(
                  onPressed: () => _displayHelp(),
                  child: Icon(
                    Icons.help,
                    size: 36.0,
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Transform.rotate(
                  angle: 0,
                  child: FlipCard(
                    flipOnTouch: false,
                    key: _redPieceController,
                    direction: FlipDirection.VERTICAL,
                    front: _frontRedPieceCard,
                    back: _backRedPieceCard,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

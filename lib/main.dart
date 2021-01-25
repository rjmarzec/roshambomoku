import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grid_button/flutter_grid_button.dart';
import 'package:flip_card/flip_card.dart';
import 'package:animated_rotation/animated_rotation.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roshambomoku',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Roshambomoku'),
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
  // stores the icons that represent rock, paper, and scissors
  final List<IconData> _pieceIcons = [
    null,
    Icons.cloud,
    Icons.description,
    Icons.content_cut,
  ];

  // random generator for picking the next piece each player gets
  final math.Random _randomGen = math.Random();

  // length of the grid
  final int _gridLength = 6;

  // keep track of what piece (if any) is placed on which tile in terms of
  //  which piece is placed on which tile
  List<int> _buttonStates;

  // keep track of scores and who's turn it is currently
  int _turnNumber;
  int _blueScore;
  int _blueScoredLastRound;
  bool _blueWon;
  int _redScore;
  int _redScoredLastRound;
  bool _redWon;
  final int maxScore = 2000;

  // variables related to which blue piece is coming up next and the
  //  cards that display the information to the players
  final GlobalKey<FlipCardState> _bluePieceController =
      GlobalKey<FlipCardState>();
  Widget _frontBluePieceCard;
  Widget _backBluePieceCard;
  List<int> _bluePieceBucket;
  int _blueBucketIndex;
  int _nextBluePiece;

  // variables related to which red piece is coming up next and the
  //  cards that display the information to the players
  final GlobalKey<FlipCardState> _redPieceController =
      GlobalKey<FlipCardState>();
  Widget _frontRedPieceCard;
  Widget _backRedPieceCard;
  List<int> _redPieceBucket;
  int _redBucketIndex;
  int _nextRedPiece;

  // keep track of the angle the arrow in the background should point
  int _arrowRotationAngle;

  _MyHomePageState() {
    // probably not the best way to initialize variables, but clean enough
    _doReset();
  }

  void _doReset() {
    // reset scores
    _turnNumber = 0;
    _blueScore = 0;
    _blueWon = false;
    _blueScoredLastRound = 0;
    _redScore = 150;
    _redWon = false;
    _redScoredLastRound = 0;

    // clear the board
    _buttonStates = new List<int>(36);
    for (int i = 0; i < _gridLength * _gridLength; i++) {
      _buttonStates[i] = 0;
    }

    // initialize the piece buckets
    _bluePieceBucket = [1, 1, 2, 2, 3, 3];
    _redPieceBucket = [1, 1, 2, 2, 3, 3];
    _blueBucketIndex = 0;
    _redBucketIndex = 0;
    _bluePieceBucket.shuffle(_randomGen);
    _redPieceBucket.shuffle(_randomGen);

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

  Widget _buildCard(int iconNumber, bool isBlue) {
    List<Color> cardColors;
    List<double> cardStops;
    int cardIconTurns;

    if (isBlue) {
      cardColors = [
        Colors.blue,
        Colors.blue,
        Colors.blueAccent[700],
        Colors.blueAccent[700],
        Colors.blueAccent[100],
        Colors.blueAccent[100],
      ];
      cardStops = [
        0,
        (_blueScore - _blueScoredLastRound) / maxScore,
        (_blueScore - _blueScoredLastRound) / maxScore,
        _blueScore / maxScore,
        _blueScore / maxScore,
        1
      ];
      cardIconTurns = 1;
    } else {
      cardColors = [
        Colors.red[200],
        Colors.red[200],
        Colors.redAccent[700],
        Colors.redAccent[700],
        Colors.red,
        Colors.red,
      ];
      cardStops = [
        0,
        1 - _redScore / maxScore,
        1 - _redScore / maxScore,
        1 - (_redScore - _redScoredLastRound) / maxScore,
        1 - (_redScore - _redScoredLastRound) / maxScore,
        1
      ];
      cardIconTurns = -1;
    }

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            stops: cardStops,
            begin: FractionalOffset.centerLeft,
            end: FractionalOffset.centerRight,
            colors: cardColors,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: RotatedBox(
                quarterTurns: cardIconTurns,
                child: Icon(
                  _pieceIcons[iconNumber],
                  color: Colors.white,
                  size: 64.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridIcon(int iconNumber) {
    int iconRotationTurns;
    Color iconColor;
    IconData iconImage;

    if (iconNumber > 0) {
      iconRotationTurns = 1;
      iconColor = Colors.blue;
      iconImage = _pieceIcons[iconNumber];
    } else if (iconNumber < 0) {
      iconRotationTurns = -1;
      iconColor = Colors.red;
      iconImage = _pieceIcons[iconNumber * -1];
    } else {
      iconRotationTurns = 0;
      iconColor = Colors.white;
      iconImage = null;
    }

    return RotatedBox(
      quarterTurns: iconRotationTurns,
      child: Icon(
        iconImage,
        color: iconColor,
        size: 36.0,
      ),
    );
  }

  List<List<GridButtonItem>> _buildGrid() {
    List<List<GridButtonItem>> grid = [];
    for (int i = 0; i < _gridLength; i++) {
      List<GridButtonItem> gridRow = [];
      for (int j = 0; j < _gridLength; j++) {
        int index = i * _gridLength + j;

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
      _nextBluePiece = _bluePieceBucket[_blueBucketIndex];
      _blueBucketIndex++;
      if (_blueBucketIndex >= 3) {
        _bluePieceBucket[0] = 1;
        _bluePieceBucket[1] = 2;
        _bluePieceBucket[2] = 3;
        _blueBucketIndex = 0;
        _bluePieceBucket.shuffle(_randomGen);
      }
    } else {
      _nextRedPiece = _redPieceBucket[_redBucketIndex];
      _redBucketIndex++;
      if (_redBucketIndex >= 3) {
        _redPieceBucket[0] = 1;
        _redPieceBucket[1] = 2;
        _redPieceBucket[2] = 3;
        _redBucketIndex = 0;
        _redPieceBucket.shuffle(_randomGen);
      }
    }
  }

  void _updateScore(bool isBlue) {
    // a 2D boolean array where each entry is true only if isBlue is true
    List<List<bool>> scoringArray = _convertPiecesTo2DArray(isBlue);

    // keep track of the length of chains of pieces, where the index # is the
    //  length of the chain
    List<int> chainCount = [0, 0, 0, 0, 0, 0, 0];

    // first, count horizontal and vertical chains
    for (int i = 0; i < _gridLength; i++) {
      int currentHorizontalChainLength = 0;
      int currentVerticalChainLength = 0;
      for (int j = 0; j < _gridLength; j++) {
        // is our horizontal chain continuing?
        if (scoringArray[i][j]) {
          // if yes, add onto the length of the chain
          currentHorizontalChainLength++;
        } else {
          // if no, reset the chain and note that we counted it
          chainCount[currentHorizontalChainLength]++;
          currentHorizontalChainLength = 0;
        }
        // is our vertical chain continuing?
        if (scoringArray[j][i]) {
          // if yes, add onto the length of the chain
          currentVerticalChainLength++;
        } else {
          // if no, reset the chain and note that we counted it
          chainCount[currentVerticalChainLength]++;
          currentVerticalChainLength = 0;
        }
      }
      // count the length of the chains we ended out on before resetting and
      //  moving on to the next row/column
      chainCount[currentHorizontalChainLength]++;
      chainCount[currentVerticalChainLength]++;
    }

    // create a second scoring array to track the second diagonal
    List<List<bool>> scoringArray2 = _convertPiecesTo2DArray(isBlue);

    // setup the diagonals to get counted by shifting the rows over such that
    //  the diagonals are just the values in each column. probably less
    //  efficient than computing looping weirdly over the array, but this is
    //  easier to implement without running into issues
    for (int i = 0; i < _gridLength; i++) {
      for (int j = 0; j < _gridLength - 1 - i; j++) {
        scoringArray[i].insert(0, false);
        scoringArray2[i].add(false);
      }
      for (int j = i; j > 0; j--) {
        scoringArray[i].add(false);
        scoringArray2[i].insert(0, false);
      }
    }

    // now count the diagonal chains by counting the horizontals of the shifted
    //  diagonal arrays
    // first, count horizontal and vertical chains
    for (int i = 0; i < _gridLength * 2 - 1; i++) {
      int currentTopLeftChainLength = 0;
      int currentTopRightChainLength = 0;
      for (int j = 0; j < _gridLength; j++) {
        // is our top-left to bottom-right chain continuing?
        if (scoringArray[j][i]) {
          // if yes, add onto the length of the chain
          currentTopLeftChainLength++;
        } else {
          // if no, reset the chain and note that we counted it
          chainCount[currentTopLeftChainLength]++;
          currentTopLeftChainLength = 0;
        }
        // is our top-right to bottom-left chain continuing?
        if (scoringArray2[j][i]) {
          // if yes, add onto the length of the chain
          currentTopRightChainLength++;
        } else {
          // if no, reset the chain and note that we counted it
          chainCount[currentTopRightChainLength]++;
          currentTopRightChainLength = 0;
        }
      }
      // count the length of the chains we ended out on before resetting and
      //  moving on to the next row/column
      chainCount[currentTopLeftChainLength]++;
      chainCount[currentTopRightChainLength]++;
    }

    // now that we calculated the total number of longest chains on the board
    //  for one players, gives them points based on the number and length
    //  of the chains. points go as follows: 5 for 2 chains, 20 for 3 chains,
    //  80 for 4 chains, 240 for 5 chains, and 960 for 6 chains.
    int totalPointsEarned = chainCount[2] * 10;
    totalPointsEarned += chainCount[3] * 40;
    totalPointsEarned += chainCount[4] * 160;
    totalPointsEarned += chainCount[5] * 480;
    totalPointsEarned += chainCount[6] * 1920;

    if (isBlue) {
      _blueScore += totalPointsEarned;
      _blueScoredLastRound = totalPointsEarned;
      if (_blueScore >= maxScore) {
        _blueWon = true;
      }
    } else {
      _redScore += totalPointsEarned;
      _redScoredLastRound = totalPointsEarned;
      if (_redScore >= maxScore) {
        _redWon = true;
      }
    }
  }

  List<List<bool>> _convertPiecesTo2DArray(bool isBlue) {
    List<List<bool>> returnArray = [];

    for (int i = 0; i < _gridLength; i++) {
      List<bool> currentColumn = [];
      for (int j = 0; j < _gridLength; j++) {
        if (isBlue) {
          currentColumn.add(_buttonStates[i * _gridLength + j] > 0);
        } else {
          currentColumn.add(_buttonStates[i * _gridLength + j] < 0);
        }
      }
      returnArray.add(currentColumn);
    }
    return returnArray;
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
                "Welcome to Roshambomoku, a game where rock-paper-scissors " +
                    "meets five-in-a-row.\n\nPlayers take turn placing " +
                    "pieces on empty spots on the board, gaining points each " +
                    "after placing based on number and length of lines of " +
                    "pieces they have on the borad.\n",
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
                    "scissors, you can replace their piece instead of going " +
                    "on an empty space.\n\nCan you outsmart your opponent to " +
                    "reach " +
                    maxScore.toString() +
                    " points first?" +
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

  @override
  Widget build(BuildContext context) {
    //SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            _buildBackground(),
            _buildPlayArea(),
            _buildVictoryScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Center(
      child: Transform.rotate(
        angle: -math.pi / 16,
        child: AnimatedRotation(
          duration: Duration(
            milliseconds: 400,
          ),
          angle: _arrowRotationAngle,
          child: Container(
            child: Icon(
              Icons.navigation,
              size: 256,
              color: Colors.grey[300],
            ),
          ),
        ),
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
                child: FlipCard(
                  flipOnTouch: false,
                  key: _bluePieceController,
                  direction: FlipDirection.VERTICAL,
                  front: _frontBluePieceCard,
                  back: _backBluePieceCard,
                ),
              ),
              Expanded(
                flex: 3,
                child: FloatingActionButton(
                  backgroundColor: Colors.deepPurpleAccent,
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
                if (!_blueWon && !_redWon) _placePiece(val);
              });
            },
            items: _buildGrid(),
            borderWidth: 2.0,
            borderColor: Colors.grey[700],
            hideSurroundingBorder: true,
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: FloatingActionButton(
                  backgroundColor: Colors.deepPurpleAccent,
                  onPressed: () => _displayHelp(),
                  child: Icon(
                    Icons.help,
                    size: 36.0,
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: FlipCard(
                  flipOnTouch: false,
                  key: _redPieceController,
                  direction: FlipDirection.VERTICAL,
                  front: _frontRedPieceCard,
                  back: _backRedPieceCard,
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

  Widget _buildVictoryScreen() {
    String victoryText;
    Color victoryTextColor;

    if (_blueWon) {
      victoryText = "Blue Wins!";
      victoryTextColor = Colors.blue;
    } else if (_redWon) {
      victoryText = "Red Wins!";
      victoryTextColor = Colors.red;
    }

    if (_blueWon || _redWon) {
      Widget victoryCard = Row(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    victoryText,
                    style: TextStyle(
                      color: victoryTextColor,
                      fontSize: 64.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Center(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: victoryCard,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(),
            ),
            Expanded(
              child: Center(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: victoryCard,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_grid_button/flutter_grid_button.dart';
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
  List<int> _buttonStates;

  _MyHomePageState() {
    _buttonStates = new List<int>(49);
    for (int i = 0; i < 49; i++) {
      _buttonStates[i] = 0;
    }
  }

  List<List<GridButtonItem>> _buildGrid() {
    List<List<GridButtonItem>> grid = [];
    for (int i = 0; i < 7; i++) {
      List<GridButtonItem> gridRow = [];
      for (int j = 0; j < 7; j++) {
        int index = i * 7 + j;
        gridRow.add(GridButtonItem(
          value: index,
          child: _getIcon(_buttonStates[index]),
        ));
      }
      grid.add(gridRow);
    }
    return grid;
  }

  void _updateTile(int val) {
    _buttonStates[val] = 1;
  }

  Transform _getIcon(int iconNumber) {
    int iconAngle;
    Color iconColor;
    IconData iconImage;

    List<IconData> icons = [
      Icons.cloud,
      Icons.description,
      Icons.content_cut,
    ];

    if (iconNumber > 0) {
      iconAngle = 90;
      iconColor = Colors.blue;
      iconImage = icons[iconNumber];
    } else if (iconNumber < 0) {
      iconAngle = -90;
      iconColor = Colors.red;
      iconImage = icons[iconNumber * -1];
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GridButton(
        onPressed: (dynamic val) {
          setState(() {
            _updateTile(val);
          });
        },
        items: _buildGrid(),
      ),
    );
  }
}

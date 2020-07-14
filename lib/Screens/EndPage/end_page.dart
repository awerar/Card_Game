import 'package:new_card_game/Models/game_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EndPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameModel>(
      builder: (context, gameModel, child) => Scaffold(
        appBar: AppBar(title: Text("${gameModel.players.firstWhere((element) => element.hand.length == 0).name} has emptied their hand!"), centerTitle: true, automaticallyImplyLeading: false,),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: <Widget>[
              _buildList(gameModel, context),
              Align(
                alignment: Alignment.bottomCenter,
                child: RaisedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: Text("Back to menu"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(GameModel gameModel, BuildContext context) {
    List<Widget> elements = gameModel.players.map((p) => Card(child: ListTile(title: Text(p.name), subtitle: Text("Points: ${p.hand.map((e) => e.value).fold(0, (a, b) => a + b) + (gameModel.players.indexOf(p) == gameModel.penaltyPlayer ? 50 : 0)}"),)) as Widget).toList();
    for(int i = 1; i < elements.length; i += 2) {
      elements.insert(i, Divider());
    }

    return ListView(children: elements, shrinkWrap: true);
  }
}

import 'dart:math';

import 'package:new_card_game/Models/card_model.dart';
import 'package:new_card_game/Models/game_model.dart';
import 'package:new_card_game/Models/player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WaitPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameModel>(
      builder: (context, gameModel, child) => Scaffold(
          appBar: AppBar(title: Text("Waiting for game to start"), centerTitle: true,),
          floatingActionButton: !gameModel.you.isOwner ? null : FloatingActionButton.extended(
            onPressed: () => _startGame(gameModel),
            icon: Icon(Icons.play_arrow),
            label: Text("Begin"),
          ),
          body: Padding(
            padding: EdgeInsets.only(top: 15),
            child: Column(
              children: <Widget>[
                Text("ID: ${gameModel.gameDocument.documentID}"),
                SizedBox(height: 15,),
                Text("People in game", style: Theme.of(context).textTheme.headline6,),
                Divider(),
                _buildPeopleList(gameModel, context),
              ],
            ),
          )
      ),
    );
  }
  
  Widget _buildPeopleList(GameModel gameModel, BuildContext context) {
    List<Widget> elements = gameModel.players.map((player) => _buildElement(player, gameModel.you, context)).toList();
    for(int i = 1; i < elements.length; i += 2) {
      elements.insert(i, Divider());
    }

    return Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), child: ListView(children: elements, shrinkWrap: true,));
  }

  Widget _buildElement(Player player, Player you, BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(player.name + (player == you ? " (You)" : "")),
        subtitle: Text((player.isOwner ? "Owner" : ""), style: Theme.of(context).textTheme.subtitle1.copyWith(inherit: true, color: Theme.of(context).colorScheme.secondary,),)
      ),
    );
  }

  void _startGame(GameModel gameModel) {
    List<CardModel> deck = CardModel.generateDeck();
    List<List<CardModel>> newHands = gameModel.players.map((e) => <CardModel>[]).toList(growable: false);

    Random rand = Random();
    for(int i = 0; deck.length > 0; i = (i + 1) % gameModel.players.length) {
      int r = rand.nextInt(deck.length);
      newHands[i].add(deck[r]);
      deck.removeAt(r);
    }

    for(int i = 0; i < gameModel.players.length; i ++) {
      gameModel.updateHand(gameModel.players[i], newHands[i]);
    }

    gameModel.begin();
  }
}

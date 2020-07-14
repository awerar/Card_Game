import 'dart:io';
import 'dart:math';

import 'package:new_card_game/Models/card_model.dart';
import 'package:new_card_game/Models/game_model.dart';
import 'package:new_card_game/Models/player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

class BoxGamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameModel>(builder: (context, gameModel, child) {
      return Scaffold(
        floatingActionButton: gameModel.yourTurn ? (!gameModel.hasMoved ? (gameModel.you.hand.where((card) => gameModel.canPlaceCard(card)).length == 0 ? FloatingActionButton.extended(onPressed: () => gameModel.takePenalty(gameModel.you), label: Builder(builder: (context) => Text("Take Penalty", style: DefaultTextStyle.of(context).style.copyWith(color: Theme.of(context).colorScheme.onError),)), backgroundColor: Theme.of(context).colorScheme.error,) : null) : FloatingActionButton.extended(onPressed: () => gameModel.finishTurn(), label: Text("Finish turn"),)) : null,
        body: Padding(
          padding: EdgeInsets.only(top: 45, left: 15, right: 15, bottom: 20),
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: IntrinsicWidth(
                  child: Column(
                    children: <Widget>[
                      Text(
                        "Players",
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      Divider(),
                      _buildPlayerIndicators(gameModel, context)
                    ],
                  ),
                ),
              ),
              if (gameModel.isPlayersTurn(gameModel.you)) Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 140),
                  child: Text("Your turn", style: Theme.of(context).textTheme.headline6,),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.only(top: (150.0 + (gameModel.isPlayersTurn(gameModel.you) ? 25.0 : 0.0))),
                  child: Flex(
                    direction: Axis.vertical,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            _buildDragTargetColumn(CardType.Clubs, gameModel),
                            _buildDragTargetColumn(CardType.Diamonds, gameModel),
                            _buildDragTargetColumn(CardType.Spades, gameModel),
                            _buildDragTargetColumn(CardType.Hearts, gameModel),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: ListView(
                              padding: EdgeInsets.all(0),
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _buildCardColumn(
                                        CardType.Clubs, gameModel, context),
                                    _buildCardColumn(
                                        CardType.Diamonds, gameModel, context),
                                    _buildCardColumn(
                                        CardType.Spades, gameModel, context),
                                    _buildCardColumn(
                                        CardType.Hearts, gameModel, context),
                                  ],
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPlayerIndicators(GameModel gameModel, BuildContext context) {
    List<Widget> indicators = gameModel.players
        .map((player) => _buildPlayerIndicator(player, gameModel, context))
        .toList();

    List<Widget> rows = [];
    for (int i = 0; indicators.length > 0; i++) {
      int remove = min(3, indicators.length);

      List<Widget> row = indicators.getRange(0, remove).toList();
      for (int i = 0; i < row.length; i += 2)
        row.insert(
            i,
            SizedBox(
              width: 10,
            ));

      rows.add(Row(
        children: row,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ));
      indicators.removeRange(0, remove);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildDragTargetColumn(CardType cardType, GameModel gameModel) {
    return Column(
      children: <Widget>[
        _buildDragTarget(2, 7, (card) => true, gameModel, cardType),
        _buildDragTarget(8, 14, (card) => true, gameModel, cardType),
      ],
    );
  }

  Widget _buildDragTarget(int minValue, int maxValue, bool Function(CardModel) valid, GameModel gameModel, CardType cardType) {
    List<CardModel> c = gameModel.placedCards.where((card) => card.type == cardType && card.value >= minValue && card.value <= maxValue).toList();

    return Opacity(
      opacity: c.contains(CardModel(type: cardType, value: 2)) || c.contains(CardModel(type: cardType, value: 14)) ? 0 : 1,
      child: DragTarget<CardModel>(
        builder: (context, candidateData, rejectedData) {
          int i = 0;

          return Stack(
            children: <Widget>[
              _buildEmptyCard(),
            ]..addAll((gameModel.placedCards.where((card) => card.type == cardType && card.value >= minValue && card.value <= maxValue).toList()..addAll(candidateData)).map((card) => Transform.translate(child: _buildCard(card, context, (i++).toDouble() + 2, gameModel), offset: Offset(0, -(i - 1).toDouble() * 3),))),
          );
        },
        onWillAccept: (card) => valid(card) && card.value >= minValue && card.value <= maxValue && gameModel.canPlaceCard(card),
        onAccept: (card) {
          gameModel.removeCardFromHand(gameModel.you, card);
          gameModel.placeCard(card);
          if (gameModel.you.hand.length == 1) gameModel.endGame();
          else if (card.value != 2 && card.value != 14) gameModel.finishTurn();
        },
      ),
    );
  }

  Widget _buildPlayerIndicator(
      Player player, GameModel gameModel, BuildContext context) {
    return Chip(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .error
                  .withAlpha(gameModel.playerHasPenalty(player) ? 255 : 0),
              width: gameModel.playerHasPenalty(player) ? 2 : 0)),
      elevation: 5,
      label: Text(
        player.name + " (${player.hand.length})",
        style: Theme.of(context).textTheme.bodyText2.copyWith(
            inherit: true,
            color: gameModel.isPlayersTurn(player)
                ? Theme.of(context).colorScheme.onSecondary
                : Theme.of(context).colorScheme.onSurface),
      ),
      avatar: player == gameModel.you ? Icon(Icons.person) : null,
      backgroundColor:
          gameModel.isPlayersTurn(player) ? Theme.of(context).colorScheme.secondary : null,
    );
  }

  Widget _buildCardColumn(
      CardType type, GameModel gameModel, BuildContext context) {
    List<CardModel> cards = gameModel.you.hand
        .where((card) => card.type == type)
        .toList(growable: false);
    cards.sort((c1, c2) => c1.value - c2.value);

    return Column(
      children: cards.length > 0 ? cards.map((card) => _buildHandCard(card, context, gameModel)).toList() : [Opacity(child: _buildEmptyCard(), opacity: 0,)],
    );
  }

  Widget _buildCard(CardModel card, BuildContext context, double height, GameModel gameModel) {
    if (card.value == 0 || card.value == 20) return _buildEmptyCard();

    ColorScheme colorScheme = Theme.of(context).colorScheme;
    bool hasBorder = (gameModel.canPlaceCard(card) && !gameModel.placedCards.contains(card)) || gameModel.lastCard == card;
    
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)), side: BorderSide(color: Colors.white.withAlpha(hasBorder ? 255 : 0), width: hasBorder ? 2 : 0)),
      margin: EdgeInsets.all(4),
      child: SizedBox(
          width: 50,
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                CardModel.iconFromType(card.type),
                style: TextStyle(fontSize: 25),
              ),
              Text(
                card.valueToken(),
                style: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .copyWith(inherit: true, color: colorScheme.onPrimary, fontSize: 20),
              ),
            ],
          )),
      color: (card.type == CardType.Hearts || card.type == CardType.Diamonds)
          ? Theme.of(context).colorScheme.error
          : Colors.black,
      elevation: height,
    );
  }

  Widget _buildEmptyCard() {
    return Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        margin: EdgeInsets.all(4),
        child: SizedBox(
          width: 50,
          height: 40,
        )
    );
  }

  Widget _buildHandCard(CardModel card, BuildContext context, GameModel gameModel) {
    return gameModel.currentPlayer == gameModel.players.indexOf(gameModel.you) ? Draggable<CardModel>(
      data: card,
      child: _buildCard(card, context, 1, gameModel),
      feedback: _buildCard(card, context, 15, gameModel),
      childWhenDragging: SizedBox(
        width: 58,
        height: 48,
      ),
      axis: Axis.vertical,
    ) : _buildCard(card, context, 1, gameModel);
  }
}

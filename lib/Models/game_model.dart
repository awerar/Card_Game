import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:new_card_game/Models/player.dart';
import 'package:new_card_game/Screens/BoxGamePage/box_game_page.dart';
import 'package:new_card_game/Screens/EndPage/end_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'card_model.dart';

class GameModel extends ChangeNotifier {
  Player you;
  final DocumentReference gameDocument;
  final Map<String, Player> _players = {};
  final BuildContext context;
  List<CardModel> _placedCards = [];
  bool started = false;
  bool ended = false;
  int currentPlayer;
  int penaltyPlayer = -1;
  bool get yourTurn => isPlayersTurn(you);
  bool hasMoved = false;
  CardModel lastCard;

  List<Player> get players => List.unmodifiable(_players.values);
  List<CardModel> get placedCards => List.unmodifiable(_placedCards);

  StreamSubscription _gameListener;

  GameModel.create(String name, this.context) : gameDocument = Firestore.instance.collection("games").document(_randomString(5)), you = Player(name: name, isOwner: true) {
    _players[you.id] = you;
    _create();
  }

  void _create() async {
    await gameDocument.setData({
      "players": [you.encode()],
      "started": false,
      "ended": false,
      "placed_cards":[]
    });
    _beginListen();
  }

  GameModel.join(String name, String id, this.context) : gameDocument = Firestore.instance.collection("games").document(id), you = Player(name: name, isOwner: false) {
    _players[you.id] = you;
    _join();
  }

  void _join() async {
    await gameDocument.updateData({
      "players": FieldValue.arrayUnion([you.encode()])
    });
    _beginListen();
  }

  void _beginListen() {
    _gameListener = gameDocument.snapshots().listen((snapshot) {
      if (!snapshot.exists ){
        Navigator.of(context).popUntil((route) => route.isFirst);
        _gameListener.cancel();
        return;
      }

      _players.clear();
      for(Player player in (snapshot.data["players"] as List<dynamic>).map((v) => Map<String, dynamic>.from(v)).map((data) => Player.fromData(data: data))) {
        _players[player.id] = player;
      }
      if (snapshot.data.containsKey("current_player")) currentPlayer = snapshot.data["current_player"];
      if (snapshot.data.containsKey("penalty_player")) penaltyPlayer = snapshot.data["penalty_player"];
      if (snapshot.data.containsKey("last_card")) lastCard = CardModel.fromData(data: snapshot.data["last_card"]);
      _placedCards = (snapshot.data["placed_cards"] as List<dynamic>).map((v) => Map<String, dynamic>.from(v)).map((data) => CardModel.fromData(data: data)).toList();

      if (!_players.containsKey(you.id)) {
        Navigator.of(context).pop();
        _gameListener.cancel();
        return;
      } else you = _players[you.id];

      notifyListeners();

      if (snapshot.data["started"] && !started) {
        started = true;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                WillPopScope(
                  child: ChangeNotifierProvider.value(
                    child: BoxGamePage(),
                    value: this,
                  ),
                  onWillPop: () async {
                    return false;
                  },
                )
        ));
      }

      if (snapshot.data["ended"] && !ended) {
        print("ended");
        ended = true;
        Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(value: this, builder: (context, child) => EndPage())
            )
        );
      }
    });
  }

  Future<void> leaveGame() async {
    if (you.isOwner) {
      await gameDocument.delete();
    } else {
      await gameDocument.updateData({
        "players": FieldValue.arrayRemove([you.encode()])
      });
    }
  }

  static Future<bool> idIsValid(String id) async {
    DocumentSnapshot doc = await Firestore.instance.collection("games").document(id).get();
    return doc.exists && !doc.data["started"];
  }

  static String _randomString(int length) {
    var rand = new Random();
    var codeUnits = new List.generate(
        length,
            (index) {
          return rand.nextInt(("Z".codeUnitAt(0) - "A".codeUnitAt(0))) + "A".codeUnitAt(0);
        }
    );

    return new String.fromCharCodes(codeUnits);
  }

  Future<void> _updatePlayers() async {
    await gameDocument.updateData({
      "players":_players.values.map((p) => p.encode()).toList(growable: false)
    });
  }

  Future<void> updateHand(Player player, List<CardModel> newHand) async {
    _players[player.id] = player.copyWithNewHand(newHand: newHand);
    notifyListeners();

    await _updatePlayers();
  }

  Future<void> removeCardFromHand(Player player, CardModel card) async {
    _players[player.id] = player.copyWithNewHand(newHand: player.hand.toList()..remove(card));
    notifyListeners();

    await _updatePlayers();
  }

  void begin() {
    gameDocument.updateData({
      "started": true,
      "current_player": players.indexWhere((player) => player.hand.contains(CardModel(type: CardType.Diamonds, value: 8)))
    });
  }

  void placeCard(CardModel card) {
    List<CardModel> newCards = <CardModel>[card];

    hasMoved = true;
    _placedCards.addAll(newCards);
    notifyListeners();

    gameDocument.updateData({
      "placed_cards":FieldValue.arrayUnion(newCards.map((e) => e.encode()).toList()),
      "last_card": card.encode()
    });
  }

  void finishTurn() {
    currentPlayer++;
    currentPlayer %= players.length;
    hasMoved = false;
    notifyListeners();

    gameDocument.updateData({
      "current_player": currentPlayer
    });
  }

  void takePenalty(Player player) {
    penaltyPlayer = players.indexOf(player);
    currentPlayer++;
    currentPlayer %= players.length;
    hasMoved = false;
    notifyListeners();
    gameDocument.updateData({
      "penalty_player": penaltyPlayer,
      "current_player": currentPlayer
    });
  }

  bool isPlayersTurn(Player player) {
    return players.indexOf(player) == currentPlayer;
  }

  bool playerHasPenalty(Player player) {
    return players.indexOf(player) == penaltyPlayer;
  }

  bool canPlaceCard(CardModel card) {
    return  card.value == 8 || placedCards.contains(CardModel(type: card.type, value: card.value - 1)) || placedCards.contains(CardModel(type: card.type, value: card.value + 1));
  }

  void endGame() async {
    gameDocument.updateData({
      "ended": true
    });
  }
}
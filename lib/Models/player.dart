import 'dart:math';

import 'package:new_card_game/Models/card_model.dart';
import 'package:flutter/material.dart';

class Player {
  final String name;
  final bool isOwner;
  final String id;
  List<CardModel> _hand;

  List<CardModel> get hand => List.unmodifiable(_hand);

  Player.withID({@required this.isOwner, @required this.name, @required this.id, List<CardModel> hand}) {
    if(hand == null) _hand = [];
    else _hand = hand;
  }
  Player({@required this.isOwner, @required this.name, List<CardModel> hand}) : id = _randomString(20) {
    if(hand == null) _hand = [];
    else _hand = hand;
  }

  Player.fromData({@required Map<String, dynamic> data}) :
        name = data["name"],
        isOwner = data["is_owner"],
        id = data["id"],
        _hand = (data["hand"] as List<dynamic>).map((v) => CardModel.fromData(data: Map<String, dynamic>.from(v))).toList();

  bool operator ==(o) => o is Player && o.id == id;

  Map<String, dynamic> encode() {
    return {
      "name": name,
      "is_owner": isOwner,
      "id": id,
      "hand": _hand.map((card) => card.encode()).toList(growable: false),
    };
  }

  @override
  int get hashCode => id.hashCode;

  Player copyWithNewHand({@required List<CardModel> newHand}) {
    return Player.withID(isOwner: isOwner, name: name, id: id, hand: newHand);
  }

  static String _randomString(int length) {
    var rand = new Random();
    var codeUnits = new List.generate(
        length,
            (index){
          return rand.nextInt(33)+89;
        }
    );

    return new String.fromCharCodes(codeUnits);
  }
}
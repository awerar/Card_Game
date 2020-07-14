import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CardModel {
  final CardType type;
  final int value;

  CardModel.fromData({@required Map<String, dynamic> data}) : type = CardType.values[data["type"]], value = data["value"];
  CardModel({@required this.type, @required this.value});

  Map<String, dynamic> encode() {
    return {
      "type": type.index,
      "value": value
    };
  }

  static List<CardModel> generateDeck() {
    List<CardModel> deck = [];
    for(int i = 2; i <= 14; i++) {
      deck.add(CardModel(type: CardType.values[0], value: i));
      deck.add(CardModel(type: CardType.values[1], value: i));
      deck.add(CardModel(type: CardType.values[2], value: i));
      deck.add(CardModel(type: CardType.values[3], value: i));
    }

    return deck;
  }

  @override
  int get hashCode => type.index * 100 + value;

  @override
  bool operator ==(other) {
    return other is CardModel && hashCode == other.hashCode;
  }

  static String iconFromType(CardType type) {
    if (type == CardType.Diamonds) return "\u2662";
    else if (type == CardType.Clubs) return "\u2667";
    else if (type == CardType.Hearts) return "\u2661";
    else return "\u2664";
  }

  String valueToken() {
    if (value <= 10) return value.toString();
    else if (value == 11) return "J";
    else if (value == 12) return "Q";
    else if (value == 13) return "K";
    else return "A";
  }
}

enum CardType {
  Hearts, Spades, Clubs, Diamonds
}
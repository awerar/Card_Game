import 'package:flutter/material.dart';
import 'package:new_card_game/Screens/MainPage/main_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Game',
      theme: ThemeData.dark(),
      home: MainPage(),
    );
  }
}

import 'package:new_card_game/Models/game_model.dart';
import 'package:new_card_game/Screens/WaitPage/wait_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  GlobalKey<FormState> _nameKey = GlobalKey();
  GlobalKey<FormState> _idKey = GlobalKey();
  bool _validID = false;

  String _id, _name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create or join game"),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Form(
                key: _nameKey,
                child: TextFormField(
                  decoration: InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(),
                      filled: true),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  validator: (name) => name.length == 0 ? "Invalid name" : null,
                  onChanged: (name) => _name = name,
                ),
              ),
              SizedBox(
                height: 40,
              ),
              _buildButton(onPress: _createGame, label: "Create game"),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  _buildButton(onPress: _joinGame, label: "Join game"),
                  SizedBox(
                    width: 200,
                    child: Form(
                      key: _idKey,
                      child: TextFormField(
                        textCapitalization: TextCapitalization.characters,
                          validator: (id) => _validID ? null : "Invalid ID",
                          onChanged: (id) {
                            _id = id;
                            GameModel.idIsValid(id).then(
                                (result) => {if (_id == id) _validID = result});
                          },
                          decoration: InputDecoration(
                            labelText: "Game ID",
                            border: OutlineInputBorder(),
                            filled: true,
                          )),
                    ),
                  )
                ],
              ),
              SizedBox(height: 100,),
              Center(child: Text("Grattis Mormor!", style: Theme.of(context).textTheme.headline5.copyWith(inherit: true)))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      {@required void Function() onPress, @required String label}) {
    return RaisedButton(
      onPressed: onPress,
      child: SizedBox(
          height: 50,
          child: Align(
              alignment: Alignment.center,
              child: Text(
                label,
                style: Theme.of(context).textTheme.headline6.copyWith(
                      inherit: true,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ))),
      color: Theme.of(context).colorScheme.primary,
    );
  }

  void _createGame() {
    if (_nameKey.currentState.validate()) {
      _goToWaiting(GameModel.create(_name, context));
    }
  }

  void _joinGame() {
    bool validName = _nameKey.currentState.validate();
    bool validID = _idKey.currentState.validate();
    if (validID && validName) {
      _goToWaiting(GameModel.join(_name, _id, context));
    }
  }

  void _goToWaiting(GameModel gameModel) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return ChangeNotifierProvider.value(
        value: gameModel,
        child: WillPopScope(
          child: WaitPage(),
          onWillPop: () async {
            gameModel.leaveGame();
            return false;
          },
        ),
      );
    }));
  }
}
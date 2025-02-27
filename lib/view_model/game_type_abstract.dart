import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tic_tac_toe/core/constants/field_enum.dart';
import 'package:tic_tac_toe/core/constants/stats_enum.dart';

sealed class GameTypeAbstract extends ChangeNotifier {
  String tableName = '';
  FieldEnum currentValue = FieldEnum.cNenhum;
  StatusEnum currentStatus = StatusEnum.sNothing;
  final List<int> fieldsWin = [];
  final database = FirebaseDatabase.instance.ref();

  final Map<int, FieldEnum> table = {
    1: FieldEnum.cNenhum,
    2: FieldEnum.cNenhum,
    3: FieldEnum.cNenhum,
    4: FieldEnum.cNenhum,
    5: FieldEnum.cNenhum,
    6: FieldEnum.cNenhum,
    7: FieldEnum.cNenhum,
    8: FieldEnum.cNenhum,
    9: FieldEnum.cNenhum,
  };

  void getDados() {
    database.child(tableName).child('currentStatus').onValue.listen((event) {
      currentStatus = StatusEnum.values[int.parse(event.snapshot.value.toString())];
      if ([StatusEnum.sNothing, StatusEnum.sRestart].contains(currentStatus)) {
        table.updateAll((key, value) {
          return value = FieldEnum.cNenhum;
        });
        fieldsWin.clear();
      }
      notifyListeners();
    });

    database.child(tableName).child('currentValue').onValue.listen((event) {
      currentValue = event.snapshot.value.toString() == FieldEnum.cCirculo.name ? FieldEnum.cCruz : FieldEnum.cCirculo;
      notifyListeners();
    });

    database.child(tableName).child('fields').onValue.listen((event) {
      for (var value in event.snapshot.children) {
        if (value.value.toString() == 'X') {
          table[int.parse(value.key.toString())] = FieldEnum.cCruz;
        } else if (value.value.toString() == 'O') {
          table[int.parse(value.key.toString())] = FieldEnum.cCirculo;
        } else {
          table[int.parse(value.key.toString())] = FieldEnum.cNenhum;
        }
      }
      verifyStatusGame();
      notifyListeners();
    });
  }

  void zerarJogo() {
    database.child(tableName).child('currentStatus').set(StatusEnum.sRestart.index);
    database.child(tableName).child('currentStatus').set(StatusEnum.sNothing.index);
    database.child(tableName).child('fields').set('');
  }

  void setCampo(int key) async {}

  String getCampo(int key) {
    return table[key]!.name;
  }

  bool isLast(int key) {
    return false;
  }

  bool condiction(int a, int b, int c) {
    final List first = [table[a], table[b], table[c]];

    if (first.every((element) => element == FieldEnum.cCirculo)) {
      database.child(tableName).child('currentStatus').set(StatusEnum.sCircleWin.index);
      fieldsWin.addAll([a, b, c]);
      return true;
    }
    if (first.every((element) => element == FieldEnum.cCruz)) {
      database.child(tableName).child('currentStatus').set(StatusEnum.sCrossWin.index);
      fieldsWin.addAll([a, b, c]);
      return true;
    }
    return false;
  }

  void verifyStatusGame() {
    condiction(1, 2, 3);
    condiction(4, 5, 6);
    condiction(7, 8, 9);
    condiction(1, 5, 9);
    condiction(3, 5, 7);
    condiction(1, 4, 7);
    condiction(2, 5, 8);
    condiction(3, 6, 9);
  }
}

class GameTypeNormal extends GameTypeAbstract {
  @override
  void setCampo(int key) async {
    database.child(tableName).child('fields').child('$key').set(currentValue.name);
    database.child(tableName).child('currentValue').set(currentValue.name);
  }
}

class GameTypeInfinity extends GameTypeAbstract {
  @override
  void getDados() {
    super.getDados();

    database.child(tableName).child('circleFields').onChildChanged.listen((event) {
      if (event.snapshot.value.toString() == '') {
        circleFields.clear();
      } else if (int.parse(event.snapshot.key.toString()) == 0) {
        circleFields.insert(0, int.parse(event.snapshot.value.toString()));
        if (circleFields.length > 3) {
          circleFields.removeAt(3);
        }
        for (var i = 1; i < circleFields.length; i++) {
          database.child(tableName).child('circleFields').child('$i').set(circleFields[i]);
        }
      }
      notifyListeners();
    });
    database.child(tableName).child('crossFields').onChildChanged.listen((event) {
      if (event.snapshot.value.toString() == '') {
        crossFields.clear();
      } else if (int.parse(event.snapshot.key.toString()) == 0) {
        crossFields.insert(0, int.parse(event.snapshot.value.toString()));
        if (crossFields.length > 3) {
          crossFields.removeAt(3);
        }
        for (var i = 1; i < crossFields.length; i++) {
          database.child(tableName).child('crossFields').child('$i').set(crossFields[i]);
        }
      }
      notifyListeners();
    });
  }

  void limpar() {
    for (var i = 0; i < 3; i++) {
      database.child(tableName).child('crossFields').child('$i').set('');
      database.child(tableName).child('circleFields').child('$i').set('');
    }
  }

  @override
  bool isLast(int key) {
    return (((crossFields.length > 2) && (crossFields[2] == key)) ||
        ((circleFields.length > 2) && (circleFields[2] == key)));
  }

  @override
  void zerarJogo() {
    super.zerarJogo();
    limpar();
  }

  final List<int> crossFields = [];
  final List<int> circleFields = [];

  @override
  void setCampo(int key) async {
    if (currentValue == FieldEnum.cCruz) {
      if (crossFields.length >= 3) {
        database.child(tableName).child('fields').child(crossFields[2].toString()).set('');
      }
      database.child(tableName).child('crossFields').child('0').set(key);
    } else if (currentValue == FieldEnum.cCirculo) {
      if (circleFields.length >= 3) {
        database.child(tableName).child('fields').child(circleFields[2].toString()).set('');
      }
      database.child(tableName).child('circleFields').child('0').set(key);
    }

    database.child(tableName).child('fields').child('$key').set(currentValue.name);
    database.child(tableName).child('currentValue').set(currentValue.name);
  }
}

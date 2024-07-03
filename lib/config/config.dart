import 'package:flutter/material.dart';

class Config {
  // on met les propriétés à static pour pouvoir y avoir accès
  //à distance sans avoir besoin d'instancier la classe
  static final colors = _Color();
}

class _Color {
  final bleuClaire = const Color(0xFF004f71);
  final bleuFonce = const Color(0xFF0a3752);
  final bleuFonce2 = const Color.fromARGB(199, 124, 171, 201);
  final jauneClaire = const Color(0xFFdec33e);
  final jauneFonce = const Color(0xFFffcb05);
  final bar = const Color(0xFF63A1BA);
  final jauneBlanc = const Color.fromARGB(255, 250, 244, 178);
  final vertA = const Color(0xff128760);
  final vertB = const Color(0xff1a5441);
  final bleuA = const Color.fromARGB(221, 18, 136, 233);
  final bleuB = const Color.fromARGB(255, 29, 60, 106);
  // final couleurExa = #2596be;
  //Colors.blueGrey;
  //const Color.fromARGB(217, 99, 161, 186);
  //final couleurPrimaireEnHexa = const Color(0xFFff9500);
  //final couleurTertiaire = const Color.fromARGB(255, 242, 255, 0);
  // #FF9500
}

/*
double calculeTailleEcran() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
    // RECUPERATION
    // int arrondi = calculateDiagonalInches().round();
  }

*/


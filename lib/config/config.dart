import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

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
}

class Connexion {
  static Future<MySqlConnection> connexionDB() async {
    try {
      final conn = await MySqlConnection.connect(ConnectionSettings(
        host: 'srv1582.hstgr.io',
        port: 3306,
        user: 'u232422107_t_mvst',
        password: 't_mvst_P@ss9',
        db: 'u232422107_mvst',
      ));
      return conn;
    } catch (e) {
      print("Erreur $e");
      throw Exception(
          'Connexion à la base de données échouée'); // Lève une exception
    }
  }

  static Future<MySqlConnection?> _connexionDB() async {
    try {
      final conn = await MySqlConnection.connect(ConnectionSettings(
        host: 'srv1582.hstgr.io',
        port: 3306,
        user: 'u232422107_t_mvst',
        password: 't_mvst_P@ss9',
        db: 'u232422107_mvst',
      ));
      return conn;
    } catch (e) {
      print('Erreur de connexion à la base de données: $e');
      return null;
    }
  }
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


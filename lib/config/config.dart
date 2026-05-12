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

  // ── Couleurs Auth ─────────────────────────────────────────────────────────
  final authBackground = const Color(0xFF1A2B3C);
  final authCardBackground = const Color(0xFF1E3A5F);
  final authBorder = const Color(0xFF2A5080);
  final authAccent = const Color(0xFF64B5F6);
  final authButton = const Color.fromARGB(255, 1, 67, 142);
  final authButtonDisabled = const Color(0xFF1E3A5F);
  final authTextPrimary = const Color(0xFFFFFFFF);
  final authTextSecondary = const Color(0x80FFFFFF);
  final authDialogBackground = const Color(0xFF1E3A5F);

  // ── Nouvelles Couleurs ────────────────────────────────────────────────────
  final couleurIcone = const Color.fromARGB(255, 3, 57, 183);
  final couleurDefondPrincipale = const Color.fromARGB(172, 54, 148, 241);
  final couleurOmbreCarte = const Color.fromARGB(144, 0, 174, 255);

  // ── Home ─────────────────────────────────────────────────────────────────
  final homeBackground = const Color(0xFFF4F7FB);
  final homeCardBackground = const Color(0xFFFFFFFF);
  final homeBordurePetiteCarte = const Color.fromARGB(255, 149, 202, 255);
  final homeAccent = const Color(0xFFFFE082);
  final homeTextPrimary = const Color(0xFF1A2D3E);
  final homeTabSelected = const Color(0xFF1565C0);
  final homeTabUnselected = const Color(0xFF90A4AE);
  final homeDrawerBackground = const Color(0xFF0D47A1);
  final homeBandeauBackground = const Color(0xFFE3F2FD);
  final homeBandeauBorder = const Color(0xFFBBDEFB);

  // ── V2 ───────────────────────────────────────────────────────────────────
  final homeHeaderTop = const Color(0xFF1565C0);
  final homeHeaderBottom = const Color(0xFF1E88E5);
  final homeGrandeCarte = const Color.fromARGB(92, 216, 231, 251);
  final homeButtonPrimary = const Color(0xFF1565C0);
  final couleurTicket = const Color.fromARGB(255, 135, 213, 241);
  final couleurInitiales = const Color.fromARGB(255, 11, 150, 242);
}

// class Connexion {
//   static Future<MySqlConnection> connexionDB() async {
//     try {
//       final conn = await MySqlConnection.connect(ConnectionSettings(
//         host: 'srv1582.hstgr.io',
//         port: 3306,
//         user: 'u232422107_t_mvst',
//         password: 't_mvst_P@ss9',
//         db: 'u232422107_mvst',
//       ));
//       return conn;
//     } catch (e) {
//       throw Exception(
//           'Connexion à la base de données échouée'); // Lève une exception
//     }
//   }

//   static Future<MySqlConnection?> _connexionDB() async {
//     try {
//       final conn = await MySqlConnection.connect(ConnectionSettings(
//         host: 'srv1582.hstgr.io',
//         port: 3306,
//         user: 'u232422107_t_mvst',
//         password: 't_mvst_P@ss9',
//         db: 'u232422107_mvst',
//       ));
//       return conn;
//     } catch (e) {
//       print('Erreur de connexion à la base de données: $e');
//       return null;
//     }
//   }
// }


/*
double calculeTailleEcran() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
    // RECUPERATION
    // int arrondi = calculateDiagonalInches().round();
  }

*/


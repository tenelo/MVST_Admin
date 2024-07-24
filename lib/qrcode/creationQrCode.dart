import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:qr_flutter/qr_flutter.dart';

Color? couleurA;
Color? couleurB;

class CreationQrCode {
  static Widget buildQrCode(
    final String idUtilisateur,
    final String idTicket,
    final int place,
    final String nom,
    final String contact,
    final String date,
    final String heure,
    final String depart,
    final String destination,
    final String etatScann,
  ) {
    final String message =
        "$idUtilisateur \n$idTicket \n$nom \n$contact \n$date \n$heure \n$place \n$depart->$destination \n$etatScann";

    final FutureBuilder<ui.Image> qrFutureBuilder = FutureBuilder<ui.Image>(
      future: _loadOverlayImage(),
      builder: (BuildContext ctx, AsyncSnapshot<ui.Image> snapshot) {
        const double size = 280.0;
        if (snapshot.hasData) {
          //return const SizedBox(width: size, height: size);
          if (etatScann == "scanne") {
            couleurA = Config.colors.bleuA;
            couleurB = Config.colors.bleuB;
          } else {
            couleurA = Config.colors.vertA;
            couleurB = Config.colors.vertB;
          }
        }

        return CustomPaint(
          size: const Size.square(size),
          painter: QrPainter(
            data: message,
            version: QrVersions.auto,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: couleurA,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: couleurB,
            ),
            embeddedImage: snapshot.data,
            // taille de l'image dans le qrcode
            embeddedImageStyle: const QrEmbeddedImageStyle(
              size: Size.square(75),
            ),
          ),
        );
      },
    );

    return qrFutureBuilder;
  }

  static Future<ui.Image> _loadOverlayImage() async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    final ByteData byteData = await rootBundle.load('assets/images/Qr_rd3.png');
    ui.decodeImageFromList(byteData.buffer.asUint8List(), completer.complete);
    return completer.future;
  }
}

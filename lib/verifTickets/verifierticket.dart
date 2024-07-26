import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/verifTickets/verifParId.dart';
import 'package:mvst_admin/verifTickets/verifParQrcode.dart';

// ignore: must_be_immutable
class ParametresVerification extends StatelessWidget {
  ParametresVerification({super.key});
  User? user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Config.colors.bleuFonce2,
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 25,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * .85,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VerifParId(),
                    ),
                  );
                },
                child: Text(
                  "VERIFICATION PAR ID",
                  style: TextStyle(
                    fontSize: 16,
                    color: Config.colors.bleuClaire,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * .85,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VerifParQrCode(),
                    ),
                  );
                },
                child: Text(
                  "VERIFICATION PAR QR CODE",
                  style: TextStyle(
                    fontSize: 16,
                    color: Config.colors.bleuClaire,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      persistentFooterButtons: [
        Text(
          user!.displayName!,
          style: TextStyle(
            fontFamily: 'Lobster',
            color: Config.colors.bleuClaire,
          ),
        )
      ],
    );
  }
}

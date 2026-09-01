import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/auth_service.dart';

// ignore: must_be_immutable
class ParametresVerification extends StatelessWidget {
  ParametresVerification({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.authBackground,
        iconTheme: IconThemeData(color: c.homeAccent),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 25),
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
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const VerifParId(),
                    //   ),
                    // );
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
            ],
          ),
        ),
      ),
      persistentFooterButtons: [
        Text(
          AuthService.getUtilisateur()?.displayName ?? '',
          style: TextStyle(
            fontFamily: 'Lobster',
            color: Config.colors.bleuClaire,
          ),
        ),
      ],
    );
  }
}

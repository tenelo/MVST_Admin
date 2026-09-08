import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mvst_admin/authentification/clavier_numerique.dart';
import 'package:mvst_admin/authentification/pin_forgot.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';

/// Ecran de saisie du code secret MVST existant, lors de l'inscription admin
/// d'un numero qui est deja client MVST. Verifie le code via /login, puis
/// appelle onPinVerifie(code) pour finaliser l'inscription admin avec CE code
/// (garantit le meme code secret entre les deux apps).
class PinVerification extends StatefulWidget {
  const PinVerification({
    super.key,
    required this.telephone,
    required this.onPinVerifie,
  });

  final String telephone;
  final Future<void> Function(String pin) onPinVerifie;

  @override
  State<PinVerification> createState() => _PinVerificationState();
}

class _PinVerificationState extends State<PinVerification> {
  String _pin = '';
  bool _isLoading = false;
  String? _erreur;

  void _onChiffre(String chiffre) {
    if (_isLoading) return;
    if (_pin.length >= 4) return;
    setState(() {
      _erreur = null;
      _pin += chiffre;
    });
    if (_pin.length == 4) _verifier();
  }

  void _onSupprimer() {
    if (_isLoading) return;
    if (_pin.isEmpty) return;
    setState(() {
      _erreur = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verifier() async {
    setState(() => _isLoading = true);
    try {
      // Verifier le code contre le compte MVST via /login.
      final resp = await ApiClient.instance.post(
        'login',
        body: {'telephone': widget.telephone, 'pin': _pin},
        timeout: const Duration(seconds: 10),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        // Code correct : finaliser l'inscription admin avec ce meme code.
        final code = _pin;
        try {
          await widget.onPinVerifie(code);
        } catch (e) {
          if (mounted) {
            setState(() {
              _erreur = 'Erreur lors de la finalisation. Réessayez.';
              _pin = '';
              _isLoading = false;
            });
          }
        }
        return;
      } else {
        if (mounted) {
          setState(() {
            _erreur = 'Code secret incorrect.';
            _pin = '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = 'Erreur réseau. Réessayez.';
          _pin = '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.authBackground,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.authTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: sh * 0.02),
            Icon(Icons.lock_outline, color: c.authAccent, size: 48),
            SizedBox(height: sh * 0.02),
            Text(
              'Entrez votre code secret',
              style: TextStyle(
                color: c.authTextPrimary,
                fontSize: sw * 0.055,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sh * 0.01),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
              child: Text(
                'Ce numéro possède déjà un compte MVST. Saisissez le même code secret.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.authTextSecondary, fontSize: sw * 0.032),
              ),
            ),
            SizedBox(height: sh * 0.04),
            _PinDots(longueur: _pin.length, erreur: _erreur != null, colors: c),
            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Text(_erreur!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            SizedBox(height: sh * 0.02),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PinForgot()),
                      );
                    },
              child: Text(
                'Code secret oublié ?',
                style: TextStyle(
                  color: c.authAccent,
                  fontSize: sw * 0.035,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: CircularProgressIndicator(color: c.authAccent),
              )
            else
              ClavierNumerique(
                onChiffre: _onChiffre,
                onSupprimer: _onSupprimer,
                colors: c,
                sw: sw,
              ),
            SizedBox(height: sh * 0.04),
          ],
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int longueur;
  final bool erreur;
  final dynamic colors;
  const _PinDots({required this.longueur, required this.erreur, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final rempli = i < longueur;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rempli ? c.authAccent : Colors.transparent,
            border: Border.all(color: erreur ? Colors.red : c.authAccent, width: 2),
          ),
        );
      }),
    );
  }
}

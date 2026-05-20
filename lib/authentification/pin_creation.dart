import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/authentification/clavier_numerique.dart';
import 'package:mvst_admin/main.dart';

class PinCreation extends StatefulWidget {
  final Future<void> Function(String pin) onPinConfirmed;

  const PinCreation({super.key, required this.onPinConfirmed});

  @override
  State<PinCreation> createState() => _PinCreationState();
}

class _PinCreationState extends State<PinCreation> {
  String _pin = '';
  String _pinConfirmation = '';
  bool _confirmStep = false;
  bool _isLoading = false;
  String? _erreur;

  void _onChiffre(String chiffre) {
    setState(() => _erreur = null);
    if (_confirmStep) {
      if (_pinConfirmation.length >= 4) return;
      _pinConfirmation += chiffre;
      if (_pinConfirmation.length == 4) _validerConfirmation();
    } else {
      if (_pin.length >= 4) return;
      _pin += chiffre;
      if (_pin.length == 4) setState(() => _confirmStep = true);
    }
    setState(() {});
  }

  void _onSupprimer() {
    setState(() {
      _erreur = null;
      if (_confirmStep) {
        if (_pinConfirmation.isEmpty) {
          _confirmStep = false;
        } else {
          _pinConfirmation = _pinConfirmation.substring(
            0,
            _pinConfirmation.length - 1,
          );
        }
      } else {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _validerConfirmation() async {
    if (_pin != _pinConfirmation) {
      setState(() {
        _erreur = 'Le Code Secret ne correspond pas. Réessayez.';
        _pinConfirmation = '';
        _confirmStep = false;
        _pin = '';
      });
      return;
    }
    setState(() => _isLoading = true);
    await widget.onPinConfirmed(_pin);
    if (!mounted) return;

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Accueil()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final pinCourant = _confirmStep ? _pinConfirmation : _pin;

    return Scaffold(
      backgroundColor: c.authBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: sh * 0.07),
            _Logo(colors: c, sw: sw),
            SizedBox(height: sh * 0.04),
            Text(
              _confirmStep
                  ? 'Confirmez votre Code Secret'
                  : 'Créez votre Code Secret',
              style: TextStyle(
                color: c.authTextPrimary,
                fontSize: sw * 0.055,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _confirmStep
                  ? 'Saisissez à nouveau votre Code Secret'
                  : 'Choisissez un code à 4 chiffres',
              style: TextStyle(
                color: c.authTextSecondary,
                fontSize: sw * 0.032,
              ),
            ),
            SizedBox(height: sh * 0.05),
            _PinDots(
              longueur: pinCourant.length,
              erreur: _erreur != null,
              colors: c,
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Text(
                _erreur!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
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

// ── Widgets partagés ──────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final dynamic colors;
  final double sw;
  const _Logo({required this.colors, required this.sw});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      width: sw * 0.20,
      height: sw * 0.20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.authAccent, width: 2),
        color: c.authCardBackground,
      ),
      child: Center(
        child: Text(
          'MVST',
          style: TextStyle(
            color: c.authAccent,
            fontSize: sw * 0.042,
            fontFamily: 'Lobster',
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int longueur;
  final bool erreur;
  final dynamic colors;
  const _PinDots({
    required this.longueur,
    required this.erreur,
    required this.colors,
  });

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
            border: Border.all(
              color: erreur ? Colors.red : c.authAccent,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';

class SuiviAffluenceTab extends StatefulWidget {
  const SuiviAffluenceTab({super.key});

  @override
  State<SuiviAffluenceTab> createState() => _SuiviAffluenceTabState();
}

class _SuiviAffluenceTabState extends State<SuiviAffluenceTab> {
  bool _chargement = true;
  String? _erreur;
  List<Map<String, dynamic>> _lignes = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  // Permet au parent (bouton refresh de l'AppBar) de recharger cet onglet.
  void rafraichir() => _charger();

  Future<void> _charger() async {
    if (!mounted) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final resp = await ApiClient.instance.post(
        'suiviAffluence.php',
        body: {},
      );
      final data = jsonDecode(resp.body);
      if (!mounted) return;
      if (data['success'] == true && data['lignes'] is List) {
        setState(() {
          _lignes = List<Map<String, dynamic>>.from(
            (data['lignes'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
          _chargement = false;
        });
      } else {
        setState(() {
          _erreur = data['message']?.toString() ?? 'Erreur de chargement.';
          _chargement = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Erreur réseau.';
        _chargement = false;
      });
    }
  }

  String _dateLisible(String dateIso) {
    if (dateIso.isEmpty) return '';
    try {
      return DateFormat(
        'EEEE d MMMM y',
        'fr_FR',
      ).format(DateTime.parse(dateIso));
    } catch (_) {
      return dateIso;
    }
  }

  // Regroupe les lignes par gare.
  Map<String, List<Map<String, dynamic>>> get _parGare {
    final g = <String, List<Map<String, dynamic>>>{};
    for (final l in _lignes) {
      final gare = (l['gare'] ?? '').toString();
      g.putIfAbsent(gare, () => []).add(l);
    }
    return g;
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;

    if (_chargement) {
      return Center(child: CircularProgressIndicator(color: c.authAccent));
    }
    if (_erreur != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erreur!, style: TextStyle(color: c.authTextPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.authAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: _charger,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final gares = _parGare;

    return RefreshIndicator(
      color: c.authAccent,
      onRefresh: _charger,
      child: _lignes.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timeline,
                          color: c.authTextPrimary.withValues(alpha: 0.4),
                          size: 44,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun départ actif à venir',
                          style: TextStyle(
                            color: c.authCardBackground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in gares.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: c.authAccent, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Gare : ${entry.key}',
                          style: TextStyle(
                            color: c.authCardBackground,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.map((l) => _carteCar(c, l)),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }

  Widget _carteCar(dynamic c, Map<String, dynamic> l) {
    final type = (l['type'] ?? 'standard').toString();
    final vendus = (l['vendus'] as num?)?.toInt() ?? 0;
    final seuil = (l['seuil'] as num?)?.toInt() ?? 1;
    final taux = (l['tauxPct'] as num?)?.toInt() ?? 0;
    final numeroCar = (l['numeroCar'] as num?)?.toInt() ?? 1;
    final plein = (l['plein'] as bool?) ?? false;
    final aAnticiper = !plein && vendus >= seuil - 10;
    final ligne = (l['ligne'] ?? '').toString();
    final heure = (l['heure'] ?? '').toString();
    final dateIso = (l['date_iso'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: c.authCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.authBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: type == 'vip' ? c.jauneBlanc : c.authAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Car n°$numeroCar · ${type.toUpperCase()}',
                  style: TextStyle(
                    color: type == 'vip' ? c.authCardBackground : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              if (plein)
                _pastille('PLEIN', const Color(0xFFEF4444))
              else if (aAnticiper)
                _pastille('À ANTICIPER', const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ligne,
            style: TextStyle(
              color: c.authTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${_dateLisible(dateIso)} · $heure',
            style: TextStyle(color: c.authTextSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$vendus / $seuil',
                style: TextStyle(
                  color: c.authTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$taux %',
                style: TextStyle(
                  color: aAnticiper || plein
                      ? const Color(0xFFEF4444)
                      : c.authAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (seuil > 0 ? vendus / seuil : 0).toDouble().clamp(0.0, 1.0),
            color: plein
                ? const Color(0xFFEF4444)
                : (aAnticiper ? const Color(0xFFF59E0B) : c.authAccent),
            backgroundColor: c.authBorder.withValues(alpha: 0.4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _pastille(String texte, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texte,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

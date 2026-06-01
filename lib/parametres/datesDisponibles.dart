import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';

class DatesDisponibles extends StatefulWidget {
  const DatesDisponibles({super.key});

  @override
  State<DatesDisponibles> createState() => _DatesDisponiblesState();
}

class _DatesDisponiblesState extends State<DatesDisponibles> {
  int _nbJours = 6;
  int _nbJoursSauvegarde = 6;
  bool _isLoading = true;
  bool _isSaving = false;

  static const List<int> _options = [1, 2, 3, 4, 5, 6, 7, 10, 14, 21, 30];

  @override
  void initState() {
    super.initState();
    _chargerConfig();
  }

  Future<void> _chargerConfig() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http
          .post(
            apiUri('datesDisponibles.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'lire'}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _nbJours = data['nbJours'] ?? 6;
            _nbJoursSauvegarde = _nbJours;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sauvegarder() async {
    setState(() => _isSaving = true);
    try {
      final response = await http
          .post(
            apiUri('datesDisponibles.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'sauvegarder', 'nbJours': _nbJours}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() => _nbJoursSauvegarde = _nbJours);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                'Intervalle mis à jour : $_nbJours jour${_nbJours > 1 ? "s" : ""}',
              ),
            ),
          );
          return;
        }
      }
      _afficherErreur();
    } catch (_) {
      _afficherErreur();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _afficherErreur() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('Erreur lors de la sauvegarde'),
      ),
    );
  }

  String _labelOption(int n) {
    if (n == 7) return '7 j (1 sem.)';
    if (n == 14) return '14 j (2 sem.)';
    if (n == 21) return '21 j (3 sem.)';
    if (n == 30) return '30 j (1 mois)';
    return '$n j';
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final bool hasChanges = _nbJours != _nbJoursSauvegarde;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: c.authCardBackground),
        title: Text(
          'Dates disponibles',
          style: TextStyle(
            color: c.authCardBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.authCardBackground),
            onPressed: _chargerConfig,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: c.authCardBackground),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Carte d'explication ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.authCardBackground.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.authCardBackground.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              color: c.authCardBackground,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Horizon de réservation',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Le client peut réserver des tickets à partir de demain (J+1) '
                          'jusqu\'au J+$_nbJoursSauvegarde.',
                          style: TextStyle(
                            //color: c.authTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: c.authCardBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Valeur actuelle : $_nbJoursSauvegarde jour${_nbJoursSauvegarde > 1 ? "s" : ""}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'CHOISIR L\'INTERVALLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Chips de sélection ────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _options.map((n) {
                      final selected = _nbJours == n;
                      return ChoiceChip(
                        label: Text(
                          _labelOption(n),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                        selected: selected,
                        selectedColor: c.authCardBackground,
                        checkmarkColor: Colors.white,
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide(
                          color: selected ? c.authCardBackground : c.authAccent,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        onSelected: (_) => setState(() => _nbJours = n),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

             
                  // ── Bouton enregistrer ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving || !hasChanges ? null : _sauvegarder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.authCardBackground,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              hasChanges
                                  ? Icons.save_outlined
                                  : Icons.check_circle_outline,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Enregistrement...'
                            : hasChanges
                            ? 'Enregistrer'
                            : 'Déjà enregistré',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

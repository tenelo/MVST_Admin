import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/screens/cars_positionnes_tab.dart';
import 'package:mvst_admin/screens/suivi_affluence_tab.dart';

class PositionnerCar extends StatefulWidget {
  const PositionnerCar({super.key});

  @override
  State<PositionnerCar> createState() => _PositionnerCarState();
}

class _PositionnerCarState extends State<PositionnerCar> {
  // 'standard' | 'vip'
  String _type = 'standard';

  // Lignes chargees depuis api_lignes.php, filtrees par type.
  List<Map<String, dynamic>> _toutesLignes = [];
  Map<String, dynamic>? _ligneSelectionnee;

  // Heures chargees depuis heuresDepart.php, filtrees par type.
  List<String> _heures = [];
  String? _heureSelectionnee;

  // Date choisie (DateTime brut) + son rendu FR pour le documentId.
  DateTime? _dateChoisie;

  bool _chargementInitial = true;
  bool _positionnementEnCours = false;
  final GlobalKey<State> _suiviKey = GlobalKey<State>();
  final GlobalKey<State> _carsKey = GlobalKey<State>();

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  /// Charge lignes + heures en parallele, puis applique le filtre de type courant.
  Future<void> _chargerDonnees() async {
    if (mounted) setState(() => _chargementInitial = true);
    try {
      final resultats = await Future.wait([
        ApiClient.instance.get('api_lignes.php?type=all'),
        ApiClient.instance.get('heuresDepart.php'),
      ]);
      if (!mounted) return;

      final lignesData = jsonDecode(resultats[0].body);
      final heuresData = jsonDecode(resultats[1].body);

      setState(() {
        if (lignesData['success'] == true && lignesData['lignes'] is List) {
          _toutesLignes = List<Map<String, dynamic>>.from(lignesData['lignes']);
        }
        if (heuresData['success'] == true && heuresData['heures'] is List) {
          _heuresBrutes = List<Map<String, dynamic>>.from(heuresData['heures']);
        }
        _chargementInitial = false;
      });
      _appliquerFiltreType();
    } catch (e) {
      if (mounted) {
        setState(() => _chargementInitial = false);
        _snack('Erreur de chargement : $e', Colors.red);
      }
    }
  }

  // Heures brutes non filtrees (toutes, tous types confondus).
  List<Map<String, dynamic>> _heuresBrutes = [];

  /// Reapplique le filtre de type sur lignes + heures et remet a zero
  /// les selections devenues invalides.
  void _appliquerFiltreType() {
    setState(() {
      _heures = _heuresBrutes
          .where((h) => h['type']?.toString() == _type)
          .map((h) => formatHeure(h['heure'].toString()))
          .toList();

      // Si l'heure choisie n'existe plus pour ce type, on la reset.
      if (!_heures.contains(_heureSelectionnee)) {
        _heureSelectionnee = null;
      }

      // Si la ligne choisie n'est plus du bon type, on la reset.
      if (_ligneSelectionnee != null &&
          _ligneSelectionnee!['type']?.toString() != _type) {
        _ligneSelectionnee = null;
      }
    });
  }

  List<Map<String, dynamic>> get _lignesDuType =>
      _toutesLignes.where((l) => l['type']?.toString() == _type).toList();

  Future<void> _choisirDate() async {
    final now = DateTime.now();
    final demain = DateTime(now.year, now.month, now.day + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: _dateChoisie ?? demain,
      firstDate: demain,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _dateChoisie = picked);
    }
  }

  /// Rendu FR de la date, IDENTIQUE au client (documentId) : 'lundi_7_septembre_2026'.
  String? get _dateFormatee => _dateChoisie == null
      ? null
      : DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(_dateChoisie!);

  /// Rendu lisible pour l'UI : 'lundi 7 septembre 2026'.
  String? get _dateLisible => _dateChoisie == null
      ? null
      : DateFormat('EEEE d MMMM y', 'fr_FR').format(_dateChoisie!);

  Future<void> _positionner() async {
    if (_ligneSelectionnee == null) {
      _snack('Choisissez une ligne.', Colors.red);
      return;
    }
    if (_dateChoisie == null) {
      _snack('Choisissez une date.', Colors.red);
      return;
    }
    if (_heureSelectionnee == null) {
      _snack('Choisissez une heure.', Colors.red);
      return;
    }

    final depart = _ligneSelectionnee!['depart']?.toString();
    final destination = _ligneSelectionnee!['destination']?.toString();
    if (depart == null || destination == null) {
      _snack('Ligne invalide (départ/destination manquant).', Colors.red);
      return;
    }

    setState(() => _positionnementEnCours = true);
    try {
      final resp = await ApiClient.instance.post(
        'positionnerCar.php',
        body: {
          'depart': depart,
          'destination': destination,
          'date': _dateFormatee,
          'heure': formatHeure(_heureSelectionnee!),
          'type': _type,
          'date_iso': DateFormat('yyyy-MM-dd').format(_dateChoisie!),
          'ligne': _ligneSelectionnee!['ligne']?.toString() ?? '',
        },
      );
      final data = jsonDecode(resp.body);
      if (!mounted) return;
      if (data['success'] == true) {
        _snack(
          data['message']?.toString() ?? 'Car positionné.',
          const Color(0xFF10B981),
        );
      } else {
        _snack(data['message']?.toString() ?? 'Erreur inconnue.', Colors.red);
      }
    } catch (_) {
      if (mounted) _snack('Erreur réseau. Réessayez.', Colors.red);
    } finally {
      if (mounted) setState(() => _positionnementEnCours = false);
    }
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;

    final widgetPositionnement = _chargementInitial
        ? Center(child: CircularProgressIndicator(color: c.authAccent))
        : SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.06, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Type (Standard / VIP) ──────────────────────────────
                Text(
                  'Type de car',
                  style: TextStyle(
                    color: c.authCardBackground.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _boutonType('standard', 'Standard', c)),
                    const SizedBox(width: 12),
                    Expanded(child: _boutonType('vip', 'VIP', c)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Ligne ──────────────────────────────────────────────
                Text(
                  'Ligne',
                  style: TextStyle(
                    color: c.authCardBackground.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _cadre(
                  c,
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _lignesDuType.contains(_ligneSelectionnee)
                        ? _ligneSelectionnee
                        : null,
                    isExpanded: true,
                    dropdownColor: c.authCardBackground,
                    iconEnabledColor: c.authAccent,
                    style: TextStyle(color: c.authTextPrimary),
                    hint: Text(
                      'Choisir une ligne',
                      style: TextStyle(color: c.authTextPrimary.withOpacity(0.6)),
                    ),
                    decoration: _decoInterne(c),
                    items: _lignesDuType
                        .map(
                          (l) => DropdownMenuItem(
                            value: l,
                            child: Text(
                              l['ligne']?.toString() ?? '',
                              style: TextStyle(color: c.authTextPrimary),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _ligneSelectionnee = val),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Date ───────────────────────────────────────────────
                Text(
                  'Date',
                  style: TextStyle(
                    color: c.authCardBackground.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _choisirDate,
                  borderRadius: BorderRadius.circular(12),
                  child: _cadre(
                    c,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: c.authAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _dateLisible ?? 'Choisir une date',
                            style: TextStyle(
                              color: _dateLisible == null
                                  ? c.authTextPrimary.withOpacity(0.6)
                                  : c.authTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Heure ──────────────────────────────────────────────
                Text(
                  'Heure',
                  style: TextStyle(
                    color: c.authCardBackground.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _cadre(
                  c,
                  DropdownButtonFormField<String>(
                    value: _heures.contains(_heureSelectionnee)
                        ? _heureSelectionnee
                        : null,
                    isExpanded: true,
                    dropdownColor: c.authCardBackground,
                    iconEnabledColor: c.authAccent,
                    style: TextStyle(color: c.authTextPrimary),
                    hint: Text(
                      _heures.isEmpty
                          ? 'Aucune heure pour ce type'
                          : 'Choisir une heure',
                      style: TextStyle(color: c.authTextPrimary.withOpacity(0.6)),
                    ),
                    decoration: _decoInterne(c),
                    items: _heures
                        .map(
                          (h) => DropdownMenuItem(
                            value: h,
                            child: Text(
                              h,
                              style: TextStyle(color: c.authTextPrimary),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _heures.isEmpty
                        ? null
                        : (val) => setState(() => _heureSelectionnee = val),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Bouton Positionner ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _positionnementEnCours ? null : _positionner,
                    child: _positionnementEnCours
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Positionner',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: c.homeBackground,
        appBar: AppBar(
          backgroundColor: c.authCardBackground,
          elevation: 0,
          iconTheme: IconThemeData(color: c.jauneBlanc),
          centerTitle: true,
          title: Text(
            'POSITIONNER UN CAR',
            style: TextStyle(
              color: c.jauneBlanc,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.refresh, color: c.jauneBlanc),
                onPressed: () {
                  final index = DefaultTabController.of(ctx).index;
                  if (index == 0) {
                    (_suiviKey.currentState as dynamic)?.rafraichir();
                  } else if (index == 1) {
                    if (!_chargementInitial) _chargerDonnees();
                  } else {
                    (_carsKey.currentState as dynamic)?.rafraichir();
                  }
                },
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: c.jauneBlanc,
            unselectedLabelColor: c.authTextSecondary,
            indicatorColor: c.authAccent,
            tabs: const [
              Tab(icon: Icon(Icons.timeline), text: 'Suivi affluence'),
              Tab(icon: Icon(Icons.add_location_alt), text: 'Positionner'),
              Tab(icon: Icon(Icons.list_alt), text: 'Cars Positionnés'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SuiviAffluenceTab(key: _suiviKey),
            widgetPositionnement,
            CarsPositionnesTab(key: _carsKey),
          ],
        ),
      ),
    );
  }

  Widget _boutonType(String valeur, String label, dynamic c) {
    final actif = _type == valeur;
    return GestureDetector(
      onTap: () {
        if (_type == valeur) return;
        setState(() => _type = valeur);
        _appliquerFiltreType();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: actif ? c.authAccent : c.authCardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: actif ? c.authAccent : c.authBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: actif ? Colors.white : c.authTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _cadre(dynamic c, Widget enfant) {
    return Container(
      decoration: BoxDecoration(
        color: c.authCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.authBorder, width: 1.5),
      ),
      child: enfant,
    );
  }

  InputDecoration _decoInterne(dynamic c) {
    return const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

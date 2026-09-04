import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class VueParDepart extends StatefulWidget {
  const VueParDepart({super.key, required this.gare, required this.uid});
  final String gare;
  final String uid;

  @override
  State<VueParDepart> createState() => _VueParDepartState();
}

class _VueParDepartState extends State<VueParDepart> {
  bool _isLoading = true;
  String? _erreur;
  List<DepartVue> _departs = [];
  DateTime _dateSelectionnee = DateTime.now();

  // ── Selecteur de gare (superadmin only) ─────────────────────────────────────
  String? _role;
  String? _gareSelectionnee;
  List<String> _listeGares = [];

  // Gare effectivement affichee : widget.gare pour un admin normal (INCHANGE),
  // ou la gare choisie (eventuellement null = "Toutes les gares") pour un
  // superadmin.
  String? get _gareEffective =>
      _role == 'superadmin' ? _gareSelectionnee : widget.gare;

  // Titre affiche : la gare effective, ou "Toutes les gares" en mode
  // agregat superadmin (le seul cas ou _gareEffective est null).
  String get _titreGare => _gareEffective ?? 'Toutes les gares';

  @override
  void initState() {
    super.initState();
    _initRoleEtGares();
  }

  Future<void> _initRoleEtGares() async {
    final role = await recupererRole();
    if (!mounted) return;
    setState(() => _role = role);
    if (role == 'superadmin') {
      _chargerListeGares();
    }
    _getDonnees();
  }

  Future<void> _chargerListeGares() async {
    try {
      final response = await ApiClient.instance.get('gares.php');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _listeGares = List<Map<String, dynamic>>.from(data['gares'])
                .map((g) => g['gare'].toString())
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  // ── Charger la vue par depart via PHP ──────────────────────────────────────
  Future<void> _getDonnees() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _erreur = null;
      });
    }
    try {
      final String dateChoisie =
          DateFormat('yyyy-MM-dd').format(_dateSelectionnee);
      final Map<String, dynamic> body = {'date': dateChoisie};
      final gareEffective = _gareEffective;
      if (gareEffective != null) {
        body['gare'] = gareEffective;
      }
      final response = await ApiClient.instance.post(
        'vue_par_depart.php',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _departs = List<Map<String, dynamic>>.from(data['departs'] ?? [])
                  .map((j) => DepartVue.fromJson(j))
                  .toList();
              _isLoading = false;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _erreur = 'Erreur lors du chargement de la vue par depart.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _erreur = 'Erreur reseau. Veuillez reessayer.';
        });
      }
    }
  }

  // ── Selecteur de date (motif ticketsDuJourScannes._choisirDate) ────────────
  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && mounted) {
      setState(() => _dateSelectionnee = picked);
      _getDonnees();
    }
  }

  // ── Selecteur de gare (visible uniquement si _role == 'superadmin') ────────
  PreferredSizeWidget _selecteurGareBottom(dynamic c) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.store_outlined, color: c.jauneBlanc, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String?>(
                value: _gareSelectionnee,
                isExpanded: true,
                dropdownColor: c.authCardBackground,
                iconEnabledColor: c.jauneBlanc,
                style: TextStyle(color: c.jauneBlanc),
                underline: Container(
                  height: 1,
                  color: c.jauneBlanc.withValues(alpha: 0.4),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Toutes les gares'),
                  ),
                  ..._listeGares.map(
                    (g) => DropdownMenuItem<String?>(value: g, child: Text(g)),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _gareSelectionnee = val);
                  _getDonnees();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _estVide => _departs.isEmpty;

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Scaffold(
      backgroundColor: c.homeBackground,
      appBar: AppBar(
        backgroundColor: c.authCardBackground,
        iconTheme: IconThemeData(color: c.jauneBlanc),
        centerTitle: true,
        title: Text(
          'Vue par depart - $_titreGare',
          style: TextStyle(
            color: c.jauneBlanc,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _choisirDate,
            icon: Icon(Icons.calendar_month_outlined, color: c.jauneBlanc),
            label: Text(
              DateFormat('EEE d MMM', 'fr_FR').format(_dateSelectionnee),
              style: TextStyle(color: c.jauneBlanc, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        bottom: _role == 'superadmin' ? _selecteurGareBottom(c) : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool large = constraints.maxWidth >= 600;
          return RefreshIndicator(
            onRefresh: _getDonnees,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: _buildContenu(large),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildContenu(bool large) {
    if (_isLoading) {
      return const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator()),
      ];
    }
    if (_erreur != null) {
      return [
        const SizedBox(height: 100),
        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
        const SizedBox(height: 12),
        Text(
          _erreur!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _getDonnees,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Config.colors.homeButtonPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ];
    }
    if (_estVide) {
      return [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 48,
                color: Config.colors.homeTabUnselected,
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun depart aujourd\'hui',
                style: TextStyle(
                  color: Config.colors.homeTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      _buildDiagrammeComparatif(),
      const SizedBox(height: 24),
      Text(
        'Departs du jour',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Config.colors.homeTextPrimary,
        ),
      ),
      const SizedBox(height: 8),
      large ? _buildDepartsTable() : _buildDepartsListe(),
    ];
  }

  // ── A) Diagramme comparatif (motif Syncfusion de diagrammeABarres.dart) ─────
  Widget _buildDiagrammeComparatif() {
    return SizedBox(
      height: 320,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        primaryYAxis: const NumericAxis(
          majorGridLines: MajorGridLines(width: 0.5),
        ),
        title: ChartTitle(
          text: 'Remplissage des departs du jour',
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Config.colors.bleuA,
          ),
        ),
        legend: const Legend(
          isVisible: true,
          textStyle: TextStyle(fontWeight: FontWeight.w900),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<DepartVue, String>>[
          ColumnSeries<DepartVue, String>(
            name: 'Vendus',
            dataSource: _departs,
            xValueMapper: (d, _) => d.labelChart,
            yValueMapper: (d, _) => d.vendus,
            color: Config.colors.bleuA,
            borderRadius: BorderRadius.circular(4),
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
          ColumnSeries<DepartVue, String>(
            name: 'Capacite',
            dataSource: _departs,
            xValueMapper: (d, _) => d.labelChart,
            yValueMapper: (d, _) => d.capacite,
            color: Config.colors.homeTabUnselected,
            borderRadius: BorderRadius.circular(4),
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  // ── B) Liste empilee (etroit) ─────────────────────────────────────────────
  Widget _buildDepartsListe() {
    return Column(
      children: _departs.map((d) => _CarteDepart(depart: d)).toList(),
    );
  }

  // ── B) DataTable (large), jauge en colonne dediee ──────────────────────────
  Widget _buildDepartsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Heure')),
          DataColumn(label: Text('Destination')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Vendus'), numeric: true),
          DataColumn(label: Text('Capacite'), numeric: true),
          DataColumn(label: Text('Restantes'), numeric: true),
          DataColumn(label: Text('Embarques'), numeric: true),
          DataColumn(label: Text('Remplissage')),
        ],
        rows: _departs.map((d) {
          return DataRow(
            cells: [
              DataCell(Text(d.heureDeDepart)),
              DataCell(Text(d.destination)),
              DataCell(Text(d.typeVoyage.toUpperCase())),
              DataCell(Text('${d.vendus}')),
              DataCell(Text('${d.capacite}')),
              DataCell(Text('${d.restantes}')),
              DataCell(Text('${d.embarques}')),
              DataCell(SizedBox(width: 150, child: _JaugeRemplissage(depart: d))),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Modele ────────────────────────────────────────────────────────────────────
class DepartVue {
  DepartVue({
    required this.documentId,
    required this.heureDeDepart,
    required this.destination,
    required this.typeVoyage,
    required this.vendus,
    required this.capacite,
    required this.restantes,
    required this.embarques,
    required this.surReservation,
  });

  final String documentId;
  final String heureDeDepart;
  final String destination;
  final String typeVoyage;
  final int vendus;
  final int capacite;
  final int restantes;
  final int embarques;
  final bool surReservation;

  factory DepartVue.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    bool asBool(dynamic v) =>
        v == true || v == 1 || v?.toString() == '1' || v?.toString().toLowerCase() == 'true';
    return DepartVue(
      documentId: j['documentId']?.toString() ?? '',
      heureDeDepart: j['heureDeDepart']?.toString() ?? '',
      destination: j['destination']?.toString() ?? '',
      typeVoyage: j['typeVoyage']?.toString() ?? 'standard',
      vendus: asInt(j['vendus']),
      capacite: asInt(j['capacite']),
      restantes: asInt(j['restantes']),
      embarques: asInt(j['embarques']),
      surReservation: asBool(j['surReservation']),
    );
  }

  double get taux => capacite > 0 ? vendus / capacite : 0;

  // Libelle utilise sur l'axe X du diagramme comparatif : heure + destination
  // courte, pour eviter que deux departs a la meme heure (destinations
  // differentes) ne partagent la meme categorie.
  String get labelChart {
    final dest = destination.length > 10
        ? '${destination.substring(0, 9)}.'
        : destination;
    return '$heureDeDepart\n$dest';
  }
}

// ── Jauge de remplissage ───────────────────────────────────────────────────────
class _JaugeRemplissage extends StatelessWidget {
  const _JaugeRemplissage({required this.depart});
  final DepartVue depart;

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final bool alerte = depart.surReservation;
    final double valeur = alerte ? 1.0 : depart.taux.clamp(0.0, 1.0);
    final Color couleur = alerte ? Colors.red : c.homeTabSelected;
    final String pourcentage = '${(depart.taux * 100).clamp(0, 999).toStringAsFixed(0)} %';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: valeur,
            minHeight: 10,
            backgroundColor: c.homeBandeauBackground,
            color: couleur,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$pourcentage  •  ${depart.vendus} / ${depart.capacite} places',
          style: TextStyle(fontSize: 11, color: c.homeTextPrimary),
        ),
        Text(
          'restantes : ${depart.restantes}',
          style: TextStyle(
            fontSize: 11,
            color: c.homeTextPrimary.withValues(alpha: 0.7),
          ),
        ),
        if (alerte)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'SURRESERVATION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Carte depart (mode etroit) ────────────────────────────────────────────────
class _CarteDepart extends StatelessWidget {
  const _CarteDepart({required this.depart});
  final DepartVue depart;

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final bool estVip = depart.typeVoyage.toLowerCase() == 'vip';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${depart.heureDeDepart}  →  ${depart.destination}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estVip
                        ? Config.colors.jauneFonce.withValues(alpha: 0.25)
                        : Config.colors.homeBandeauBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estVip ? 'VIP' : 'STANDARD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: estVip
                          ? Config.colors.jauneFonce
                          : Config.colors.homeTabSelected,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _JaugeRemplissage(depart: depart),
            const SizedBox(height: 6),
            Text(
              'Embarques : ${depart.embarques}',
              style: TextStyle(fontSize: 12, color: c.homeTextPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

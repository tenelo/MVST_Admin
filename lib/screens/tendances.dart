import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Tendances extends StatefulWidget {
  const Tendances({super.key, required this.gare, required this.uid});
  final String gare;
  final String uid;

  @override
  State<Tendances> createState() => _TendancesState();
}

class _TendancesState extends State<Tendances> {
  bool _isLoading = true;
  String? _erreur;
  int _nbJours = 30;
  DateTime _dateFin = DateTime.now();
  int _metriqueIndex = 0; // 0 = Vendus, 1 = Recettes, 2 = Embarques

  List<JourCourbe> _courbeParJour = [];
  Map<String, dynamic>? _comparaisonCourant;
  Map<String, dynamic>? _comparaisonPrecedent;
  double? _variationVendusPct;
  double? _variationRecettesPct;
  List<Map<String, dynamic>> _parDestination = [];
  List<Map<String, dynamic>> _parType = [];
  List<Map<String, dynamic>> _parHeure = [];
  int _actifsFenetreMois = 0;
  int _actifsNombre = 0;

  static const List<String> _metriquesLabels = [
    'Vendus',
    'Recettes',
    'Embarques',
  ];

  @override
  void initState() {
    super.initState();
    _getDonnees();
  }

  // ── Charger les tendances via PHP ──────────────────────────────────────────
  Future<void> _getDonnees() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _erreur = null;
      });
    }
    try {
      final response = await ApiClient.instance.post(
        'tendances_gare.php',
        body: {
          'gare': widget.gare,
          'date': DateFormat('yyyy-MM-dd').format(_dateFin),
          'nbJours': _nbJours,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _courbeParJour = List<Map<String, dynamic>>.from(
                data['courbeParJour'] ?? [],
              ).map((j) => JourCourbe.fromJson(j)).toList();

              final comparaison = Map<String, dynamic>.from(
                data['comparaison'] ?? {},
              );
              _comparaisonCourant = Map<String, dynamic>.from(
                comparaison['courant'] ?? {},
              );
              _comparaisonPrecedent = Map<String, dynamic>.from(
                comparaison['precedent'] ?? {},
              );
              _variationVendusPct = _asDoubleOrNull(
                comparaison['variationVendusPct'],
              );
              _variationRecettesPct = _asDoubleOrNull(
                comparaison['variationRecettesPct'],
              );

              final repartitions = Map<String, dynamic>.from(
                data['repartitions'] ?? {},
              );
              _parDestination = List<Map<String, dynamic>>.from(
                repartitions['parDestination'] ?? [],
              );
              _parType = List<Map<String, dynamic>>.from(
                repartitions['parType'] ?? [],
              );
              _parHeure = List<Map<String, dynamic>>.from(
                repartitions['parHeure'] ?? [],
              );

              final actifs = Map<String, dynamic>.from(data['actifs'] ?? {});
              _actifsFenetreMois = _asInt(actifs['fenetreMois']);
              _actifsNombre = _asInt(actifs['nombre']);

              _isLoading = false;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _erreur = 'Erreur lors du chargement des tendances.';
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

  static int _asInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  static double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  bool get _estVide => _courbeParJour.isEmpty;

  // ── Selecteur de date de fin (motif ticketsDuJourScannes._choisirDate) ─────
  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFin,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && mounted) {
      setState(() => _dateFin = picked);
      _getDonnees();
    }
  }

  void _choisirPeriode(int nbJours) {
    if (nbJours == _nbJours) return;
    setState(() => _nbJours = nbJours);
    _getDonnees();
  }

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
          'Tendances - ${widget.gare}',
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
              DateFormat('EEE d MMM', 'fr_FR').format(_dateFin),
              style: TextStyle(
                color: c.jauneBlanc,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
        const SizedBox(height: 40),
        _buildSelecteurPeriode(),
        const SizedBox(height: 60),
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
        const SizedBox(height: 20),
        _buildSelecteurPeriode(),
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: Config.colors.homeTabUnselected,
              ),
              const SizedBox(height: 12),
              Text(
                'Aucune donnee sur cette periode',
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
      // A) Selecteur de periode
      _buildSelecteurPeriode(),
      const SizedBox(height: 20),
      // B) Comparaison
      _buildComparaison(),
      const SizedBox(height: 24),
      // C) Courbe (selecteur de metrique + graphe)
      _buildSelecteurMetrique(),
      const SizedBox(height: 8),
      _buildCourbe(),
      const SizedBox(height: 24),
      // D) Repartitions
      Text(
        'Repartitions',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Config.colors.homeTextPrimary,
        ),
      ),
      const SizedBox(height: 8),
      _buildRepartitions(large),
      const SizedBox(height: 24),
      // E) Actifs
      _buildActifs(),
    ];
  }

  // ── A) Selecteur de periode ─────────────────────────────────────────────────
  Widget _buildSelecteurPeriode() {
    return Center(
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 7, label: Text('7 jours')),
          ButtonSegment(value: 30, label: Text('30 jours')),
          ButtonSegment(value: 90, label: Text('90 jours')),
        ],
        selected: {_nbJours},
        onSelectionChanged: (s) => _choisirPeriode(s.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: Config.colors.homeButtonPrimary,
          selectedForegroundColor: Colors.white,
        ),
      ),
    );
  }

  // ── B) Comparaison courant / precedent ──────────────────────────────────────
  // Bornes des 2 periodes comparees, memes formules que le backend.
  String _intervalle(DateTime a, DateTime b) =>
      '${DateFormat('d MMM', 'fr_FR').format(a)} - ${DateFormat('d MMM', 'fr_FR').format(b)}';

  Widget _buildComparaison() {
    final c = Config.colors;
    final courantVendus = _asInt(_comparaisonCourant?['vendus']);
    final courantRecettes =
        _asDoubleOrNull(_comparaisonCourant?['recettes']) ?? 0;
    final courantEmbarques = _asInt(_comparaisonCourant?['embarques']);

    final precedentVendus = _asInt(_comparaisonPrecedent?['vendus']);
    final precedentRecettes =
        _asDoubleOrNull(_comparaisonPrecedent?['recettes']) ?? 0;
    final precedentEmbarques = _asInt(_comparaisonPrecedent?['embarques']);

    final fin = _dateFin;
    final courantDebut = _dateFin.subtract(Duration(days: _nbJours - 1));
    final precedentFin = _dateFin.subtract(Duration(days: _nbJours));
    final precedentDebut = _dateFin.subtract(Duration(days: 2 * _nbJours - 1));

    return Card(
      color: c.homeCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparaison',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: c.homeTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _blocPeriode(
                    titre: 'Periode precedente',
                    sousTitre: _intervalle(precedentDebut, precedentFin),
                    vendus: precedentVendus,
                    recettes: precedentRecettes,
                    embarques: precedentEmbarques,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _blocPeriode(
                    titre: 'Periode courante',
                    sousTitre: _intervalle(courantDebut, fin),
                    vendus: courantVendus,
                    recettes: courantRecettes,
                    embarques: courantEmbarques,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _puceVariation('Vendus', _variationVendusPct)),
                const SizedBox(width: 12),
                Expanded(
                  child: _puceVariation('Recettes', _variationRecettesPct),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocPeriode({
    required String titre,
    required String sousTitre,
    required int vendus,
    required double recettes,
    required int embarques,
  }) {
    final c = Config.colors;
    final recettesStr =
        '${NumberFormat('#,##0', 'fr_FR').format(recettes)} FCFA';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.homeBandeauBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.homeBandeauBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: c.homeTextPrimary,
            ),
          ),
          Text(
            sousTitre,
            style: TextStyle(
              fontSize: 10,
              color: c.homeTextPrimary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vendus : $vendus',
            style: TextStyle(fontSize: 12, color: c.homeTextPrimary),
          ),
          Text(
            recettesStr,
            style: TextStyle(fontSize: 12, color: c.homeTextPrimary),
          ),
          Text(
            'Embarques : $embarques',
            style: TextStyle(fontSize: 12, color: c.homeTextPrimary),
          ),
        ],
      ),
    );
  }

  Widget _puceVariation(String libelle, double? pct) {
    final c = Config.colors;
    final Color couleur;
    final IconData icone;
    final String valeur;
    if (pct == null) {
      couleur = c.homeTabUnselected;
      icone = Icons.remove;
      valeur = 'n/a';
    } else if (pct > 0) {
      couleur = Colors.green;
      icone = Icons.arrow_upward;
      valeur = '${pct.toStringAsFixed(1)} %';
    } else if (pct < 0) {
      couleur = Colors.red;
      icone = Icons.arrow_downward;
      valeur = '${pct.toStringAsFixed(1)} %';
    } else {
      couleur = c.homeTabUnselected;
      icone = Icons.remove;
      valeur = '${pct.toStringAsFixed(1)} %';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 16, color: couleur),
          const SizedBox(width: 6),
          Text(
            '$libelle $valeur',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }

  // ── C) Selecteur de metrique + courbe (motif Syncfusion diagrammeABarres) ──
  Widget _buildSelecteurMetrique() {
    final c = Config.colors;
    return Wrap(
      spacing: 8,
      children: List.generate(_metriquesLabels.length, (i) {
        final selected = i == _metriqueIndex;
        return ChoiceChip(
          label: Text(_metriquesLabels[i]),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => setState(() => _metriqueIndex = i),
          selectedColor: c.homeButtonPrimary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : c.homeTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        );
      }),
    );
  }

  Widget _buildCourbe() {
    final bool sur90 = _nbJours == 90;
    final double interval = sur90 ? 6 : (_nbJours == 30 ? 3 : 1);
    return SizedBox(
      height: 280,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          labelRotation: sur90 ? 45 : 0,
          interval: interval,
        ),
        primaryYAxis: const NumericAxis(
          majorGridLines: MajorGridLines(width: 0.5),
        ),
        title: ChartTitle(
          text: 'Evolution : ${_metriquesLabels[_metriqueIndex]}',
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Config.colors.bleuA,
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<JourCourbe, String>>[
          LineSeries<JourCourbe, String>(
            name: _metriquesLabels[_metriqueIndex],
            dataSource: _courbeParJour,
            xValueMapper: (d, _) => d.jourCourt,
            yValueMapper: (d, _) => d.valeurPour(_metriqueIndex),
            color: Config.colors.bleuA,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  // ── D) Repartitions (3 graphes Syncfusion) ──────────────────────────────────
  Widget _buildRepartitions(bool large) {
    final graphes = [
      _buildGraphDestination(),
      _buildGraphType(),
      _buildGraphHeure(),
    ];
    if (!large) {
      return Column(
        children: graphes
            .map(
              (w) =>
                  Padding(padding: const EdgeInsets.only(bottom: 16), child: w),
            )
            .toList(),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: graphes.map((w) => SizedBox(width: 340, child: w)).toList(),
    );
  }

  Widget _buildGraphDestination() {
    return SizedBox(
      height: 260,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 11)),
        primaryYAxis: const NumericAxis(
          majorGridLines: MajorGridLines(width: 0.5),
        ),
        title: ChartTitle(
          text: 'Vendus par destination',
          textStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Config.colors.bleuA,
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<Map<String, dynamic>, String>>[
          BarSeries<Map<String, dynamic>, String>(
            name: 'Vendus',
            dataSource: _parDestination,
            xValueMapper: (m, _) => m['destination']?.toString() ?? '',
            yValueMapper: (m, _) => _asInt(m['vendus']),
            color: Config.colors.bleuA,
            borderRadius: BorderRadius.circular(4),
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphType() {
    return SizedBox(
      height: 260,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 11)),
        primaryYAxis: const NumericAxis(
          majorGridLines: MajorGridLines(width: 0.5),
        ),
        title: ChartTitle(
          text: 'Vendus par type',
          textStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Config.colors.bleuA,
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<Map<String, dynamic>, String>>[
          ColumnSeries<Map<String, dynamic>, String>(
            name: 'Vendus',
            dataSource: _parType,
            xValueMapper: (m, _) =>
                (m['typeVoyage']?.toString() ?? 'standard').toUpperCase(),
            yValueMapper: (m, _) => _asInt(m['vendus']),
            color: Config.colors.jauneFonce,
            borderRadius: BorderRadius.circular(4),
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphHeure() {
    return SizedBox(
      height: 260,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 10)),
        primaryYAxis: const NumericAxis(
          majorGridLines: MajorGridLines(width: 0.5),
        ),
        title: ChartTitle(
          text: 'Vendus par heure',
          textStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Config.colors.bleuA,
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<Map<String, dynamic>, String>>[
          ColumnSeries<Map<String, dynamic>, String>(
            name: 'Vendus',
            dataSource: _parHeure,
            xValueMapper: (m, _) => m['heure']?.toString() ?? '',
            yValueMapper: (m, _) => _asInt(m['vendus']),
            color: Config.colors.vertA,
            borderRadius: BorderRadius.circular(4),
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  // ── E) Actifs ────────────────────────────────────────────────────────────────
  Widget _buildActifs() {
    final c = Config.colors;
    return Card(
      color: c.homeCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.people_alt_outlined, size: 36, color: c.homeTabSelected),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_actifsNombre clients actifs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.homeTextPrimary,
                    ),
                  ),
                  Text(
                    'sur les $_actifsFenetreMois derniers mois',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.homeTextPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modele courbe ─────────────────────────────────────────────────────────────
class JourCourbe {
  JourCourbe({
    required this.jour,
    required this.vendus,
    required this.recettes,
    required this.embarques,
  });

  final String jour;
  final int vendus;
  final double recettes;
  final int embarques;

  factory JourCourbe.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
    return JourCourbe(
      jour: j['jour']?.toString() ?? '',
      vendus: asInt(j['vendus']),
      recettes: asDouble(j['recettes']),
      embarques: asInt(j['embarques']),
    );
  }

  num valeurPour(int metriqueIndex) {
    switch (metriqueIndex) {
      case 1:
        return recettes;
      case 2:
        return embarques;
      case 0:
      default:
        return vendus;
    }
  }

  // Libelle court pour l'axe X (ex. '3/9') ; retombe sur le champ brut si le
  // format renvoye par le serveur n'est pas une date ISO parseable.
  String get jourCourt {
    try {
      final d = DateTime.parse(jour);
      return '${d.day}/${d.month}';
    } catch (_) {
      return jour;
    }
  }
}

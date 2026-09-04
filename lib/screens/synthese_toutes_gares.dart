import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/screens/synthese_du_jour.dart';
import 'package:mvst_admin/services/api_client.dart';

class SyntheseToutesGares extends StatefulWidget {
  const SyntheseToutesGares({super.key, required this.uid});
  final String uid;

  @override
  State<SyntheseToutesGares> createState() => _SyntheseToutesGaresState();
}

class _SyntheseToutesGaresState extends State<SyntheseToutesGares> {
  bool _isLoading = true;
  String? _erreur;
  bool _accesRefuse = false;
  DateTime _dateSelectionnee = DateTime.now();
  List<GareSynthese> _lignes = [];
  GareSynthese? _totaux;

  @override
  void initState() {
    super.initState();
    _getDonnees();
  }

  // ── Charger la liste des gares + la synthese du jour choisi ────────────────
  Future<void> _getDonnees() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _erreur = null;
        _accesRefuse = false;
      });
    }
    try {
      final String dateChoisie = DateFormat(
        'yyyy-MM-dd',
      ).format(_dateSelectionnee);

      final resultats = await Future.wait([
        ApiClient.instance.get('gares.php'),
        ApiClient.instance.post(
          'synthese_toutes_gares.php',
          body: {'date': dateChoisie},
        ),
      ]);

      final respGares = resultats[0];
      final respSynthese = resultats[1];

      if (respGares.statusCode != 200) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _erreur = 'Erreur lors du chargement des gares.';
          });
        }
        return;
      }
      final dataGares = jsonDecode(respGares.body);
      if (dataGares['success'] != true) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _erreur = 'Erreur lors du chargement des gares.';
          });
        }
        return;
      }
      final List<String> toutesLesGares = List<Map<String, dynamic>>.from(
        dataGares['gares'],
      ).map((g) => g['gare'].toString()).toList();

      if (respSynthese.statusCode != 200) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _erreur = 'Erreur lors du chargement de la synthese.';
          });
        }
        return;
      }
      final dataSynthese = jsonDecode(respSynthese.body);
      if (dataSynthese['success'] != true) {
        // Defense : un non-superadmin qui atteindrait cet ecran verrait ce
        // message au lieu du tableau (jamais de crash).
        if (mounted) {
          setState(() {
            _isLoading = false;
            _accesRefuse = true;
          });
        }
        return;
      }

      // Croisement : la liste COMPLETE des gares (gares.php), enrichie des
      // chiffres du jour quand la gare est active, sinon ligne a 0.
      final Map<String, Map<String, dynamic>> parGare = {
        for (final g in List<Map<String, dynamic>>.from(
          dataSynthese['gares'] ?? [],
        ))
          g['gare'].toString(): g,
      };

      final lignes = toutesLesGares
          .map(
            (nomGare) => GareSynthese.fromJsonOuVide(nomGare, parGare[nomGare]),
          )
          .toList();
      lignes.sort((a, b) => b.vendus.compareTo(a.vendus));

      final totaux = GareSynthese.fromJsonOuVide(
        'TOTAL',
        Map<String, dynamic>.from(dataSynthese['totaux'] ?? {}),
      );

      if (mounted) {
        setState(() {
          _lignes = lignes;
          _totaux = totaux;
          _isLoading = false;
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

  void _ouvrirGare(String gare) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SyntheseDuJour(gare: gare, uid: widget.uid),
      ),
    );
  }

  String _recettesStr(double v) =>
      '${NumberFormat('#,##0', 'fr_FR').format(v)} FCFA';
  String _tauxStr(double v) => '${v.toStringAsFixed(1)} %';

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
          'Toutes les gares',
          style: TextStyle(
            color: c.jauneBlanc,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.6),
          child: Container(color: c.jauneBlanc, height: 0.6),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: c.authCardBackground,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: _choisirDate,
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    color: c.jauneBlanc,
                  ),
                  label: Text(
                    DateFormat('EEE d MMM', 'fr_FR').format(_dateSelectionnee),
                    style: TextStyle(
                      color: c.jauneBlanc,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
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
          ),
        ],
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
    if (_accesRefuse) {
      return [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.lock_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(
                'Acces reserve au superadmin',
                textAlign: TextAlign.center,
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
    if (_lignes.isEmpty) {
      return [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 48,
                color: Config.colors.homeTabUnselected,
              ),
              const SizedBox(height: 12),
              Text(
                'Aucune gare configuree',
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
    return large ? [_buildTableauLarge()] : _buildListeEtroite();
  }

  // ── Tableau (large) ─────────────────────────────────────────────────────────
  Widget _buildTableauLarge() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Gare')),
          DataColumn(label: Text('Vendus'), numeric: true),
          DataColumn(label: Text('Recettes'), numeric: true),
          DataColumn(label: Text('Scannes'), numeric: true),
          DataColumn(label: Text('Taux')),
        ],
        rows: [
          for (final g in _lignes)
            DataRow(
              onSelectChanged: (_) => _ouvrirGare(g.gare),
              cells: [
                DataCell(Text(g.gare)),
                DataCell(Text('${g.vendus}')),
                DataCell(Text(_recettesStr(g.recettes))),
                DataCell(Text('${g.scannes}')),
                DataCell(Text(_tauxStr(g.taux))),
              ],
            ),
          if (_totaux != null)
            DataRow(
              color: WidgetStateProperty.all(
                Config.colors.homeBandeauBackground,
              ),
              cells: [
                DataCell(
                  Text(
                    'TOTAL',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    '${_totaux!.vendus}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    _recettesStr(_totaux!.recettes),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    '${_totaux!.scannes}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    _tauxStr(_totaux!.taux),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Liste empilee (etroit) ───────────────────────────────────────────────────
  List<Widget> _buildListeEtroite() {
    return [
      ..._lignes.map(
        (g) => _CarteGare(
          gare: g,
          recettesStr: _recettesStr(g.recettes),
          tauxStr: _tauxStr(g.taux),
          onTap: () => _ouvrirGare(g.gare),
        ),
      ),
      if (_totaux != null)
        Card(
          color: Config.colors.homeBandeauBackground,
          margin: const EdgeInsets.only(top: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_totaux!.vendus} vendus  •  ${_recettesStr(_totaux!.recettes)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

// ── Modele ─────────────────────────────────────────────────────────────────────
class GareSynthese {
  GareSynthese({
    required this.gare,
    required this.vendus,
    required this.recettes,
    required this.scannes,
    required this.taux,
  });

  final String gare;
  final int vendus;
  final double recettes;
  final int scannes;
  final double taux;

  factory GareSynthese.fromJsonOuVide(String nomGare, Map<String, dynamic>? j) {
    int asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
    if (j == null) {
      return GareSynthese(
        gare: nomGare,
        vendus: 0,
        recettes: 0,
        scannes: 0,
        taux: 0,
      );
    }
    return GareSynthese(
      gare: nomGare,
      vendus: asInt(j['vendus']),
      recettes: asDouble(j['recettes']),
      scannes: asInt(j['scannes']),
      taux: asDouble(j['tauxEmbarquement']),
    );
  }
}

// ── Carte gare (mode etroit) ───────────────────────────────────────────────────
class _CarteGare extends StatelessWidget {
  const _CarteGare({
    required this.gare,
    required this.recettesStr,
    required this.tauxStr,
    required this.onTap,
  });
  final GareSynthese gare;
  final String recettesStr;
  final String tauxStr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          gare.gare,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Vendus ${gare.vendus} • Scannes ${gare.scannes} • Taux $tauxStr',
        ),
        trailing: Text(
          recettesStr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: c.homeTabSelected,
          ),
        ),
      ),
    );
  }
}

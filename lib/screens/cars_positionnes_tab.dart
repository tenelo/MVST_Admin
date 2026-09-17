import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';

class CarPositionne {
  final int id;
  final String depart;
  final String destination;
  final String date;
  final String heure;
  final String type;
  final int numeroCar;
  final String documentId;
  final int vendus;
  final int capacite;
  final int seuil;
  final bool plein;
  final String? idAdmin;
  final String? nomAdmin;
  final String? dateCreation;
  final String dateIso;
  final String ligne;

  CarPositionne({
    required this.id,
    required this.depart,
    required this.destination,
    required this.date,
    required this.heure,
    required this.type,
    required this.numeroCar,
    required this.documentId,
    required this.vendus,
    required this.capacite,
    required this.seuil,
    required this.plein,
    this.idAdmin,
    this.nomAdmin,
    this.dateCreation,
    required this.dateIso,
    required this.ligne,
  });

  factory CarPositionne.fromJson(Map<String, dynamic> json) {
    return CarPositionne(
      id: (json['id'] as num?)?.toInt() ?? 0,
      depart: (json['depart'] ?? '').toString(),
      destination: (json['destination'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      heure: (json['heure'] ?? '').toString(),
      type: (json['type'] ?? 'standard').toString(),
      numeroCar: (json['numeroCar'] as num?)?.toInt() ?? 0,
      documentId: (json['documentId'] ?? '').toString(),
      vendus: (json['vendus'] as num?)?.toInt() ?? 0,
      capacite: (json['capacite'] as num?)?.toInt() ?? 0,
      seuil: (json['seuil'] as num?)?.toInt() ?? 0,
      plein: (json['plein'] as bool?) ?? false,
      idAdmin: json['idAdmin']?.toString(),
      nomAdmin: json['nomAdmin']?.toString(),
      dateCreation: json['dateCreation']?.toString(),
      dateIso: (json['date_iso'] ?? '').toString(),
      ligne: (json['ligne'] ?? '').toString(),
    );
  }
}

class CarsPositionnesTab extends StatefulWidget {
  const CarsPositionnesTab({super.key});

  @override
  State<CarsPositionnesTab> createState() => _CarsPositionnesTabState();
}

class _CarsPositionnesTabState extends State<CarsPositionnesTab> {
  DateTime? _dateFiltre;
  String _typeFiltre = 'all';

  bool _chargementInitial = true;
  String? _erreur;
  List<CarPositionne> _liste = [];
  String _debugInfo = '';

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
      _chargementInitial = true;
      _erreur = null;
    });

    try {
      final body = <String, dynamic>{};

      if (_dateFiltre != null) {
        body['date'] = DateFormat('yyyy-MM-dd').format(_dateFiltre!);
      } else {
        body['dateDebut'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }

      if (_typeFiltre != 'all') {
        body['type'] = _typeFiltre;
      }

      final resp = await ApiClient.instance.post(
        'listerTousCars.php',
        body: body,
      );

      final debugBody = jsonEncode(body);
      final debugResponse = resp.body.length > 500
          ? '${resp.body.substring(0, 500)}...'
          : resp.body;

      final data = jsonDecode(resp.body);
      if (!mounted) return;

      _debugInfo =
          'body envoyé: $debugBody\n'
          'status HTTP: ${resp.statusCode}\n'
          'body brut: $debugResponse\n'
          'resultat: success=${data['success']}, total=${data['total']}, cars!=null=${data['cars'] != null}';

      if (data['success'] == true) {
        final cars = data['cars'] is List
            ? data['cars'] as List
            : const <dynamic>[];

        final parsed = cars
            .map(
              (item) => CarPositionne.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .where((c) => c.dateIso.isNotEmpty)
            .toList();

        setState(() {
          _liste = parsed;
          _erreur = null;
          _chargementInitial = false;
        });

        final groupCount = _groupes.length;
        final firstKey = _liste.isNotEmpty && groupCount == 0
            ? '${_liste.first.depart}|${_liste.first.destination}|${_liste.first.dateIso}|${_liste.first.heure}|${_liste.first.type}'
            : 'n/a';

        _debugInfo =
            '$_debugInfo\n'
            '_liste.length=${_liste.length}\n'
            '_groupes.length=$groupCount\n'
            'first_key_if_no_group=$firstKey';
      } else {
        final msg = data['message']?.toString() ?? 'Erreur de chargement.';
        setState(() {
          _erreur = msg;
          _chargementInitial = false;
        });
        _snack(msg, Colors.red);
      }
    } catch (e, stack) {
      if (!mounted) return;

      _debugInfo =
          'EXCEPTION: $e\nStack: ${stack.toString().split('\n').take(3).join('\n')}';

      setState(() {
        _erreur = 'Erreur réseau: $e';
        _chargementInitial = false;
      });

      debugPrint('=== CARS ERROR ===');
      debugPrint('exception: $e');
      debugPrint('stack: $stack');

      _snack('Erreur réseau', Colors.red);
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

  Future<void> _choisirDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFiltre ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (picked != null && mounted) {
      setState(() => _dateFiltre = picked);
      await _charger();
    }
  }

  Map<String, List<CarPositionne>> get _groupes {
    final groups = <String, List<CarPositionne>>{};

    for (final car in _liste) {
      final key =
          '${car.depart}|${car.destination}|${car.dateIso}|${car.heure}|${car.type}';
      groups.putIfAbsent(key, () => <CarPositionne>[]).add(car);
    }

    final orderedKeys = groups.keys.toList()
      ..sort((a, b) {
        final left = a.split('|');
        final right = b.split('|');

        final leftDate = left[2];
        final rightDate = right[2];
        final dateCompare = leftDate.compareTo(rightDate);
        if (dateCompare != 0) return dateCompare;

        final leftHeure = left[3];
        final rightHeure = right[3];
        return leftHeure.compareTo(rightHeure);
      });

    final result = <String, List<CarPositionne>>{};
    for (final key in orderedKeys) {
      result[key] = groups[key]!;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;

    if (_chargementInitial) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: CircularProgressIndicator(color: c.authAccent),
            ),
          ),
        ],
      );
    }

    if (_erreur != null) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _erreur!,
                    style: TextStyle(color: c.authTextPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.authAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _charger,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: c.authAccent,
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFilters(c),
          const SizedBox(height: 12),
          if (_liste.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_bus,
                      //color: c.authTextPrimary.withValues(alpha: 0.4),
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun car positionné pour ce filtre',
                      style: TextStyle(
                        //color: c.authTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._buildGroupes(c),
        ],
      ),
    );
  }

  Widget _buildFilters(dynamic c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _choisirDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: c.authCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.authBorder, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: c.authAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dateFiltre == null
                          ? 'Toutes les dates à venir'
                          : DateFormat(
                              'EEEE d MMMM y',
                              'fr_FR',
                            ).format(_dateFiltre!),
                      style: TextStyle(color: c.authTextPrimary),
                    ),
                  ),
                  if (_dateFiltre != null)
                    GestureDetector(
                      onTap: () async {
                        setState(() => _dateFiltre = null);
                        await _charger();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: c.authCardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.authBorder, width: 1.5),
                        ),
                        child: Icon(Icons.clear, color: c.authAccent, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _chipType('all', 'Tous', c)),
            const SizedBox(width: 8),
            Expanded(child: _chipType('standard', 'Standard', c)),
            const SizedBox(width: 8),
            Expanded(child: _chipType('vip', 'VIP', c)),
          ],
        ),
      ],
    );
  }

  Widget _chipType(String valeur, String label, dynamic c) {
    final actif = _typeFiltre == valeur;
    return GestureDetector(
      onTap: () async {
        if (_typeFiltre == valeur) return;
        setState(() => _typeFiltre = valeur);
        await _charger();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
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

  String _formatDateLisible(String dateIso) {
    if (dateIso.isEmpty) return 'Date inconnue';
    try {
      final d = DateTime.parse(dateIso);
      return DateFormat('EEEE d MMMM y', 'fr_FR').format(d);
    } catch (_) {
      return dateIso;
    }
  }

  List<Widget> _buildGroupes(dynamic c) {
    final widgets = <Widget>[];
    final groupes = _groupes;

    for (final entry in groupes.entries) {
      final parts = entry.key.split('|');
      final depart = parts[0];
      final destination = parts[1];
      final dateIso = parts[2];
      final heure = parts[3];
      final type = parts[4];

      final ligne = entry.value.first.ligne.isNotEmpty
          ? entry.value.first.ligne
          : '$depart → $destination';

      final dateLisible = _formatDateLisible(dateIso);

      widgets.add(
        Container(
          decoration: BoxDecoration(
            color: c.authCardBackground.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ligne,
                      style: TextStyle(
                        color: c.authTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateLisible · $heure',
                      style: TextStyle(
                        color: c.authTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: type == 'vip' ? c.jauneBlanc : c.authAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    color: type == 'vip' ? c.authCardBackground : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      for (final car in entry.value) {
        widgets.add(
          Container(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.authAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Car n°${car.numeroCar}',
                        style: TextStyle(
                          color: c.authAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (car.plein)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PLEIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                      ),
                      tooltip: 'Retirer ce car',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _retirerCar(car),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${car.vendus} / ${car.seuil}',
                        style: TextStyle(
                          color: c.authTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value:
                      ((car.seuil > 0 ? (car.vendus / car.seuil) : 0)
                              .toDouble())
                          .clamp(0.0, 1.0),
                  color: car.plein ? const Color(0xFFEF4444) : c.authAccent,
                  backgroundColor: c.authBorder.withOpacity(0.4),
                  minHeight: 6,
                ),
                const SizedBox(height: 8),
                Text(
                  'Capacité : ${car.capacite} · Ajouté par ${car.nomAdmin ?? '—'}'
                  '${_formatDateCreation(car.dateCreation)}',
                  style: TextStyle(color: c.authTextSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Future<void> _retirerCar(CarPositionne car) async {
    final c = Config.colors;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.authCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Retirer ce car ?',
          style: TextStyle(
            color: c.authTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Car n°${car.numeroCar} — ${car.ligne.isNotEmpty ? car.ligne : '${car.depart} ${car.destination}'} · ${car.heure}.\n\n'
          'Le retrait est impossible si des billets ont déjà été vendus sur ce car.',
          style: TextStyle(color: c.authTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: c.authTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Retirer',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      final resp = await ApiClient.instance.post(
        'retirerCar.php',
        body: {'id': car.id},
      );
      final data = jsonDecode(resp.body);
      if (!mounted) return;
      if (data['success'] == true) {
        _snack(
          data['message']?.toString() ?? 'Car retiré.',
          const Color(0xFF10B981),
        );
        await _charger();
      } else {
        _snack(
          data['message']?.toString() ?? 'Suppression impossible',
          Colors.red,
        );
      }
    } catch (_) {
      if (mounted) _snack('Erreur réseau. Réessayez.', Colors.red);
    }
  }

  String _formatDateCreation(String? dateCreation) {
    if (dateCreation == null || dateCreation.isEmpty) return '';
    try {
      final parsed = DateTime.tryParse(dateCreation);
      if (parsed == null) return '';
      return ' · ${DateFormat('dd/MM/yy HH:mm').format(parsed)}';
    } catch (_) {
      return '';
    }
  }
}

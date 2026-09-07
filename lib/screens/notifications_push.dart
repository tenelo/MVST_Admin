import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';

// Cibles de diffusion (valeur backend + libelle affiche).
const List<_Cible> _cibles = [
  _Cible('tous', 'Tous les utilisateurs', Icons.groups_outlined),
  _Cible('actifs', 'Utilisateurs actifs', Icons.person_pin_circle_outlined),
  _Cible('recents', 'Voyageurs recents', Icons.history_toggle_off_outlined),
  _Cible('bloques', 'Comptes bloques', Icons.block_outlined),
  _Cible('gare', 'Par gare (residence)', Icons.location_on_outlined),
  _Cible('selection', 'Selection manuelle', Icons.checklist_outlined),
];

class _Cible {
  final String valeur;
  final String label;
  final IconData icon;
  const _Cible(this.valeur, this.label, this.icon);
}

class NotificationsPush extends StatefulWidget {
  const NotificationsPush({super.key, this.prefill});

  // Prefill optionnel pour "modifier puis renvoyer" depuis l'historique.
  final Map<String, dynamic>? prefill;

  @override
  State<NotificationsPush> createState() => _NotificationsPushState();
}

class _NotificationsPushState extends State<NotificationsPush>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _titreCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  String _cible = 'tous';
  String? _gareSelectionnee;
  List<String> _listeGares = [];

  final TextEditingController _rechercheCtrl = TextEditingController();
  List<Map<String, dynamic>> _resultatsRecherche = [];
  final Set<String> _selection = {};
  bool _rechercheEnCours = false;

  bool _envoiEnCours = false;

  List<Map<String, dynamic>> _historique = [];
  bool _historiqueEnCours = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recupererGares();
    if (widget.prefill != null) {
      _appliquerPrefill(widget.prefill!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titreCtrl.dispose();
    _messageCtrl.dispose();
    _rechercheCtrl.dispose();
    super.dispose();
  }

  void _appliquerPrefill(Map<String, dynamic> p) {
    _titreCtrl.text = p['titre']?.toString() ?? '';
    _messageCtrl.text = p['message']?.toString() ?? '';
    _cible = p['cible']?.toString() ?? 'tous';
    _gareSelectionnee = p['gare']?.toString();
    final ids = p['idUtilisateurs'];
    if (ids is String && ids.isNotEmpty) {
      try {
        final decoded = jsonDecode(ids);
        if (decoded is List) {
          _selection.addAll(decoded.map((e) => e.toString()));
        }
      } catch (_) {}
    }
  }

  Future<void> _recupererGares() async {
    try {
      final response = await ApiClient.instance.get('gares.php');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['gares'] is List) {
          if (mounted) {
            setState(() {
              _listeGares = List<String>.from(
                (data['gares'] as List).map(
                  (g) => g is Map ? g['gare'].toString() : g.toString(),
                ),
              );
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _rechercherUtilisateurs(String terme) async {
    if (terme.trim().isEmpty) {
      setState(() => _resultatsRecherche = []);
      return;
    }
    setState(() => _rechercheEnCours = true);
    try {
      final response = await ApiClient.instance.post(
        'rechercheUtilisateurs.php',
        body: {'terme': terme.trim()},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['utilisateurs'] is List) {
          setState(() {
            _resultatsRecherche = List<Map<String, dynamic>>.from(
              (data['utilisateurs'] as List).map(
                (u) => Map<String, dynamic>.from(u),
              ),
            );
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _rechercheEnCours = false);
    }
  }

  Map<String, dynamic> _construirePayload({bool avecContenu = true}) {
    final payload = <String, dynamic>{'cible': _cible};
    if (avecContenu) {
      payload['titre'] = _titreCtrl.text.trim();
      payload['message'] = _messageCtrl.text.trim();
    }
    if (_cible == 'gare' && _gareSelectionnee != null) {
      payload['gare'] = _gareSelectionnee;
    }
    if (_cible == 'selection') {
      payload['idUtilisateurs'] = _selection.toList();
    }
    return payload;
  }

  Future<void> _lancerEnvoi() async {
    final titre = _titreCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (titre.isEmpty || message.isEmpty) {
      _snack('Titre et message obligatoires.', Colors.red);
      return;
    }
    if (_cible == 'gare' &&
        (_gareSelectionnee == null || _gareSelectionnee!.isEmpty)) {
      _snack('Choisissez une gare.', Colors.red);
      return;
    }
    if (_cible == 'selection' && _selection.isEmpty) {
      _snack('Selectionnez au moins un utilisateur.', Colors.red);
      return;
    }

    setState(() => _envoiEnCours = true);

    int? destinataires;
    int? appareils;
    try {
      final resp = await ApiClient.instance.post(
        'compterNotificationDiffusion.php',
        body: _construirePayload(avecContenu: false),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        destinataires = data['destinataires'] as int?;
        appareils = data['appareils'] as int?;
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }
    setState(() => _envoiEnCours = false);

    final confirme = await _confirmerEnvoi(destinataires, appareils);
    if (confirme != true) return;

    setState(() => _envoiEnCours = true);
    try {
      final resp = await ApiClient.instance.post(
        'envoyerNotificationDiffusion.php',
        body: _construirePayload(),
      );
      final data = jsonDecode(resp.body);
      if (!mounted) return;
      if (data['success'] == true) {
        _snack(
          'Envoye : ${data['envoyes'] ?? 0} notification(s) sur ${data['destinataires'] ?? 0} destinataire(s).',
          const Color(0xFF10B981),
        );
        _titreCtrl.clear();
        _messageCtrl.clear();
        setState(() {
          _selection.clear();
          _resultatsRecherche = [];
          _rechercheCtrl.clear();
        });
      } else {
        _snack(data['message']?.toString() ?? 'Erreur inconnue.', Colors.red);
      }
    } catch (_) {
      if (mounted) _snack('Erreur reseau. Reessayez.', Colors.red);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  Future<bool?> _confirmerEnvoi(int? destinataires, int? appareils) {
    final c = Config.colors;
    final texte = destinataires == null
        ? 'Impossible d\'estimer le nombre de destinataires. Envoyer quand meme ?'
        : 'Cette notification touchera $destinataires destinataire(s), soit $appareils appareil(s) joignable(s). Confirmer l\'envoi ?';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.authCardBackground,
        title: Text(
          'Confirmer l\'envoi',
          style: TextStyle(color: c.jauneBlanc),
        ),
        content: Text(texte, style: TextStyle(color: Colors.white)),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Annuler',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Envoyer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _chargerHistorique() async {
    setState(() => _historiqueEnCours = true);
    try {
      final resp = await ApiClient.instance.post(
        'historiqueNotificationDiffusion.php',
        body: {},
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true && data['historique'] is List) {
        setState(() {
          _historique = List<Map<String, dynamic>>.from(
            (data['historique'] as List).map(
              (h) => Map<String, dynamic>.from(h),
            ),
          );
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _historiqueEnCours = false);
    }
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: bg, content: Text(msg)));
  }

  String _libelleCible(String valeur) {
    return _cibles
        .firstWhere((c) => c.valeur == valeur, orElse: () => _cibles.first)
        .label;
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Scaffold(
      backgroundColor: c.homeBackground,
      appBar: AppBar(
        backgroundColor: c.authCardBackground,
        iconTheme: IconThemeData(color: c.jauneBlanc),
        title: Text(
          'NOTIFICATIONS PUSH',
          style: TextStyle(
            color: c.jauneBlanc,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) {
            if (i == 1) _chargerHistorique();
          },
          labelColor: c.jauneBlanc,
          unselectedLabelColor: c.authTextSecondary,
          indicatorColor: c.jauneBlanc,
          tabs: const [
            Tab(text: 'Envoyer'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_ongletEnvoyer(c), _ongletHistorique(c)],
      ),
    );
  }

  Widget _ongletEnvoyer(dynamic c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titreCtrl,
            style: TextStyle(color: c.authCardBackground),
            decoration: InputDecoration(
              labelText: 'Titre',
              labelStyle: TextStyle(
                color: c.authCardBackground.withValues(alpha: 0.6),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            style: TextStyle(color: c.authCardBackground),
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Message',
              labelStyle: TextStyle(
                color: c.authCardBackground.withValues(alpha: 0.6),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cible',
            style: TextStyle(
              color: c.authCardBackground.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._cibles.map(
            (cible) => RadioListTile<String>(
              value: cible.valeur,
              groupValue: _cible,
              onChanged: (v) => setState(() => _cible = v ?? 'tous'),
              title: Text(
                cible.label,
                style: TextStyle(color: c.authCardBackground, fontSize: 14),
              ),
              secondary: Icon(cible.icon, color: c.authAccent, size: 20),
              activeColor: c.authAccent,
              dense: true,
            ),
          ),
          if (_cible == 'gare') _selecteurGare(c),
          if (_cible == 'selection') _selecteurUtilisateurs(c),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              onPressed: _envoiEnCours ? null : _lancerEnvoi,
              child: _envoiEnCours
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Envoyer la notification',
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
  }

  Widget _selecteurGare(dynamic c) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<String>(
        initialValue: _listeGares.contains(_gareSelectionnee)
            ? _gareSelectionnee
            : null,
        decoration: InputDecoration(
          labelText: 'Gare',
          labelStyle: TextStyle(
            color: c.authCardBackground.withValues(alpha: 0.6),
          ),
          border: const OutlineInputBorder(),
        ),
        dropdownColor: c.homeCardBackground,
        style: TextStyle(color: c.authCardBackground),
        items: _listeGares
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (v) => setState(() => _gareSelectionnee = v),
      ),
    );
  }

  Widget _selecteurUtilisateurs(dynamic c) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _rechercheCtrl,
            style: TextStyle(color: c.authCardBackground),
            decoration: InputDecoration(
              labelText: 'Rechercher (nom ou telephone)',
              labelStyle: TextStyle(
                color: c.authCardBackground.withValues(alpha: 0.6),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.search, color: c.authAccent),
                onPressed: () => _rechercherUtilisateurs(_rechercheCtrl.text),
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: _rechercherUtilisateurs,
          ),
          if (_selection.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_selection.length} selectionne(s)',
                style: TextStyle(color: c.authAccent, fontSize: 12),
              ),
            ),
          if (_rechercheEnCours)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          ..._resultatsRecherche.map((u) {
            final id = u['idUtilisateur']?.toString() ?? '';
            final selected = _selection.contains(id);
            return CheckboxListTile(
              value: selected,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selection.add(id);
                } else {
                  _selection.remove(id);
                }
              }),
              activeColor: c.authAccent,
              title: Text(
                '${u['nom'] ?? ''} ${u['prenoms'] ?? ''}'.trim(),
                style: TextStyle(color: c.authCardBackground, fontSize: 14),
              ),
              subtitle: Text(
                u['telephone']?.toString() ?? '',
                style: TextStyle(
                  color: c.authCardBackground.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              dense: true,
            );
          }),
        ],
      ),
    );
  }

  Widget _ongletHistorique(dynamic c) {
    if (_historiqueEnCours) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historique.isEmpty) {
      return Center(
        child: Text(
          'Aucune diffusion pour le moment.',
          style: TextStyle(color: c.authTextSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _chargerHistorique,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _historique.length,
        itemBuilder: (context, i) {
          final h = _historique[i];
          final date = h['dateEnvoi']?.toString() ?? '';
          String dateFmt = date;
          try {
            dateFmt = DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(DateTime.parse(date));
          } catch (_) {}
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.authCardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h['titre']?.toString() ?? '',
                  style: TextStyle(
                    color: c.jauneBlanc,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  h['message']?.toString() ?? '',
                  style: TextStyle(color: c.authTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.groups_outlined, color: c.authAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _libelleCible(h['cible']?.toString() ?? ''),
                      style: TextStyle(color: c.authAccent, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      '${h['envoyes'] ?? 0}/${h['destinataires'] ?? 0}',
                      style: TextStyle(
                        color: c.authTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      h['nomAdmin']?.toString() ?? '',
                      style: TextStyle(
                        color: c.authTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateFmt,
                      style: TextStyle(
                        color: c.authTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        Icons.copy_all_outlined,
                        color: c.authAccent,
                        size: 18,
                      ),
                      label: Text(
                        'Renvoyer / modifier',
                        style: TextStyle(color: c.authAccent, fontSize: 12),
                      ),
                      onPressed: () {
                        _tabController.animateTo(0);
                        setState(() => _appliquerPrefill(h));
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

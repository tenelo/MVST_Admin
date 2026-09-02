import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ── Constantes ────────────────────────────────────────────────────────────────
const String _prefsMasqueKey = 'suggestions_masquees';

// ── Catégories ────────────────────────────────────────────────────────────────
const List<_Categorie> _categories = [
  _Categorie('Toutes',        Icons.all_inbox_outlined),
  _Categorie('Amélioration',  Icons.build_circle_outlined),
  _Categorie('Problème',      Icons.warning_amber_outlined),
  _Categorie('Compliment',    Icons.star_outline_rounded),
  _Categorie('Autre',         Icons.chat_bubble_outline_rounded),
  _Categorie('Nouveau trajet',Icons.map_outlined),
];

class _Categorie {
  final String label;
  final IconData icon;
  const _Categorie(this.label, this.icon);
}

// ── Statuts ───────────────────────────────────────────────────────────────────
const Map<String, _StatutInfo> _statuts = {
  'en_attente': _StatutInfo('En attente', Color(0xFFF59E0B), Icons.hourglass_empty_rounded),
  'lu':         _StatutInfo('Lu',         Color(0xFF3B82F6), Icons.drafts_outlined),
  'traite':     _StatutInfo('Traité',     Color(0xFF10B981), Icons.check_circle_outline_rounded),
};

const List<String> _filtresStatut = ['tous', 'en_attente', 'lu', 'traite'];

class _StatutInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _StatutInfo(this.label, this.color, this.icon);
}

// ── Modèle ─────────────────────────────────────────────────────────────────
class _Suggestion {
  final int id;
  final String nom;
  final String telephone;
  final String message;
  final String categorie;
  final String idutilisateur;
  String statut;
  final DateTime createdat;

  _Suggestion({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.message,
    required this.categorie,
    required this.idutilisateur,
    required this.statut,
    required this.createdat,
  });

  factory _Suggestion.fromJson(Map<String, dynamic> j) => _Suggestion(
        id:            (j['id'] as num).toInt(),
        nom:           j['nom']           ?? '',
        telephone:     j['telephone']     ?? '',
        message:       j['message']       ?? '',
        categorie:     j['categorie']     ?? 'Autre',
        idutilisateur: j['idutilisateur'] ?? '',
        statut:        j['statut']        ?? 'en_attente',
        createdat:     DateTime.tryParse(j['createdat'] ?? '') ?? DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
class SuggestionsAdmin extends StatefulWidget {
  const SuggestionsAdmin({super.key});

  @override
  State<SuggestionsAdmin> createState() => _SuggestionsAdminState();
}

class _SuggestionsAdminState extends State<SuggestionsAdmin>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filtres
  String _categorieFiltre = 'Toutes';
  String _statutFiltre    = 'tous';
  DateTime? _dateDebut;
  DateTime? _dateFin;

  // Données
  List<_Suggestion> _suggestions   = [];
  Set<int> _idsMasques              = {};
  bool _isLoading                   = true;

  // Socket
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerIdsMasques().then((_) => _chargerSuggestions());
    _connecterSocket();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  // ── IDs masqués (SharedPreferences) ──────────────────────────────────────
  Future<void> _chargerIdsMasques() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList(_prefsMasqueKey) ?? [];
    setState(() => _idsMasques = list.map(int.parse).toSet());
  }

  Future<void> _masquer(int id) async {
    setState(() => _idsMasques.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsMasqueKey, _idsMasques.map((e) => '$e').toList());
  }

  Future<void> _afficherDeNouveaux() async {
    setState(() => _idsMasques.clear());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsMasqueKey);
  }

  // ── Chargement HTTP ───────────────────────────────────────────────────────
  Future<void> _chargerSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri(path: 'api_suggestions.php').replace(queryParameters: {
        'action': 'get_all',
        if (_dateDebut != null) 'date_debut': DateFormat('yyyy-MM-dd').format(_dateDebut!),
        if (_dateFin   != null) 'date_fin':   DateFormat('yyyy-MM-dd').format(_dateFin!),
      });

      final resp = await ApiClient.instance.get(
        uri.toString(),
        timeout: const Duration(seconds: 10),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true && mounted) {
          final list = (data['suggestions'] as List)
              .map((j) => _Suggestion.fromJson(j))
              .toList();
          setState(() => _suggestions = list);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Socket.IO ─────────────────────────────────────────────────────────────
  void _connecterSocket() {
    _socket = IO.io(
      'https://mvst.tenelo.cloud',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );
    _socket.connect();

    _socket.onConnect((_) {
      _socket.emit('rejoindre_suggestions_admin', {});
    });

    // Un client vient d'envoyer une nouvelle suggestion
    _socket.on('nouvelle_suggestion', (data) {
      if (!mounted) return;
      try {
        final s = _Suggestion.fromJson(Map<String, dynamic>.from(data));
        setState(() => _suggestions.insert(0, s));
      } catch (_) {}
    });

    // Un client a supprimé l'une de ses suggestions
    _socket.on('suggestion_supprimee', (data) {
      if (!mounted) return;
      final int id = (data['id'] as num).toInt();
      setState(() => _suggestions.removeWhere((s) => s.id == id));
    });
  }

  // ── Changer statut + émettre socket ──────────────────────────────────────
  Future<void> _changerStatut(_Suggestion s, String nouveauStatut) async {
    try {
      final resp = await ApiClient.instance.post(
        'api_suggestions.php',
        body: {'action': 'update_statut', 'id': s.id, 'statut': nouveauStatut},
        timeout: const Duration(seconds: 8),
      );

      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        setState(() => s.statut = nouveauStatut);
        // Notifier le client en temps réel via sa room personnelle
        _socket.emit('rejoindre_suggestions_user', {'idutilisateur': s.idutilisateur});
        _socket.emit('statut_suggestion_change', {
          'id':            s.id,
          'statut':        nouveauStatut,
          'idutilisateur': s.idutilisateur,
        });
      }
    } catch (_) {}
  }

  // ── Supprimer (admin) ─────────────────────────────────────────────────────
  Future<void> _supprimer(_Suggestion s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la suggestion'),
        content: Text(
          'Supprimer définitivement la suggestion de ${s.nom} ?\nLe client en sera notifié.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final resp = await ApiClient.instance.post(
        'api_suggestions.php',
        body: {'action': 'admin_delete', 'id': s.id},
        timeout: const Duration(seconds: 8),
      );

      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        // Notifier le client que sa suggestion a été supprimée
        _socket.emit('suggestion_supprimee_admin', {
          'id':            s.id,
          'idutilisateur': s.idutilisateur,
        });
        if (mounted) setState(() => _suggestions.remove(s));
      }
    } catch (_) {}
  }

  // ── Filtre date ───────────────────────────────────────────────────────────
  Future<void> _choisirDate(bool estDebut) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: estDebut ? (_dateDebut ?? now) : (_dateFin ?? now),
      firstDate: DateTime(2024),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: Config.colors.authCardBackground),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (estDebut) _dateDebut = picked;
      else _dateFin = picked;
    });
    _chargerSuggestions();
  }

  void _reinitialiserFiltresDate() {
    setState(() { _dateDebut = null; _dateFin = null; });
    _chargerSuggestions();
  }

  // ── Filtrage local ─────────────────────────────────────────────────────────
  List<_Suggestion> get _suggestionsFiltrees {
    return _suggestions.where((s) {
      if (_idsMasques.contains(s.id)) return false;
      final catOk    = _categorieFiltre == 'Toutes' || s.categorie == _categorieFiltre;
      final statutOk = _statutFiltre == 'tous' || s.statut == _statutFiltre;
      return catOk && statutOk;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = Config.colors;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: c.authCardBackground,
        iconTheme: IconThemeData(color: c.jauneBlanc),
        title: Text('Suggestions Passagers',
            style: TextStyle(color: c.jauneBlanc, fontFamily: 'Lobster',
                letterSpacing: 0.5, fontSize: 20)),
        centerTitle: true,
        actions: [
          // Bouton réafficher les masquées
          if (_idsMasques.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_idsMasques.length}'),
                child: Icon(Icons.visibility_outlined, color: c.jauneBlanc),
              ),
              tooltip: 'Réafficher les suggestions masquées',
              onPressed: _afficherDeNouveaux,
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: c.jauneBlanc),
            onPressed: _chargerSuggestions,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: c.authCardBackground,
            child: TabBar(
              controller: _tabController,
              indicatorColor: c.jauneFonce,
              indicatorWeight: 3,
              labelColor: c.jauneBlanc,
              unselectedLabelColor: c.jauneBlanc.withValues(alpha: 0.5),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [Tab(text: 'Liste'), Tab(text: 'Statistiques')],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: c.authCardBackground))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListe(c),
                _buildStats(c),
              ],
            ),
    );
  }

  // ── Onglet Liste ──────────────────────────────────────────────────────────
  Widget _buildListe(c) {
    final filtered = _suggestionsFiltrees;

    return Column(children: [
      // ── Filtres catégories ─────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final selected = cat.label == _categorieFiltre;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _categorieFiltre = cat.label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? Config.colors.authCardBackground
                          : Config.colors.authCardBackground.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? Config.colors.authCardBackground
                            : Config.colors.authCardBackground.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(cat.icon, size: 13,
                          color: selected ? Colors.white : Config.colors.authCardBackground),
                      const SizedBox(width: 5),
                      Text(cat.label,
                          style: TextStyle(
                            color: selected ? Colors.white : Config.colors.authCardBackground,
                            fontSize: 12, fontWeight: FontWeight.w600,
                          )),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),

      // ── Filtres statuts ────────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        child: Row(
          children: _filtresStatut.map((s) {
            final selected = s == _statutFiltre;
            final label    = s == 'tous' ? 'Tous' : (_statuts[s]?.label ?? s);
            final color    = s == 'tous'
                ? Config.colors.authCardBackground
                : (_statuts[s]?.color ?? Config.colors.authCardBackground);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _statutFiltre = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected ? color : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? color : color.withValues(alpha: 0.3), width: 1.2,
                    ),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: selected ? Colors.white : color,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            );
          }).toList(),
        ),
      ),

      // ── Filtre par date ────────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        child: Row(children: [
          const Icon(Icons.date_range_outlined, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          _DateBtn(
            label: _dateDebut != null
                ? DateFormat('d MMM', 'fr_FR').format(_dateDebut!)
                : 'Du',
            onTap: () => _choisirDate(true),
            active: _dateDebut != null,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('→', style: TextStyle(color: Colors.black38)),
          ),
          _DateBtn(
            label: _dateFin != null
                ? DateFormat('d MMM', 'fr_FR').format(_dateFin!)
                : 'Au',
            onTap: () => _choisirDate(false),
            active: _dateFin != null,
          ),
          if (_dateDebut != null || _dateFin != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _reinitialiserFiltresDate,
              child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
            ),
          ],
          const Spacer(),
          Text(
            '${filtered.length} résultat${filtered.length > 1 ? 's' : ''}',
            style: TextStyle(
                color: Config.colors.authCardBackground.withValues(alpha: 0.6),
                fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ]),
      ),

      const Divider(height: 1),

      // ── Liste ──────────────────────────────────────────────────────────
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inbox_outlined, size: 60,
                    color: Config.colors.authCardBackground.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text('Aucune suggestion',
                    style: TextStyle(
                        color: Config.colors.authCardBackground.withValues(alpha: 0.4),
                        fontSize: 15)),
              ]))
            : RefreshIndicator(
                onRefresh: _chargerSuggestions,
                color: Config.colors.authCardBackground,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildCard(filtered[i]),
                ),
              ),
      ),
    ]);
  }

  Widget _buildCard(_Suggestion s) {
    final c          = Config.colors;
    final statutInfo = _statuts[s.statut] ?? _statuts['en_attente']!;
    final catInfo    = _categories.firstWhere((x) => x.label == s.categorie,
        orElse: () => _categories.last);
    final date = DateFormat('d MMM y · HH:mm', 'fr_FR').format(s.createdat.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: c.authCardBackground.withValues(alpha: 0.06),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // En-tête : catégorie + statut
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.bleuClaire.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(catInfo.icon, size: 12, color: c.bleuClaire),
                const SizedBox(width: 5),
                Text(s.categorie,
                    style: TextStyle(color: c.bleuClaire, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(s.statut),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statutInfo.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statutInfo.icon, size: 12, color: statutInfo.color),
                  const SizedBox(width: 5),
                  Text(statutInfo.label,
                      style: TextStyle(color: statutInfo.color, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),

          const SizedBox(height: 10),

          // Expéditeur
          Row(children: [
            Icon(Icons.person_outline, size: 14, color: c.authCardBackground.withValues(alpha: 0.5)),
            const SizedBox(width: 5),
            Text(s.nom,
                style: TextStyle(color: c.authCardBackground, fontSize: 13, fontWeight: FontWeight.w600)),
            if (s.telephone.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(s.telephone,
                  style: TextStyle(color: c.authCardBackground.withValues(alpha: 0.45), fontSize: 12)),
            ],
          ]),

          const SizedBox(height: 8),

          // Message
          Text(s.message,
              style: TextStyle(color: c.authCardBackground.withValues(alpha: 0.85),
                  fontSize: 13, height: 1.5)),

          const SizedBox(height: 10),

          // Pied : date + actions
          Row(children: [
            Icon(Icons.access_time_rounded, size: 12,
                color: c.authCardBackground.withValues(alpha: 0.35)),
            const SizedBox(width: 4),
            Text(date,
                style: TextStyle(color: c.authCardBackground.withValues(alpha: 0.4), fontSize: 11)),
            const Spacer(),
            // Bouton masquer
            GestureDetector(
              onTap: () => _masquer(s.id),
              child: Tooltip(
                message: 'Ne plus afficher',
                child: Icon(Icons.visibility_off_outlined, size: 18,
                    color: c.authCardBackground.withValues(alpha: 0.35)),
              ),
            ),
            const SizedBox(width: 8),
            _ActionMenu(
              statut: s.statut,
              onChanged: (nouveau) => _changerStatut(s, nouveau),
              onDelete: () => _supprimer(s),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Onglet Statistiques ───────────────────────────────────────────────────
  Widget _buildStats(_) {
    final c = Config.colors;
    final all = _suggestions; // stats sur toutes, pas que les filtrées

    int enAttente = 0, lu = 0, traite = 0;
    final Map<String, int> parCategorie = {};

    for (final s in all) {
      if (s.statut == 'en_attente') enAttente++;
      else if (s.statut == 'lu') lu++;
      else if (s.statut == 'traite') traite++;
      parCategorie[s.categorie] = (parCategorie[s.categorie] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _StatCard(label: 'Total',      value: all.length, color: c.authCardBackground, icon: Icons.inbox_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'En attente', value: enAttente, color: const Color(0xFFF59E0B), icon: Icons.hourglass_empty_rounded)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _StatCard(label: 'Lus',     value: lu,     color: const Color(0xFF3B82F6), icon: Icons.drafts_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Traités', value: traite, color: const Color(0xFF10B981), icon: Icons.check_circle_outline_rounded)),
        ]),

        const SizedBox(height: 24),

        Text('PAR CATÉGORIE',
            style: TextStyle(color: c.authCardBackground.withValues(alpha: 0.45),
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
        const SizedBox(height: 12),

        ...(_categories.where((cat) => cat.label != 'Toutes').map((cat) {
          final count = parCategorie[cat.label] ?? 0;
          final pct   = all.isEmpty ? 0.0 : count / all.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(cat.icon, size: 14, color: c.bleuClaire),
                const SizedBox(width: 8),
                Expanded(child: Text(cat.label,
                    style: TextStyle(color: c.authCardBackground, fontSize: 13, fontWeight: FontWeight.w600))),
                Text('$count', style: TextStyle(color: c.bleuClaire, fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 6,
                  backgroundColor: c.bleuClaire.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(c.bleuClaire),
                ),
              ),
            ]),
          );
        }).toList()),

        if (_idsMasques.isNotEmpty) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _afficherDeNouveaux,
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: Text('Réafficher ${_idsMasques.length} suggestion${_idsMasques.length > 1 ? 's' : ''} masquée${_idsMasques.length > 1 ? 's' : ''}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.authCardBackground,
              side: BorderSide(color: c.authCardBackground.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Bouton date ───────────────────────────────────────────────────────────────
class _DateBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _DateBtn({required this.label, required this.onTap, required this.active});
  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? c.authCardBackground : c.authCardBackground.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.authCardBackground.withValues(alpha: 0.25)),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? Colors.white : c.authCardBackground,
              fontSize: 12, fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

// ── Menu d'actions statut ─────────────────────────────────────────────────────
class _ActionMenu extends StatelessWidget {
  final String statut;
  final void Function(String) onChanged;
  final VoidCallback onDelete;
  const _ActionMenu({required this.statut, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final actions = <String, String>{
      if (statut != 'lu' && statut != 'traite') 'lu': 'Marquer lu',
      if (statut != 'traite') 'traite': 'Marquer traité',
      if (statut == 'traite' || statut == 'lu') 'en_attente': 'Remettre en attente',
    };
    if (actions.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == '__delete__') {
          onDelete();
        } else {
          onChanged(val);
        }
      },
      icon: Icon(Icons.more_horiz, size: 20,
          color: Config.colors.authCardBackground.withValues(alpha: 0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        ...actions.entries.map((e) {
          final info = _statuts[e.key]!;
          return PopupMenuItem<String>(
            value: e.key,
            child: Row(children: [
              Icon(info.icon, size: 16, color: info.color),
              const SizedBox(width: 10),
              Text(e.value,
                  style: TextStyle(color: info.color, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          );
        }),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: '__delete__',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 16, color: Colors.red),
            SizedBox(width: 10),
            Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      ],
    );
  }
}

// ── Carte statistique ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value',
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Lobster')),
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

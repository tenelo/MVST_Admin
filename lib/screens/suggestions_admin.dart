import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';

// ── Catégories (miroir de l'app client) ───────────────────────────────────────
const List<_Categorie> _categories = [
  _Categorie('Toutes', Icons.all_inbox_outlined),
  _Categorie('Amélioration', Icons.build_circle_outlined),
  _Categorie('Problème', Icons.warning_amber_outlined),
  _Categorie('Compliment', Icons.star_outline_rounded),
  _Categorie('Autre', Icons.chat_bubble_outline_rounded),
  _Categorie('Nouveau trajet', Icons.map_outlined),
];

class _Categorie {
  final String label;
  final IconData icon;
  const _Categorie(this.label, this.icon);
}

// ── Statuts ───────────────────────────────────────────────────────────────────
const Map<String, _StatutInfo> _statuts = {
  'en_attente': _StatutInfo(
    'En attente',
    Color(0xFFF59E0B),
    Icons.hourglass_empty_rounded,
  ),
  'lu': _StatutInfo('Lu', Color(0xFF3B82F6), Icons.drafts_outlined),
  'traite': _StatutInfo(
    'Traité',
    Color(0xFF10B981),
    Icons.check_circle_outline_rounded,
  ),
};

const List<String> _filtresStatut = ['tous', 'en_attente', 'lu', 'traite'];

class _StatutInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _StatutInfo(this.label, this.color, this.icon);
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
  String _categorieFiltre = 'Toutes';
  String _statutFiltre = 'tous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('suggestions')
      .orderBy('createdAt', descending: true)
      .snapshots();

  List<QueryDocumentSnapshot> _filtrer(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final cat = data['categorie'] ?? 'Autre';
      final statut = data['statut'] ?? 'en_attente';
      final catOk = _categorieFiltre == 'Toutes' || cat == _categorieFiltre;
      final statutOk = _statutFiltre == 'tous' || statut == _statutFiltre;
      return catOk && statutOk;
    }).toList();
  }

  Future<void> _changerStatut(String docId, String nouveauStatut) async {
    await FirebaseFirestore.instance
        .collection('suggestions')
        .doc(docId)
        .update({'statut': nouveauStatut});
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: c.bleuFonce,
        iconTheme: IconThemeData(color: c.jauneBlanc),
        title: Text(
          'Suggestions Passagers',
          style: TextStyle(
            color: c.jauneBlanc,
            fontFamily: 'Lobster',
            letterSpacing: 0.5,
            wordSpacing: 1.2,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: c.bleuFonce,
            child: TabBar(
              controller: _tabController,
              indicatorColor: c.jauneFonce,
              indicatorWeight: 3,
              labelColor: c.jauneBlanc,
              unselectedLabelColor: c.jauneBlanc.withValues(alpha: 0.5),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Liste'),
                Tab(text: 'Statistiques'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: c.bleuClaire),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement',
                style: TextStyle(color: Colors.red[400]),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];
          final filtered = _filtrer(allDocs);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildListe(c, allDocs, filtered),
              _buildStats(c, allDocs),
            ],
          );
        },
      ),
    );
  }

  // ── Onglet Liste ─────────────────────────────────────────────────────────
  Widget _buildListe(
    _,
    List<QueryDocumentSnapshot> allDocs,
    List<QueryDocumentSnapshot> filtered,
  ) {
    final c = Config.colors;

    return Column(
      children: [
        // ── Filtres catégories ───────────────────────────────────────────
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? c.bleuClaire
                            : c.bleuClaire.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? c.bleuClaire
                              : c.bleuClaire.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 13,
                            color: selected ? Colors.white : c.bleuClaire,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat.label,
                            style: TextStyle(
                              color: selected ? Colors.white : c.bleuClaire,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Filtres statuts ──────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
          child: Row(
            children: _filtresStatut.map((s) {
              final selected = s == _statutFiltre;
              final label = s == 'tous' ? 'Tous' : (_statuts[s]?.label ?? s);
              final color = s == 'tous'
                  ? c.bleuFonce
                  : (_statuts[s]?.color ?? c.bleuFonce);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _statutFiltre = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? color : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? color : color.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(height: 1),

        // ── Compteur ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${filtered.length} suggestion${filtered.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: c.bleuFonce.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // ── Liste ─────────────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 60,
                        color: c.bleuClaire.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune suggestion',
                        style: TextStyle(
                          color: c.bleuFonce.withValues(alpha: 0.4),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildCard(c, doc.id, data);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCard(_, String docId, Map<String, dynamic> data) {
    final c = Config.colors;
    final String categorie = data['categorie'] ?? 'Autre';
    final String message = data['message'] ?? '';
    final String statut = data['statut'] ?? 'en_attente';
    final String nom = data['nom'] ?? 'Inconnu';
    final String telephone = data['telephone'] ?? '';
    final Timestamp? ts = data['createdAt'];
    final String date = ts != null
        ? DateFormat('d MMM y · HH:mm', 'fr_FR').format(ts.toDate())
        : '—';

    final statutInfo = _statuts[statut] ?? _statuts['en_attente']!;
    final catInfo = _categories.firstWhere(
      (c) => c.label == categorie,
      orElse: () => _categories.last,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: c.bleuFonce.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ────────────────────────────────────────────────
            Row(
              children: [
                // Catégorie
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.bleuClaire.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(catInfo.icon, size: 12, color: c.bleuClaire),
                      const SizedBox(width: 5),
                      Text(
                        categorie,
                        style: TextStyle(
                          color: c.bleuClaire,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Statut
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statutInfo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statutInfo.icon, size: 12, color: statutInfo.color),
                      const SizedBox(width: 5),
                      Text(
                        statutInfo.label,
                        style: TextStyle(
                          color: statutInfo.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Expéditeur ─────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: c.bleuFonce.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 5),
                Text(
                  nom,
                  style: TextStyle(
                    color: c.couleurIcone,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (telephone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    telephone,
                    style: TextStyle(
                      color: c.bleuFonce.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // ── Message ────────────────────────────────────────────────
            Text(
              message,
              style: TextStyle(
                color: c.bleuFonce.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 10),

            // ── Pied : date + actions ──────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: c.bleuFonce.withValues(alpha: 0.35),
                ),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: c.bleuFonce.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                _ActionMenu(
                  statut: statut,
                  onChanged: (nouveau) => _changerStatut(docId, nouveau),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Onglet Statistiques ──────────────────────────────────────────────────
  Widget _buildStats(_, List<QueryDocumentSnapshot> allDocs) {
    final c = Config.colors;

    int enAttente = 0, lu = 0, traite = 0;
    final Map<String, int> parCategorie = {};

    for (final doc in allDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final statut = data['statut'] ?? 'en_attente';
      final cat = data['categorie'] ?? 'Autre';
      if (statut == 'en_attente')
        enAttente++;
      else if (statut == 'lu')
        lu++;
      else if (statut == 'traite')
        traite++;
      parCategorie[cat] = (parCategorie[cat] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cartes résumé ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total',
                  value: allDocs.length,
                  color: c.bleuClaire,
                  icon: Icons.inbox_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'En attente',
                  value: enAttente,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.hourglass_empty_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Lus',
                  value: lu,
                  color: const Color(0xFF3B82F6),
                  icon: Icons.drafts_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Traités',
                  value: traite,
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Par catégorie ─────────────────────────────────────────────
          Text(
            'PAR CATÉGORIE',
            style: TextStyle(
              color: c.bleuFonce.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          ...(_categories.where((cat) => cat.label != 'Toutes').map((cat) {
            final count = parCategorie[cat.label] ?? 0;
            final pct = allDocs.isEmpty ? 0.0 : count / allDocs.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cat.icon, size: 14, color: c.bleuClaire),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            color: c.bleuFonce,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: c.bleuClaire,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: c.bleuClaire.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(c.bleuClaire),
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
        ],
      ),
    );
  }
}

// ── Widget menu d'action pour changer le statut ───────────────────────────────
class _ActionMenu extends StatelessWidget {
  final String statut;
  final void Function(String) onChanged;

  const _ActionMenu({required this.statut, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;

    final actions = <String, String>{
      if (statut != 'lu' && statut != 'traite') 'lu': 'Marquer lu',
      if (statut != 'traite') 'traite': 'Marquer traité',
      if (statut == 'traite' || statut == 'lu')
        'en_attente': 'Remettre en attente',
    };

    if (actions.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      onSelected: onChanged,
      icon: Icon(
        Icons.more_horiz,
        size: 20,
        color: c.bleuFonce.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => actions.entries.map((e) {
        final info = _statuts[e.key]!;
        return PopupMenuItem<String>(
          value: e.key,
          child: Row(
            children: [
              Icon(info.icon, size: 16, color: info.color),
              const SizedBox(width: 10),
              Text(
                e.value,
                style: TextStyle(
                  color: info.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Carte statistique ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lobster',
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

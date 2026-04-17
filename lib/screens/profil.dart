import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profil extends StatefulWidget {
  const Profil({super.key, required this.idUtilisateur, required this.userProfil});
  final String idUtilisateur;
  final String userProfil;

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final _nomCtrl       = TextEditingController();
  final _prenomsCtrl   = TextEditingController();
  final _telCtrl       = TextEditingController();
  final _residenceCtrl = TextEditingController();

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomsCtrl.dispose();
    _telCtrl.dispose();
    _residenceCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _chargerProfil() async {
    final results = await Future.wait([
      FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('id', isEqualTo: widget.idUtilisateur)
          .limit(1)
          .get(),
      SharedPreferences.getInstance(),
    ]);

    final snap  = results[0] as QuerySnapshot;
    final prefs = results[1] as SharedPreferences;

    if (snap.docs.isEmpty) return null;
    final data = Map<String, dynamic>.from(
        snap.docs.first.data() as Map<String, dynamic>);

    // La gare est stockée dans les SharedPreferences (définie dans Paramètres)
    final garePrefs = prefs.getString('gare') ?? '';
    if (data['gare'] == null || (data['gare'] as String).isEmpty) {
      data['gare'] = garePrefs;
    }
    return data;
  }

  String _initiales(String nom, String prenoms) {
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    final p = prenoms.isNotEmpty ? prenoms[0].toUpperCase() : '';
    return '$n$p';
  }

  void _ouvrirEdition(Map<String, dynamic> data) {
    final id = data['id'] as String? ?? widget.idUtilisateur;
    _nomCtrl.text       = data['nom']       ?? '';
    _prenomsCtrl.text   = data['prenoms']   ?? '';
    _telCtrl.text       = data['telephone'] ?? '';
    _residenceCtrl.text = data['residence'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        nomCtrl: _nomCtrl,
        prenomsCtrl: _prenomsCtrl,
        telCtrl: _telCtrl,
        residenceCtrl: _residenceCtrl,
        onSave: () async {
          await _sauvegarder(
            id,
            _nomCtrl.text.trim(),
            _prenomsCtrl.text.trim(),
            _telCtrl.text.trim(),
            _residenceCtrl.text.trim(),
          );
          if (mounted) {
            Navigator.pop(context);
            setState(() {}); // recharge le FutureBuilder
          }
        },
      ),
    );
  }

  Future<void> _sauvegarder(String docId, String nom, String prenoms,
      String telephone, String residence) async {
    try {
      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(docId)
          .update({
        'nom': nom,
        'prenoms': prenoms,
        'telephone': telephone,
        'residence': residence,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Config.colors.authCardBackground,
          content: const Text('Profil mis à jour',
              style: TextStyle(color: Colors.white)),
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _chargerProfil(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: SpinKitThreeBounce(color: Config.colors.authCardBackground),
            );
          }
          if (!snap.hasData || snap.data == null) {
            return const Center(child: Text('Aucun profil trouvé.'));
          }
          final d = snap.data!;
          final nom     = d['nom']       as String? ?? '';
          final prenoms = d['prenoms']   as String? ?? '';
          final tel     = d['telephone'] as String? ?? '';
          final res     = d['residence'] as String? ?? '';
          final gare    = d['gare']      as String? ?? '';

          return CustomScrollView(
            slivers: [
              // ── AppBar + hero ─────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: Config.colors.authCardBackground,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Config.colors.authCardBackground,
                          Config.colors.authCardBackground
                              .withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Avatar initiales
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Config.colors.jauneBlanc
                                .withValues(alpha: 0.15),
                            border: Border.all(
                              color: Config.colors.jauneBlanc,
                              width: 2.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _initiales(nom, prenoms),
                              style: TextStyle(
                                color: Config.colors.jauneBlanc,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$nom $prenoms',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Badge rôle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Config.colors.jauneBlanc
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Config.colors.jauneBlanc
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            widget.userProfil.toUpperCase(),
                            style: TextStyle(
                              color: Config.colors.jauneBlanc,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Corps ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('Informations personnelles'),
                      const SizedBox(height: 12),
                      _InfoCard(children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Nom',
                          value: nom,
                        ),
                        _Divider(),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Prénoms',
                          value: prenoms,
                        ),
                        _Divider(),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Téléphone',
                          value: tel,
                        ),
                        _Divider(),
                        _InfoRow(
                          icon: Icons.home_outlined,
                          label: 'Résidence',
                          value: res,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _SectionTitle('Affectation'),
                      const SizedBox(height: 12),
                      _InfoCard(children: [
                        _InfoRow(
                          icon: Icons.train_outlined,
                          label: 'Gare d\'origine',
                          value: gare.isEmpty ? 'Non définie' : gare,
                        ),
                        _Divider(),
                        _InfoRow(
                          icon: Icons.manage_accounts_outlined,
                          label: 'Rôle',
                          value: widget.userProfil,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      // Bouton modifier
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Config.colors.authCardBackground,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _ouvrirEdition(d),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: const Text(
                            'Modifier le profil',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Composants internes ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Config.colors.authCardBackground,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Config.colors.authCardBackground.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Config.colors.authCardBackground),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 66, endIndent: 16, thickness: 0.5);
  }
}

// ── Bottom sheet d'édition ────────────────────────────────────────────────────

class _EditSheet extends StatelessWidget {
  final TextEditingController nomCtrl;
  final TextEditingController prenomsCtrl;
  final TextEditingController telCtrl;
  final TextEditingController residenceCtrl;
  final VoidCallback onSave;

  const _EditSheet({
    required this.nomCtrl,
    required this.prenomsCtrl,
    required this.telCtrl,
    required this.residenceCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Modifier le profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Config.colors.authCardBackground,
            ),
          ),
          const SizedBox(height: 20),
          _EditField(ctrl: nomCtrl,       label: 'Nom',              icon: Icons.person_outline),
          const SizedBox(height: 12),
          _EditField(ctrl: prenomsCtrl,   label: 'Prénoms',          icon: Icons.badge_outlined),
          const SizedBox(height: 12),
          _EditField(ctrl: telCtrl,       label: 'Téléphone',        icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _EditField(ctrl: residenceCtrl, label: 'Lieu de résidence', icon: Icons.home_outlined),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Config.colors.authCardBackground,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: onSave,
              child: const Text(
                'Enregistrer',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  const _EditField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Config.colors.authCardBackground, size: 20),
        labelStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF4F6FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Config.colors.authCardBackground, width: 1.5),
        ),
      ),
    );
  }
}

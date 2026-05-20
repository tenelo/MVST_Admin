import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/parametres/ajoutDimages.dart';
import 'package:mvst_admin/parametres/gare.dart';
import 'package:mvst_admin/parametres/gestion_admins.dart';
import 'package:mvst_admin/parametres/heuresDeparts.dart';
import 'package:mvst_admin/parametres/infosGare.dart';
import 'package:mvst_admin/parametres/lignesStandard.dart';
import 'package:mvst_admin/screens/vip/heureDepartVip.dart';
import 'package:mvst_admin/screens/vip/lignesVip.dart';

const Color _vipGold = Color(0xFFFFB300);

class ParametresBody extends StatelessWidget {
  const ParametresBody({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;

    return Container(
      //color: c.authBackground,
      child: ListView(
        padding: EdgeInsets.fromLTRB(sw * 0.06, 20, sw * 0.06, 32),
        children: [
          // ── Section Général ───────────────────────────────────────────────
          _sectionLabel('Général'),
          const SizedBox(height: 8),
          _item(
            context: context,
            icon: Icons.manage_accounts_outlined,
            label: 'Gestion des administrateurs',
            c: c,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GestionAdmins()),
            ),
          ),
          _item(
            context: context,
            icon: Icons.train_outlined,
            label: 'Ajout de gares',
            c: c,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Gares()),
            ),
          ),
          _item(
            context: context,
            icon: Icons.schedule_outlined,
            label: 'Heures de départ',
            c: c,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HeureDepart()),
            ),
          ),
          _item(
            context: context,
            icon: Icons.route_outlined,
            label: 'Création de lignes et prix',
            c: c,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LignesStandard()),
            ),
          ),
          _item(
            context: context,
            icon: Icons.info_outline_rounded,
            label: 'Informations sur les gares',
            c: c,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Informations()),
            ),
          ),
          _item(
            context: context,
            icon: Icons.image_outlined,
            label: 'Gestion des images',
            c: c,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ListeImages()),
            ),
          ),
          _item(
            context: context,
            icon: Icons.notifications_outlined,
            label: 'Les notifications',
            c: c,
            onTap: () {},
          ),

          const SizedBox(height: 28),

          // ── Séparateur VIP ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Divider(
                  // color: _vipGold.withValues(alpha: 0.35),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: _vipGold, size: 14),
                    const SizedBox(width: 7),
                    const Text(
                      'V I P',
                      style: TextStyle(
                        //color: _vipGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Icon(Icons.star_rounded, color: _vipGold, size: 14),
                  ],
                ),
              ),
              Expanded(
                child: Divider(
                  // color: _vipGold.withValues(alpha: 0.35),
                  thickness: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Section VIP ───────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: c.authCardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _vipGold.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _vipItem(
                  context: context,
                  icon: Icons.schedule_rounded,
                  label: 'Heures de départ VIP',
                  c: c,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HeureDepartVip()),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _vipGold.withValues(alpha: 0.18),
                  indent: 56,
                  endIndent: 16,
                ),
                _vipItem(
                  context: context,
                  icon: Icons.route_rounded,
                  label: 'Création de lignes et prix VIP',
                  c: c,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LignesVip()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          //color: c.authTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _item({
    required BuildContext context,
    required IconData icon,
    required String label,
    required dynamic c,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: c.authCardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.authBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.authAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: c.authAccent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c.authTextPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: c.authTextSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _vipItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required dynamic c,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      splashColor: _vipGold.withValues(alpha: 0.08),
      highlightColor: _vipGold.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _vipGold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _vipGold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c.homeAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.homeAccent, size: 20),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class Parametres extends StatelessWidget {
  Parametres({super.key});
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      //  backgroundColor: c.authBackground,
      appBar: AppBar(
        iconTheme: IconThemeData(color: c.homeAccent),
        backgroundColor: c.authCardBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Paramètres',
          style: TextStyle(
            color: c.authTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: sw * 0.048,
          ),
        ),
      ),
      body: const ParametresBody(),
      persistentFooterButtons: [
        Text(
          user?.displayName ?? '',
          style: TextStyle(fontFamily: 'Lobster', color: c.authCardBackground),
        ),
      ],
    );
  }
}

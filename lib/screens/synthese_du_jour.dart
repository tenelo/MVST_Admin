import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SyntheseDuJour extends StatefulWidget {
  const SyntheseDuJour({super.key, required this.gare, required this.uid});
  final String gare;
  final String uid;

  @override
  State<SyntheseDuJour> createState() => _SyntheseDuJourState();
}

class _SyntheseDuJourState extends State<SyntheseDuJour> {
  bool _isLoading = true;
  String? _erreur;
  Map<String, dynamic>? _bandeau;
  Map<String, dynamic>? _acheteurs;
  List<Map<String, dynamic>> _departsDuJour = [];
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

  // ── Socket.IO ──────────────────────────────────────────────────────────────
  late IO.Socket socket;
  Timer? _debounce;
  String? _gareRoomActuelle;

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
    _connecterSocket();
  }

  Future<void> _chargerListeGares() async {
    try {
      final response = await ApiClient.instance.get('gares.php');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _listeGares = List<Map<String, dynamic>>.from(
              data['gares'],
            ).map((g) => g['gare'].toString()).toList();
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    socket.off('synthese_maj');
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  // ── Connexion Socket.IO ────────────────────────────────────────────────────
  void _connecterSocket() {
    socket = IO.io(
      'https://mvst.tenelo.cloud',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) => _rejoindreRoomGare());

    // ── Une vente/un scan a modifie la synthese -> rafraichir (debounce) ────
    // On ne recharge que si l'evenement concerne la gare actuellement
    // affichee (evite un rafraichissement croise si le socket reste abonne
    // a une ancienne room apres un changement de gare). Si le serveur
    // n'indique pas de gare dans l'evenement, on ne filtre pas (comportement
    // actuel inchange pour un admin normal).
    socket.on('synthese_maj', (data) {
      final dynamic gareEvenement = (data is Map) ? data['gare'] : null;
      final bool concerneCetteGare =
          gareEvenement == null || gareEvenement == _gareRoomActuelle;
      if (_gareRoomActuelle != null && concerneCetteGare) {
        _rechargerAvecDebounce();
      }
    });
  }

  // Rejoint la room socket de la gare effective. En mode "Toutes les gares"
  // (superadmin, aucune gare choisie), ne rejoint aucune room : pas de temps
  // reel dans ce mode (choix proprietaire).
  void _rejoindreRoomGare() {
    final gareEffective = _gareEffective;
    _gareRoomActuelle = gareEffective;
    if (gareEffective == null) return;
    socket.emit('rejoindre_room_gare', {'gare': gareEffective});
  }

  void _rechargerAvecDebounce() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _getDonnees);
  }

  // ── Charger la synthese via PHP ────────────────────────────────────────────
  Future<void> _getDonnees() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _erreur = null;
      });
    }
    try {
      final String dateChoisie = DateFormat(
        'yyyy-MM-dd',
      ).format(_dateSelectionnee);
      final Map<String, dynamic> body = {'date': dateChoisie};
      final gareEffective = _gareEffective;
      if (gareEffective != null) {
        body['gare'] = gareEffective;
      }
      final response = await ApiClient.instance.post(
        'synthese_gare.php',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _bandeau = Map<String, dynamic>.from(data['bandeau'] ?? {});
              _acheteurs = Map<String, dynamic>.from(data['acheteurs'] ?? {});
              _departsDuJour = List<Map<String, dynamic>>.from(
                data['departsDuJour'] ?? [],
              );
              _isLoading = false;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _erreur = 'Erreur lors du chargement de la synthese.';
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
  // Contenu du selecteur de gare (icone + Dropdown), reutilise tel quel dans
  // la barre de filtres sous l'AppBar.
  Widget _selecteurGareDropdown(dynamic c) {
    return Row(
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
              _rejoindreRoomGare();
              _getDonnees();
            },
          ),
        ),
      ],
    );
  }

  // Bouton date, reutilise tel quel (etait auparavant dans les actions de
  // l'AppBar).
  Widget _boutonDate(dynamic c) {
    return TextButton.icon(
      onPressed: _choisirDate,
      icon: Icon(Icons.calendar_month_outlined, color: c.jauneBlanc),
      label: Text(
        DateFormat('EEE d MMM', 'fr_FR').format(_dateSelectionnee),
        style: TextStyle(color: c.jauneBlanc, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Barre de filtres sous l'AppBar : selecteur de gare + bouton date sur la
  // meme ligne (superadmin), ou juste le bouton date aligne a droite (admin
  // normal, comportement inchange).
  Widget _buildBarreFiltres(dynamic c) {
    if (_role == 'superadmin') {
      return Row(
        children: [
          Expanded(child: _selecteurGareDropdown(c)),
          const SizedBox(width: 12),
          _boutonDate(c),
        ],
      );
    }
    return Row(children: [const Spacer(), _boutonDate(c)]);
  }

  bool get _estVide => _departsDuJour.isEmpty;

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
          'Synthese du jour - $_titreGare',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
            child: _buildBarreFiltres(c),
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
    return [
      _buildBandeau(large),
      const SizedBox(height: 20),
      _buildAcheteurs(),
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
      _estVide
          ? _buildVide()
          : (large ? _buildDepartsTable() : _buildDepartsListe()),
    ];
  }

  Widget _buildBandeau(bool large) {
    final vendus = _bandeau?['vendus'] ?? 0;
    final recettesRaw = _bandeau?['recettes'] ?? 0;
    final scannes = _bandeau?['scannes'] ?? 0;
    final tauxRaw = _bandeau?['tauxEmbarquement'] ?? 0;

    final recettesNum = recettesRaw is num
        ? recettesRaw
        : num.tryParse(recettesRaw.toString()) ?? 0;
    final tauxNum = tauxRaw is num
        ? tauxRaw
        : num.tryParse(tauxRaw.toString()) ?? 0;

    final recettesStr =
        '${NumberFormat('#,##0', 'fr_FR').format(recettesNum)} FCFA';
    final tauxStr = '${tauxNum.toStringAsFixed(1)} %';

    final indicateurs = [
      _IndicateurCard(valeur: '$vendus', libelle: 'Vendus'),
      _IndicateurCard(valeur: recettesStr, libelle: 'Recettes'),
      _IndicateurCard(valeur: '$scannes', libelle: 'Scannes'),
      _IndicateurCard(valeur: tauxStr, libelle: 'Taux embarquement'),
    ];

    return GridView.count(
      crossAxisCount: large ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: large ? 1.6 : 1.3,
      children: indicateurs,
    );
  }

  Widget _buildAcheteurs() {
    final jour = _acheteurs?['jour'] ?? 0;
    final semaine = _acheteurs?['semaine'] ?? 0;
    final mois = _acheteurs?['mois'] ?? 0;
    return Row(
      children: [
        Expanded(
          child: _PetiteCarte(valeur: '$jour', libelle: 'Jour'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PetiteCarte(valeur: '$semaine', libelle: 'Semaine'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PetiteCarte(valeur: '$mois', libelle: 'Mois'),
        ),
      ],
    );
  }

  Widget _buildVide() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 40,
              color: Config.colors.homeTabUnselected,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune vente aujourd\'hui',
              style: TextStyle(
                color: Config.colors.homeTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartsListe() {
    return Column(
      children: _departsDuJour.map((depart) {
        final heure = depart['heureDeDepart']?.toString() ?? '';
        final destination = depart['destination']?.toString() ?? '';
        final typeVoyage = depart['typeVoyage']?.toString() ?? 'standard';
        final vendus = depart['vendus'] ?? 0;
        final embarques = depart['embarques'] ?? 0;
        final estVip = typeVoyage.toLowerCase() == 'vip';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              '$heure  →  $destination',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Vendus $vendus | Embarques $embarques'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDepartsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Heure')),
          DataColumn(label: Text('Destination')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Vendus'), numeric: true),
          DataColumn(label: Text('Embarques'), numeric: true),
        ],
        rows: _departsDuJour.map((depart) {
          final heure = depart['heureDeDepart']?.toString() ?? '';
          final destination = depart['destination']?.toString() ?? '';
          final typeVoyage = depart['typeVoyage']?.toString() ?? 'standard';
          final vendus = depart['vendus'] ?? 0;
          final embarques = depart['embarques'] ?? 0;
          return DataRow(
            cells: [
              DataCell(Text(heure)),
              DataCell(Text(destination)),
              DataCell(Text(typeVoyage.toUpperCase())),
              DataCell(Text('$vendus')),
              DataCell(Text('$embarques')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _IndicateurCard extends StatelessWidget {
  const _IndicateurCard({required this.valeur, required this.libelle});
  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Card(
      color: c.homeCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.homeBandeauBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              child: Text(
                valeur,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: c.homeTabSelected,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              libelle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.homeTextPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetiteCarte extends StatelessWidget {
  const _PetiteCarte({required this.valeur, required this.libelle});
  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: c.homeBandeauBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.homeBandeauBorder),
      ),
      child: Column(
        children: [
          Text(
            valeur,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.homeTabSelected,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            libelle,
            style: TextStyle(fontSize: 11, color: c.homeTextPrimary),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';

const Color _headerBg = Color(0xFF1A3A5C);
const TextStyle _headerStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 12,
);

class ListeDesUtilisateurs extends StatefulWidget {
  const ListeDesUtilisateurs({super.key});

  @override
  State<ListeDesUtilisateurs> createState() => _ListeDesUtilisateursState();
}

class _ListeDesUtilisateursState extends State<ListeDesUtilisateurs> {
  List<Map<String, dynamic>> _utilisateurs = [];
  bool _isLoading = true;
  final TextEditingController _rechercheController = TextEditingController();

  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  int _limit = 20;

  @override
  void initState() {
    super.initState();
    _chargerUtilisateurs();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerUtilisateurs({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _currentPage = page;
    });

    try {
      final response = await http
          .post(
            apiUri('reinitialiserPoints.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'lister_tous',
              'page': page,
              'limit': _limit,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _utilisateurs = List<Map<String, dynamic>>.from(
              data['utilisateurs'],
            );
            _total = data['total'] ?? 0;
            _totalPages = data['totalPages'] ?? 1;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _rechercherParNumero() async {
    final numero = _rechercheController.text.trim();
    if (numero.isEmpty) {
      _chargerUtilisateurs();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http
          .post(
            apiUri('reinitialiserPoints.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'verifier', 'telephone': numero}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final user = data['utilisateur'];
          final estBloque = data['bloque'] == true;
          setState(() {
            _utilisateurs = [
              {
                'idUtilisateur': user['idUtilisateur'],
                'nom': user['nom'],
                'prenoms': user['prenoms'] ?? '',
                'telephone': user['telephone'],
                'residence': user['residence'] ?? '',
                'points': user['points'],
                'motif': estBloque ? 'Compte bloqué' : 'Compte actif',
                'date': '',
              },
            ];
            _total = 1;
            _totalPages = 1;
            _currentPage = 1;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(data['message'])));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _debloquerCompte(Map<String, dynamic> compte) async {
    final pointsController = TextEditingController(text: '3');
    final motifController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Config.colors.authCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_open, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Débloquer ${compte['nom']} ${compte['prenoms']}',
                style: TextStyle(
                  color: Config.colors.authTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Téléphone : ${compte['telephone']}',
              style: TextStyle(color: Config.colors.authTextSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Points à attribuer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motifController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Motif du déblocage',
                hintText: 'Ex: Contact support...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Débloquer'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final points = int.tryParse(pointsController.text) ?? 3;
      final motif = motifController.text.isNotEmpty
          ? motifController.text
          : 'Déblocage manuel';
      try {
        final response = await http
            .post(
              apiUri('reinitialiserPoints.php'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'action': 'reinitialiser',
                'idUtilisateur': compte['idUtilisateur'],
                'points': points,
                'motif': motif,
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(data['message']),
            ),
          );
          _chargerUtilisateurs(page: _currentPage);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Erreur réseau'),
            ),
          );
        }
      }
    }
  }

  String _formaterDateCourte(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  String _formaterDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      return DateFormat(
        'dd/MM/yyyy à HH:mm',
        'fr_FR',
      ).format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  void _voirDetails(Map<String, dynamic> compte) {
    final points = int.tryParse(compte['points']?.toString() ?? '0') ?? 0;
    final estBloque = points <= 0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              estBloque ? Icons.lock : Icons.check_circle,
              color: estBloque ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${compte['nom']} ${compte['prenoms']}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLigne(Icons.phone, compte['telephone']?.toString() ?? ''),
            _detailLigne(Icons.stars, '$points point(s)'),
            if ((compte['dateDeCreation']?.toString() ?? '').isNotEmpty)
              _detailLigne(
                Icons.calendar_today,
                'Inscrit le ${_formaterDate(compte['dateDeCreation'])}',
              ),
            if ((compte['motif']?.toString() ?? '').isNotEmpty)
              _detailLigne(Icons.info_outline, compte['motif'].toString()),
            if ((compte['date']?.toString() ?? '').isNotEmpty)
              _detailLigne(
                Icons.block,
                'Bloqué le ${_formaterDate(compte['date'])}',
                color: Colors.red,
              ),
          ],
        ),
        actions: [
          if (estBloque)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _debloquerCompte(compte);
              },
              icon: const Icon(Icons.lock_open, size: 16),
              label: const Text('Débloquer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _detailLigne(IconData icon, String texte, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texte,
            style: TextStyle(fontSize: 13, color: color ?? Colors.black87),
          ),
        ),
      ],
    ),
  );

  DataColumn _col(String label) =>
      DataColumn(label: Text(label, style: _headerStyle));

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        iconTheme: IconThemeData(color: c.authCardBackground),
        title: Text(
          'Utilisateurs',
          style: TextStyle(
            fontSize: 14,
            color: c.authCardBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.authCardBackground),
            onPressed: () => _chargerUtilisateurs(page: _currentPage),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rechercheController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par numéro',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _rechercheController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _rechercheController.clear();
                                _chargerUtilisateurs();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _rechercherParNumero(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _rechercherParNumero,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _headerBg,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Chercher', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: c.authCardBackground,
                    ),
                  )
                : _utilisateurs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          color: Colors.grey,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun utilisateur trouvé',
                          style: TextStyle(
                            color: c.authTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: PaginatedDataTable(
                        showCheckboxColumn: false,
                        header: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _headerBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$_total utilisateur(s)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Page $_currentPage / $_totalPages',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        rowsPerPage: _limit,
                        availableRowsPerPage: const [10, 20, 50, 100],
                        onRowsPerPageChanged: (int? value) {
                          if (value != null) {
                            _limit = value;
                            _chargerUtilisateurs(page: 1);
                          }
                        },
                        showFirstLastButtons: true,
                        onPageChanged: (int? page) {
                          if (page != null) {
                            _chargerUtilisateurs(page: page + 1);
                          }
                        },
                        headingRowColor: WidgetStateProperty.all(_headerBg),
                        headingRowHeight: 42,
                        dataRowMinHeight: 44,
                        dataRowMaxHeight: 56,
                        horizontalMargin: 12,
                        columnSpacing: 20,
                        columns: [
                          _col('#'),
                          _col('Nom & Prénoms'),
                          _col('Téléphone'),
                          _col('Inscription'),
                          _col('Points'),
                          _col('Résidence'),
                          _col('Action'),
                        ],
                        source: _UserDataSource(
                          utilisateurs: _utilisateurs,
                          currentPage: _currentPage,
                          limit: _limit,
                          voirDetails: _voirDetails,
                          debloquerCompte: _debloquerCompte,
                          formaterDateCourte: _formaterDateCourte,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _UserDataSource extends DataTableSource {
  final List<Map<String, dynamic>> utilisateurs;
  final int currentPage;
  final int limit;
  final Function(Map<String, dynamic>) voirDetails;
  final Function(Map<String, dynamic>) debloquerCompte;
  final String Function(String?) formaterDateCourte;

  _UserDataSource({
    required this.utilisateurs,
    required this.currentPage,
    required this.limit,
    required this.voirDetails,
    required this.debloquerCompte,
    required this.formaterDateCourte,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= utilisateurs.length) return null;
    final compte = utilisateurs[index];
    final points = int.tryParse(compte['points']?.toString() ?? '0') ?? 0;
    final estBloque = points <= 0;

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (estBloque) return Colors.red.shade50;
        return index.isEven ? Colors.white : const Color(0xFFEFF6FF);
      }),
      onSelectChanged: (_) => voirDetails(compte),
      cells: [
        DataCell(
          Text(
            '${(currentPage - 1) * limit + index + 1}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${compte['nom']} ${compte['prenoms']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (estBloque)
                const Text(
                  'Bloqué',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Text(
            compte['telephone']?.toString() ?? '—',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            formaterDateCourte(compte['dateDeCreation']?.toString()),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: estBloque ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$points',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            compte['residence']?.toString() ?? '—',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        DataCell(
          estBloque
              ? TextButton.icon(
                  onPressed: () => debloquerCompte(compte),
                  icon: const Icon(
                    Icons.lock_open,
                    size: 14,
                    color: Colors.green,
                  ),
                  label: const Text(
                    'Débloquer',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => utilisateurs.length;

  @override
  int get selectedRowCount => 0;
}

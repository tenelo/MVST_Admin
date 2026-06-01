import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';

class GestionComptesBloques extends StatefulWidget {
  const GestionComptesBloques({super.key});

  @override
  State<GestionComptesBloques> createState() => _GestionComptesBloquesState();
}

class _GestionComptesBloquesState extends State<GestionComptesBloques> {
  List<Map<String, dynamic>> _comptesBloques = [];
  bool _isLoading = true;
  final TextEditingController _rechercheController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  final int _limit = 100;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chargerComptesBloques();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _currentPage < _totalPages) {
        _chargerComptesBloques(page: _currentPage + 1, isLoadMore: true);
      }
    }
  }

  Future<void> _chargerComptesBloques({
    int page = 1,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      setState(() => _isLoading = true);
    } else {
      setState(() {
        _isLoading = true;
        _comptesBloques = [];
        _currentPage = page;
      });
    }

    try {
      final response = await http
          .post(
            apiUri('reinitialiserPoints.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'lister_bloques',
              'page': page,
              'limit': _limit,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            if (isLoadMore) {
              _comptesBloques.addAll(
                List<Map<String, dynamic>>.from(data['bloques']),
              );
            } else {
              _comptesBloques = List<Map<String, dynamic>>.from(
                data['bloques'],
              );
            }
            _total = data['total'] ?? 0;
            _totalPages = data['totalPages'] ?? 1;
            _currentPage = page;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rechercherParNumero() async {
    final numero = _rechercheController.text.trim();
    if (numero.isEmpty) {
      _chargerComptesBloques();
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
          setState(() {
            _comptesBloques = [
              {
                'idUtilisateur': user['idUtilisateur'],
                'nom': user['nom'],
                'prenoms': user['prenoms'] ?? '',
                'telephone': user['telephone'],
                'points': user['points'],
                'motif': data['bloque'] == true
                    ? 'Recherche manuelle'
                    : 'Compte actif',
                'date': '',
              },
            ];
            _isLoading = false;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(data['message'])));
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
          _chargerComptesBloques();
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

  String _formaterDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;

    return Scaffold(
      backgroundColor: c.authBackground,
      appBar: AppBar(
        iconTheme: IconThemeData(color: c.authCardBackground),
        title: Text(
          'Comptes Bloqués',
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
            onPressed: () => _chargerComptesBloques(),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color.fromARGB(143, 228, 227, 227),
        ),
        child: Column(
          children: [
            Row(
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
                                _chargerComptesBloques();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _rechercherParNumero(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _rechercherParNumero,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Vérifier'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$_total résultat(s) - Page $_currentPage/$_totalPages',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: c.authTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading && _comptesBloques.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: c.authCardBackground,
                      ),
                    )
                  : _comptesBloques.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 56,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun compte bloqué',
                            style: TextStyle(
                              color: c.authTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _comptesBloques.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _comptesBloques.length && _isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final compte = _comptesBloques[index];
                        final points =
                            int.tryParse(compte['points']?.toString() ?? '0') ??
                            0;
                        final estBloque = points <= 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: estBloque
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${compte['nom']} ${compte['prenoms']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: estBloque
                                            ? Colors.red
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$points point(s)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '📱 ${compte['telephone']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (compte['motif'] != null &&
                                    compte['motif'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Motif : ${compte['motif']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                if (compte['date'] != null &&
                                    compte['date'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Date blocage : ${_formaterDate(compte['date'])}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                                if (estBloque) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _debloquerCompte(compte),
                                      icon: const Icon(
                                        Icons.lock_open,
                                        size: 16,
                                      ),
                                      label: const Text('Débloquer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

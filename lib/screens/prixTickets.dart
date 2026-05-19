import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';

class PrixTickets extends StatefulWidget {
  const PrixTickets({super.key});

  @override
  _PrixTicketsState createState() => _PrixTicketsState();
}

class _PrixTicketsState extends State<PrixTickets> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _axeController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  List<Map<String, dynamic>> _prixList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rafraichirDonnees();
  }

  @override
  void dispose() {
    _axeController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  // ── Charger les prix ───────────────────────────────────────────────────────
  Future<void> _rafraichirDonnees() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.get(
        apiUri('prixTickets.php'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _prixList = List<Map<String, dynamic>>.from(
              data['prix'],
            ).where((p) => p['type']?.toString() == 'standard').toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Ajouter ───────────────────────────────────────────────────────────────
  Future<void> _ajouter(String axe, int prix) async {
    try {
      await http.post(
        apiUri('prixTickets.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'ajouter',
          'axe': axe,
          'prix': prix,
          'type': 'standard',
        }),
      );
      await _rafraichirDonnees();
    } catch (e) {}
  }

  // ── Modifier ──────────────────────────────────────────────────────────────
  Future<void> _modifier(int id, String axe, int prix) async {
    try {
      await http.post(
        apiUri('prixTickets.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'modifier',
          'id': id,
          'axe': axe,
          'prix': prix,
        }),
      );
      await _rafraichirDonnees();
    } catch (e) {}
  }

  // ── Supprimer ─────────────────────────────────────────────────────────────
  Future<void> _supprimer(int id) async {
    try {
      await http.post(
        apiUri('prixTickets.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'supprimer', 'id': id}),
      );
      await _rafraichirDonnees();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(93, 12, 134, 195),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Prix des Tickets',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _rafraichirDonnees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prixList.isEmpty
          ? Center(
              child: Text(
                'Aucune donnée disponible',
                style: TextStyle(
                  color: Config.colors.authCardBackground,
                  fontFamily: 'Lobster',
                ),
              ),
            )
          : ListView.builder(
              itemCount: _prixList.length,
              itemBuilder: (context, index) {
                final ticket = _prixList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Card(
                    margin: const EdgeInsets.all(4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ticket['axe'].toString()),
                              Text('${ticket['prix']} f'),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _afficherModalModifier(context, ticket),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final confirm = await _confirmerSuppression(
                                    context,
                                  );
                                  if (confirm == true) {
                                    await _supprimer(ticket['id']);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _afficherModalAjouter(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _afficherModalAjouter(BuildContext context) {
    _axeController.clear();
    _prixController.clear();
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _axeController,
                decoration: const InputDecoration(labelText: 'Axe'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Veuillez entrer un axe' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prixController,
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Veuillez entrer un prix';
                  if (int.tryParse(v) == null) return 'Entrer un nombre valide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _ajouter(
                      _axeController.text.trim(),
                      int.parse(_prixController.text.trim()),
                    );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _afficherModalModifier(
    BuildContext context,
    Map<String, dynamic> ticket,
  ) {
    _axeController.text = ticket['axe'].toString();
    _prixController.text = ticket['prix'].toString();
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _axeController,
                decoration: const InputDecoration(labelText: 'Axe'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Veuillez entrer un axe' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prixController,
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Veuillez entrer un prix';
                  if (int.tryParse(v) == null) return 'Entrer un nombre valide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _modifier(
                      ticket['id'],
                      _axeController.text.trim(),
                      int.parse(_prixController.text.trim()),
                    );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmerSuppression(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette entrée ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

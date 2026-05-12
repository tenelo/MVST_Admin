import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';

class Gares extends StatefulWidget {
  const Gares({super.key});

  @override
  _GaresState createState() => _GaresState();
}

class _GaresState extends State<Gares> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _gareController = TextEditingController();
  List<Map<String, dynamic>> _garesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rafraichirDonnees();
  }

  @override
  void dispose() {
    _gareController.dispose();
    super.dispose();
  }

  // ── Charger les gares ──────────────────────────────────────────────────────
  Future<void> _rafraichirDonnees() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://mvst.tenelo.cloud/gares.php'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _garesList = List<Map<String, dynamic>>.from(data['gares']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Ajouter une gare ───────────────────────────────────────────────────────
  Future<void> _ajouterGare(String gare) async {
    try {
      await http.post(
        Uri.parse('https://mvst.tenelo.cloud/gares.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'ajouter', 'gare': gare}),
      );
      _rafraichirDonnees();
    } catch (e) {}
  }

  // ── Modifier une gare ──────────────────────────────────────────────────────
  Future<void> _modifierGare(int id, String gare) async {
    try {
      await http.post(
        Uri.parse('https://mvst.tenelo.cloud/gares.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'modifier', 'id': id, 'gare': gare}),
      );
      _rafraichirDonnees();
    } catch (e) {}
  }

  // ── Supprimer une gare ─────────────────────────────────────────────────────
  Future<void> _supprimerGare(int id) async {
    try {
      await http.post(
        Uri.parse('https://mvst.tenelo.cloud/gares.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'supprimer', 'id': id}),
      );
      _rafraichirDonnees();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(93, 12, 134, 195),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text("Gares", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _rafraichirDonnees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _garesList.isEmpty
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
              itemCount: _garesList.length,
              itemBuilder: (context, index) {
                final gare = _garesList[index];
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
                          Text(gare['gare'].toString()),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _afficherModalModifier(context, gare),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final confirm = await _confirmerSuppression(
                                    context,
                                  );
                                  if (confirm == true) {
                                    await _supprimerGare(gare['id']);
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
    _gareController.clear();
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
                controller: _gareController,
                decoration: const InputDecoration(labelText: 'Gare'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Veuillez entrer une gare' : null,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _ajouterGare(_gareController.text.trim());
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

  void _afficherModalModifier(BuildContext context, Map<String, dynamic> gare) {
    _gareController.text = gare['gare'];
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
                controller: _gareController,
                decoration: const InputDecoration(labelText: 'Gare'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Veuillez entrer une gare' : null,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _modifierGare(
                      gare['id'],
                      _gareController.text.trim(),
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

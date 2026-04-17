import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PrixTicketsVip extends StatefulWidget {
  const PrixTicketsVip({super.key});

  @override
  _PrixTicketsVipState createState() => _PrixTicketsVipState();
}

class _PrixTicketsVipState extends State<PrixTicketsVip> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _axeController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  List<Map<String, dynamic>> _prixList = [];
  bool _isLoading = true;

  static const _bleu = Color.fromARGB(93, 12, 134, 195);
  static const _or = Color(0xFFFFD700);
  static const _dark = Color(0xFF1A1A2E);

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

  Future<void> _rafraichirDonnees() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://mvst.tenelo.cloud/prixTickets.php?type=vip'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _prixList = List<Map<String, dynamic>>.from(
              data['prix'],
            ).where((p) => p['type']?.toString() == 'vip').toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouter(String axe, int prix) async {
    try {
      await http.post(
        Uri.parse('https://mvst.tenelo.cloud/prixTickets.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'ajouter',
          'axe': axe,
          'prix': prix,
          'type': 'vip',
        }),
      );
      await _rafraichirDonnees();
    } catch (e) {}
  }

  Future<void> _modifier(int id, String axe, int prix) async {
    try {
      await http.post(
        Uri.parse('https://mvst.tenelo.cloud/prixTickets.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'modifier',
          'id': id,
          'axe': axe,
          'prix': prix,
          'type': 'vip',
        }),
      );
      await _rafraichirDonnees();
    } catch (e) {}
  }

  Future<void> _supprimer(int id) async {
    try {
      await http.post(
        Uri.parse('https://mvst.tenelo.cloud/prixTickets.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'supprimer', 'id': id}),
      );
      await _rafraichirDonnees();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: _dark,
        iconTheme: const IconThemeData(color: _or),
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: _or, size: 20),
            SizedBox(width: 8),
            Text(
              'Prix VIP',
              style: TextStyle(color: _or, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _or),
            onPressed: _rafraichirDonnees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _or))
          : _prixList.isEmpty
          ? const Center(
              child: Text(
                'Aucun prix VIP enregistré',
                style: TextStyle(color: _or, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: _prixList.length,
              itemBuilder: (context, index) {
                final ticket = _prixList[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _or, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _or,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.star, color: _dark, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket['axe'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _or,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ticket['prix']} FCFA',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: _or),
                          onPressed: () =>
                              _afficherModalModifier(context, ticket),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Color.fromARGB(255, 233, 75, 64),
                          ),
                          onPressed: () async {
                            final confirm = await _confirmerSuppression(
                              context,
                            );
                            if (confirm == true) await _supprimer(ticket['id']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _or,
        onPressed: () => _afficherModalAjouter(context),
        child: const Icon(Icons.add, color: _dark),
      ),
    );
  }

  void _afficherModalAjouter(BuildContext context) {
    _axeController.clear();
    _prixController.clear();
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: _or, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Ajouter un prix VIP',
                    style: TextStyle(
                      color: _or,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _axeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Axe',
                  labelStyle: TextStyle(color: _or),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _or),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _or, width: 2),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Veuillez entrer un axe' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prixController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Prix (FCFA)',
                  labelStyle: TextStyle(color: _or),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _or),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _or, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Veuillez entrer un prix';
                  if (int.tryParse(v) == null) return 'Entrer un nombre valide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _or),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _ajouter(
                      _axeController.text.trim(),
                      int.parse(_prixController.text.trim()),
                    );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text(
                  'Ajouter',
                  style: TextStyle(color: _dark, fontWeight: FontWeight.bold),
                ),
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
      backgroundColor: const Color(0xFF16213E),
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: _or, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Modifier le prix VIP',
                    style: TextStyle(
                      color: _or,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _axeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Axe',
                  labelStyle: TextStyle(color: _or),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _or),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _or, width: 2),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Veuillez entrer un axe' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prixController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Prix (FCFA)',
                  labelStyle: TextStyle(color: _or),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _or),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _or, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Veuillez entrer un prix';
                  if (int.tryParse(v) == null) return 'Entrer un nombre valide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _or),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _modifier(
                      ticket['id'],
                      _axeController.text.trim(),
                      int.parse(_prixController.text.trim()),
                    );
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text(
                  'Modifier',
                  style: TextStyle(color: _dark, fontWeight: FontWeight.bold),
                ),
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
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(color: _or),
        ),
        content: const Text(
          'Voulez-vous vraiment supprimer ce prix VIP ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Color.fromARGB(255, 233, 75, 64)),
            ),
          ),
        ],
      ),
    );
  }
}

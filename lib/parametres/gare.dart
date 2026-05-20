import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';

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

  Future<void> _rafraichirDonnees() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.get(apiUri('gares.php'));
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

  Future<void> _ajouterGare(String gare) async {
    try {
      await http.post(
        apiUri('gares.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'ajouter', 'gare': gare}),
      );
      _rafraichirDonnees();
    } catch (e) {}
  }

  Future<void> _modifierGare(int id, String gare) async {
    try {
      await http.post(
        apiUri('gares.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'modifier', 'id': id, 'gare': gare}),
      );
      _rafraichirDonnees();
    } catch (e) {}
  }

  Future<void> _supprimerGare(int id) async {
    try {
      await http.post(
        apiUri('gares.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'supprimer', 'id': id}),
      );
      _rafraichirDonnees();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.authBackground,
      appBar: AppBar(
        backgroundColor: c.authCardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.authTextPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Gares',
          style: TextStyle(
            color: c.authTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: sw * 0.045,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.authTextPrimary),
            onPressed: _rafraichirDonnees,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: c.authAccent))
          : _garesList.isEmpty
          ? Center(
              child: Text(
                'Aucune donnée disponible',
                style: TextStyle(color: c.authTextSecondary, fontFamily: 'Lobster'),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.06,
                vertical: sh * 0.02,
              ),
              itemCount: _garesList.length,
              itemBuilder: (context, index) {
                final gare = _garesList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: c.authCardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.authBorder, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          gare['gare'].toString(),
                          style: TextStyle(
                            color: c.authTextPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: c.authAccent),
                              onPressed: () =>
                                  _afficherModalModifier(context, gare),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm =
                                    await _confirmerSuppression(context);
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
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.authButton,
        foregroundColor: c.authTextPrimary,
        onPressed: () => _afficherModalAjouter(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _afficherModalAjouter(BuildContext context) {
    final c = Config.colors;
    _gareController.clear();
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: c.authCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
              Text(
                'Ajouter une gare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.authTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: c.authCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.authBorder, width: 1.5),
                ),
                child: TextFormField(
                  controller: _gareController,
                  cursorColor: c.authAccent,
                  style: TextStyle(color: c.authTextPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: 'Nom de la gare',
                    hintStyle: TextStyle(color: c.authTextSecondary),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Veuillez entrer une gare' : null,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _ajouterGare(_gareController.text.trim());
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.authButton,
                  foregroundColor: c.authTextPrimary,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
    Map<String, dynamic> gare,
  ) {
    final c = Config.colors;
    _gareController.text = gare['gare'];
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: c.authCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
              Text(
                'Modifier la gare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.authTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: c.authCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.authBorder, width: 1.5),
                ),
                child: TextFormField(
                  controller: _gareController,
                  cursorColor: c.authAccent,
                  style: TextStyle(color: c.authTextPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: 'Nom de la gare',
                    hintStyle: TextStyle(color: c.authTextSecondary),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Veuillez entrer une gare' : null,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _modifierGare(gare['id'], _gareController.text.trim());
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.authButton,
                  foregroundColor: c.authTextPrimary,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmerSuppression(BuildContext context) {
    final c = Config.colors;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.authCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirmer la suppression',
          style: TextStyle(
            color: c.authTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer cette entrée ?',
          style: TextStyle(color: c.authTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: TextStyle(color: c.authTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

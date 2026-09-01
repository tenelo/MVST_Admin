import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';

class Informations extends StatefulWidget {
  @override
  _InformationsState createState() => _InformationsState();
}

class _InformationsState extends State<Informations> {
  final TextEditingController villeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController confirmTelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _infos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    villeController.dispose();
    descriptionController.dispose();
    telephoneController.dispose();
    confirmTelController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.get('infosGares.php');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _infos = List<Map<String, dynamic>>.from(data['infos']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouter() async {
    try {
      await ApiClient.instance.post(
        'infosGares.php',
        body: {
          'action': 'ajouter',
          'ville': villeController.text,
          'description': descriptionController.text,
          'telephone': telephoneController.text,
        },
      );
      await _chargerDonnees();
    } catch (e) {}
  }

  Future<void> _modifier(int id) async {
    try {
      await ApiClient.instance.post(
        'infosGares.php',
        body: {
          'action': 'modifier',
          'id': id,
          'ville': villeController.text,
          'description': descriptionController.text,
          'telephone': telephoneController.text,
        },
      );
      await _chargerDonnees();
    } catch (e) {}
  }

  Future<void> _supprimer(int id) async {
    try {
      await ApiClient.instance.post(
        'infosGares.php',
        body: {'action': 'supprimer', 'id': id},
      );
      await _chargerDonnees();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.authCardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: c.authTextPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Informations Gares',
          style: TextStyle(
            color: c.authTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: sw * 0.045,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.authTextPrimary),
            onPressed: _chargerDonnees,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: c.authAccent))
          : _infos.isEmpty
          ? Center(
              child: Text(
                'Aucune donnée disponible.',
                style: TextStyle(
                  color: c.authTextSecondary,
                  fontFamily: 'Lobster',
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.06,
                vertical: sh * 0.02,
              ),
              itemCount: _infos.length,
              itemBuilder: (context, index) {
                final row = _infos[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.authBorder, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Icône gare ──────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: c.authAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_city,
                            color: c.authAccent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ── Infos ────────────────────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row['ville'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: c.authCardBackground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                row['description'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: c.authTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    row['telephone'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: c.authTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // ── Boutons ──────────────────────────────────────────
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: c.authAccent),
                              onPressed: () => _afficherBottomSheet(row: row),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: c.authCardBackground,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Text(
                                      'Confirmer la suppression',
                                      style: TextStyle(
                                        color: c.authTextPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Voulez-vous vraiment supprimer ?',
                                      style: TextStyle(
                                        color: c.authTextSecondary,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(
                                          'Annuler',
                                          style: TextStyle(
                                            color: c.authTextSecondary,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Supprimer',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true)
                                  await _supprimer(row['id']);
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
        backgroundColor: Config.colors.authButton,
        foregroundColor: Config.colors.authTextPrimary,
        onPressed: () => _afficherBottomSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _afficherBottomSheet({Map<String, dynamic>? row}) {
    final c = Config.colors;
    if (row != null) {
      villeController.text = row['ville'];
      descriptionController.text = row['description'];
      telephoneController.text = row['telephone'];
      confirmTelController.text = row['telephone'];
    } else {
      villeController.clear();
      descriptionController.clear();
      telephoneController.clear();
      confirmTelController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.authCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                row == null ? 'Ajouter une gare' : 'Modifier la gare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.authTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _themedField(
                controller: villeController,
                hint: 'Ville',
                c: c,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Entrer la ville' : null,
              ),
              const SizedBox(height: 8),
              _themedField(
                controller: descriptionController,
                hint: 'Description',
                c: c,
                maxLines: 5,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Entrer la description' : null,
              ),
              const SizedBox(height: 8),
              _themedField(
                controller: telephoneController,
                hint: 'Téléphone',
                c: c,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Entrer le téléphone' : null,
              ),
              const SizedBox(height: 8),
              _themedField(
                controller: confirmTelController,
                hint: 'Confirmer Téléphone',
                c: c,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirmer le téléphone';
                  if (v != telephoneController.text) {
                    return 'Les numéros ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (row == null) {
                      await _ajouter();
                    } else {
                      await _modifier(row['id']);
                    }
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
                child: Text(row == null ? 'Ajouter' : 'Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themedField({
    required TextEditingController controller,
    required String hint,
    required dynamic c,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.authCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.authBorder, width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        cursorColor: c.authAccent,
        style: TextStyle(color: c.authTextPrimary),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintText: hint,
          hintStyle: TextStyle(color: c.authTextSecondary),
        ),
        validator: validator,
      ),
    );
  }
}

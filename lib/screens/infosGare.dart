import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';

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

  // ── Charger les infos ──────────────────────────────────────────────────────
  Future<void> _chargerDonnees() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://mvst.tenelo.cloud/infosGares.php'),
      );
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

  // ── Ajouter ───────────────────────────────────────────────────────────────
  Future<void> _ajouter() async {
    try {
      await http.post(
        Uri.parse('https://mvst.tenelo.cloud/infosGares.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'ajouter',
          'ville': villeController.text,
          'description': descriptionController.text,
          'telephone': telephoneController.text,
        }),
      );
      await _chargerDonnees();
    } catch (e) {}
  }

  // ── Modifier ──────────────────────────────────────────────────────────────
  Future<void> _modifier(int id) async {
    try {
      await http.post(
        Uri.parse('https://mvst.tenelo.cloud/infosGares.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'modifier',
          'id': id,
          'ville': villeController.text,
          'description': descriptionController.text,
          'telephone': telephoneController.text,
        }),
      );
      await _chargerDonnees();
    } catch (e) {}
  }

  // ── Supprimer ─────────────────────────────────────────────────────────────
  Future<void> _supprimer(int id) async {
    try {
      await http.post(
        Uri.parse('https://mvst.tenelo.cloud/infosGares.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'supprimer', 'id': id}),
      );
      await _chargerDonnees();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Informations Gares",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(93, 12, 134, 195),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _chargerDonnees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _infos.isEmpty
          ? Center(
              child: Text(
                'Aucune donnée disponible.',
                style: TextStyle(
                  color: Config.colors.authCardBackground,
                  fontFamily: 'Lobster',
                ),
              ),
            )
          : ListView.builder(
              itemCount: _infos.length,
              itemBuilder: (context, index) {
                final row = _infos[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color.fromARGB(93, 12, 134, 195),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.lightBlue.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Icône gare ─────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(93, 12, 134, 195),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_city,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ── Infos ──────────────────────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row['ville'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 12, 134, 195),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                row['description'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    row['telephone'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // ── Boutons ────────────────────────────────────────────
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color.fromARGB(255, 12, 134, 195),
                              ),
                              onPressed: () => _afficherBottomSheet(row: row),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Color.fromARGB(255, 233, 75, 64),
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text(
                                      'Confirmer la suppression',
                                    ),
                                    content: const Text(
                                      'Voulez-vous vraiment supprimer ?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Supprimer',
                                          style: TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              233,
                                              75,
                                              64,
                                            ),
                                          ),
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
        onPressed: () => _afficherBottomSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _afficherBottomSheet({Map<String, dynamic>? row}) {
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
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: villeController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Entrer la ville' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 5,
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Entrer la description' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Entrer le téléphone' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmTelController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Confirmer Téléphone',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirmer le téléphone';
                  if (v != telephoneController.text)
                    return 'Les numéros ne correspondent pas';
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
                child: Text(row == null ? 'Ajouter' : 'Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

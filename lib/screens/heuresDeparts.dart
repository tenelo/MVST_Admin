import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';

class HeureDepart extends StatefulWidget {
  const HeureDepart({Key? key}) : super(key: key);

  @override
  _HeureDepartState createState() => _HeureDepartState();
}

class _HeureDepartState extends State<HeureDepart> {
  TimeOfDay? selectedTime;
  final TextEditingController _timeController = TextEditingController();
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _heures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerHeures();
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  // ── Charger les heures ─────────────────────────────────────────────────────
  Future<void> _chargerHeures() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://mvst.tenelo.cloud/heuresDepart.php'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _heures = List<Map<String, dynamic>>.from(
              data['heures'],
            ).where((h) => h['type']?.toString() == 'standard').toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Ajouter une heure ──────────────────────────────────────────────────────
  Future<void> _ajouterHeure(TimeOfDay time) async {
    setState(() => _isSaving = true);
    try {
      final formattedTime =
          '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      await http.post(
        Uri.parse('https://mvst.tenelo.cloud/heuresDepart.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'ajouter',
          'heure': formattedTime,
          'type': 'standard',
        }),
      );
      _timeController.clear();
      await _chargerHeures();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Config.colors.authCardBackground,
            content: Text('Heure de départ ajoutée : $formattedTime'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Erreur lors de l'ajout"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Modifier une heure ─────────────────────────────────────────────────────
  Future<void> _modifierHeure(int id, String heureActuelle) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(heureActuelle.split(':')[0]),
        minute: int.parse(heureActuelle.split(':')[1]),
      ),
    );

    if (time != null) {
      final formattedTime =
          '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      try {
        await http.post(
          Uri.parse('https://mvst.tenelo.cloud/heuresDepart.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'action': 'modifier',
            'id': id,
            'heure': formattedTime,
          }),
        );
        await _chargerHeures();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Config.colors.authCardBackground,
              content: Text('Heure modifiée : $formattedTime'),
            ),
          );
        }
      } catch (e) {}
    }
  }

  // ── Supprimer une heure ────────────────────────────────────────────────────
  Future<void> _supprimerHeure(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cette heure ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await http.post(
          Uri.parse('https://mvst.tenelo.cloud/heuresDepart.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'action': 'supprimer', 'id': id}),
        );
        await _chargerHeures();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Config.colors.authCardBackground,
              content: const Text('Heure supprimée'),
            ),
          );
        }
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Heures de Départs',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(93, 12, 134, 195),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _chargerHeures,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Champ heure ────────────────────────────────────────────
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.access_time),
                  labelText: 'Heure de départ (HH:mm)',
                ),
                readOnly: true,
                validator: (v) => v == null || v.isEmpty
                    ? 'Veuillez choisir une heure'
                    : null,
                onTap: () async {
                  selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selectedTime != null) {
                    _timeController.text = selectedTime!.format(context);
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _ajouterHeure(selectedTime!);
                        }
                      },
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ajouter'),
              ),
              const SizedBox(height: 20),
              // ── Liste des heures ────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _heures.isEmpty
                    ? const Center(child: Text('Aucune heure enregistrée'))
                    : ListView.builder(
                        itemCount: _heures.length,
                        itemBuilder: (context, index) {
                          final heure = _heures[index];
                          final timeParts = heure['heure'].toString().split(
                            ':',
                          );
                          final formattedTime =
                              '${timeParts[0]}:${timeParts[1].padLeft(2, '0')}';

                          return ListTile(
                            title: Text(formattedTime),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _modifierHeure(
                                    heure['id'],
                                    heure['heure'],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _supprimerHeure(heure['id']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

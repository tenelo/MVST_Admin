import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';

class HeureDepartVip extends StatefulWidget {
  const HeureDepartVip({Key? key}) : super(key: key);

  @override
  _HeureDepartVipState createState() => _HeureDepartVipState();
}

class _HeureDepartVipState extends State<HeureDepartVip> {
  TimeOfDay? selectedTime;
  final TextEditingController _timeController = TextEditingController();
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _heures = [];
  bool _isLoading = true;

  static const _or = Color(0xFFFFD700);
  static const _dark = Color(0xFF1A1A2E);

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

  Future<void> _chargerHeures() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.get(
        apiUri('heuresDepart.php?type=vip'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _heures = List<Map<String, dynamic>>.from(
              data['heures'],
            ).where((h) => h['type']?.toString() == 'vip').toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouterHeure(TimeOfDay selectedTime) async {
    setState(() => _isSaving = true);
    try {
      final formattedTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      await http.post(
        apiUri('heuresDepart.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'ajouter',
          'heure': formattedTime,
          'type': 'vip',
        }),
      );
      _timeController.clear();
      // selectedTime = null;  // ← SUPPRIME OU COMMENTE CETTE LIGNE
      await _chargerHeures();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _or,
            content: Text(
              'Heure VIP ajoutée : $formattedTime',
              style: const TextStyle(color: _dark, fontWeight: FontWeight.bold),
            ),
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

  Future<void> _modifierHeure(int id, String heureActuelle) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(heureActuelle.split(':')[0]),
        minute: int.parse(heureActuelle.split(':')[1]),
      ),
    );
    if (selectedTime != null) {
      final formattedTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      try {
        await http.post(
          apiUri('heuresDepart.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'action': 'modifier',
            'id': id,
            'heure': formattedTime,
            'type': 'vip',
          }),
        );
        await _chargerHeures();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: _or,
              content: Text(
                'Heure VIP modifiée : $formattedTime',
                style: const TextStyle(
                  color: _dark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
      } catch (e) {}
    }
  }

  Future<void> _supprimerHeure(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Confirmation', style: TextStyle(color: _or)),
        content: const Text(
          'Voulez-vous vraiment supprimer cette heure VIP ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Oui',
              style: TextStyle(color: Color.fromARGB(255, 233, 75, 64)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await http.post(
          apiUri('heuresDepart.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'action': 'supprimer', 'id': id}),
        );
        await _chargerHeures();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: _or,
              content: Text(
                'Heure VIP supprimée',
                style: TextStyle(color: _dark, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      } catch (e) {}
    }
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
          children: [
            Icon(Icons.star, color: _or, size: 18),
            SizedBox(width: 2),
            Flexible(
              child: Text(
                'Heures de Départs VIP',
                style: TextStyle(
                  color: _or,
                  fontWeight: FontWeight.bold,
                  //fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _or),
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
              // ── Champ heure ──────────────────────────────────────────
              TextFormField(
                controller: _timeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  icon: Icon(Icons.access_time, color: _or),
                  labelText: 'Heure de départ VIP (HH:mm)',
                  labelStyle: TextStyle(color: _or),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _or),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _or, width: 2),
                  ),
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
                    setState(
                      () =>
                          _timeController.text = selectedTime!.format(context),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _or),
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _ajouterHeure(selectedTime!);
                        }
                      },
                child: _isSaving
                    ? const CircularProgressIndicator(color: _dark)
                    : const Text(
                        'Ajouter',
                        style: TextStyle(
                          color: _dark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              // ── Liste des heures VIP ──────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _or))
                    : _heures.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune heure VIP enregistrée',
                          style: TextStyle(
                            color: _or,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _heures.length,
                        itemBuilder: (context, index) {
                          final heure = _heures[index];
                          final timeParts = heure['heure'].toString().split(
                            ':',
                          );
                          final hour = int.tryParse(timeParts[0]) ?? 0;
                          final minute = int.tryParse(timeParts[1]) ?? 0;
                          final formattedTime =
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _or, width: 1.2),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _or,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: _dark,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _or,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: _or),
                                    onPressed: () => _modifierHeure(
                                      heure['id'],
                                      heure['heure'],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color.fromARGB(255, 233, 75, 64),
                                    ),
                                    onPressed: () =>
                                        _supprimerHeure(heure['id']),
                                  ),
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
      ),
    );
  }
}

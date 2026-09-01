import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';

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

  Future<void> _chargerHeures() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.get('heuresDepart.php');
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

  Future<void> _ajouterHeure(TimeOfDay selectedTime) async {
    setState(() => _isSaving = true);
    try {
      final formattedTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      await ApiClient.instance.post(
        'heuresDepart.php',
        body: {
          'action': 'ajouter',
          'heure': formattedTime,
          'type': 'standard',
        },
      );
      _timeController.clear();
      await _chargerHeures();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Config.colors.authCardBackground,
            content: Text(
              'Heure de départ ajoutée : $formattedTime',
              style: TextStyle(color: Config.colors.authTextPrimary),
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
        await ApiClient.instance.post(
          'heuresDepart.php',
          body: {
            'action': 'modifier',
            'id': id,
            'heure': formattedTime,
          },
        );
        await _chargerHeures();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Config.colors.authCardBackground,
              content: Text(
                'Heure modifiée : $formattedTime',
                style: TextStyle(color: Config.colors.authTextPrimary),
              ),
            ),
          );
        }
      } catch (e) {}
    }
  }

  Future<void> _supprimerHeure(int id) async {
    final c = Config.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.authCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirmation',
          style: TextStyle(
            color: c.authTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer cette heure ?',
          style: TextStyle(color: c.authTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Non', style: TextStyle(color: c.authTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient.instance.post(
          'heuresDepart.php',
          body: {'action': 'supprimer', 'id': id},
        );
        await _chargerHeures();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Config.colors.authCardBackground,
              content: Text(
                'Heure supprimée',
                style: TextStyle(color: Config.colors.authTextPrimary),
              ),
            ),
          );
        }
      } catch (e) {}
    }
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
          'Heures de Départs',
          style: TextStyle(
            color: c.authTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: sw * 0.045,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.authTextPrimary),
            onPressed: _chargerHeures,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: sw * 0.06,
          vertical: sh * 0.02,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Champ heure ────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: c.authCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.authBorder, width: 1.5),
                ),
                child: TextFormField(
                  controller: _timeController,
                  cursorColor: c.authAccent,
                  style: TextStyle(color: c.authTextPrimary),
                  readOnly: true,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Veuillez choisir une heure'
                      : null,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedTime = picked;
                        _timeController.text = picked.format(context);
                      });
                    }
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: 'Heure de départ (HH:mm)',
                    hintStyle: TextStyle(color: c.authTextSecondary),
                    prefixIcon: Icon(Icons.access_time, color: c.authAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_formKey.currentState!.validate() &&
                            selectedTime != null) {
                          _ajouterHeure(selectedTime!);
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
                child: _isSaving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: c.authTextPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Ajouter'),
              ),
              const SizedBox(height: 20),
              // ── Liste des heures ───────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: c.authAccent),
                      )
                    : _heures.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune heure enregistrée',
                          style: TextStyle(color: c.authTextSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _heures.length,
                        itemBuilder: (context, index) {
                          final heure = _heures[index];
                          final timeParts =
                              heure['heure'].toString().split(':');
                          final hour = int.tryParse(timeParts[0]) ?? 0;
                          final minute = int.tryParse(timeParts[1]) ?? 0;
                          final formattedTime =
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(

                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.authBorder, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                      color: c.authCardBackground,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: c.authAccent,
                                        ),
                                        onPressed: () => _modifierHeure(
                                          heure['id'],
                                          heure['heure'],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _supprimerHeure(heure['id']),
                                      ),
                                    ],
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

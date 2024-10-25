import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mysql1/mysql1.dart';

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
  MySqlConnection? _connection;
  final StreamController<List<Map<String, dynamic>>> _streamController =
      StreamController();

  @override
  void initState() {
    super.initState();
    _initialiserDB().then((_) {
      _chargerHeuresEnTempsReel();
    });
  }

  Future<void> _initialiserDB() async {
    try {
      _connection = await Connexion.connexionDB();
    } catch (e) {
      print('Erreur lors de la connexion à la base de données: $e');
    }
  }

  Future<void> _chargerHeuresEnTempsReel() async {
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _recupHeuresDeDeparts();
    });
  }

  Future<void> _ajouterHeureDeDepart(TimeOfDay time) async {
    try {
      if (_connection == null) {
        await _initialiserDB();
      }

      var result =
          await _connection!.query("SHOW TABLES LIKE 'HeuresDeDeparts'");
      if (result.isEmpty) {
        await _connection!.query('''
          CREATE TABLE HeuresDeDeparts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            heure VARCHAR(10),
            dateCreation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      }

      setState(() {
        _isSaving = true;
      });

      String formattedTime =
          '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      print("L'HEURE AJOUTEE AVANT EST : $formattedTime");
      await _connection!.query(
        'INSERT INTO HeuresDeDeparts (heure) VALUES (?)',
        [formattedTime],
      );
      print("L'HEURE AJOUTEE APRES EST : $formattedTime");
      _timeController.clear();
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Config.colors.bleuFonce2,
          content: Text('Heure de départ ajoutée : $formattedTime'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: const Text('Erreur lors de l\'ajout de l\'heure de départ'),
        ),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _recupHeuresDeDeparts() async {
    try {
      if (_connection == null) {
        await _initialiserDB();
      }

      var results = await _connection!.query('SELECT * FROM HeuresDeDeparts');
      List<Map<String, dynamic>> heures = results.map((row) {
        return {
          'id': row[0],
          'heure': row[1],
        };
      }).toList();

      _streamController.add(heures);
    } catch (e) {
      print("Erreur lors de la récupération des heures de départ: $e");
    }
  }

  Future<void> _modifierHeureDeDepart(int id, String heure) async {
    try {
      if (_connection == null) {
        await _initialiserDB();
      }

      selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
            hour: int.parse(heure.split(':')[0]),
            minute: int.parse(heure.split(':')[1])),
      );

      if (selectedTime != null) {
        String formattedTime =
            '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}';
        await _connection!.query(
            'UPDATE HeuresDeDeparts SET heure = ? WHERE id = ?',
            [formattedTime, id]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Config.colors.bleuFonce2,
            content: Text('Heure de départ modifiée : $formattedTime'),
          ),
        );
      }
    } catch (e) {
      print("Erreur lors de la modification de l'heure de départ: $e");
    }
  }

  Future<void> _supprimerHeureDeDepart(int id) async {
    try {
      if (_connection == null) {
        await _initialiserDB();
      }

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: const Text(
                'Voulez-vous vraiment supprimer cette heure de départ ?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop(); // Fermer la boîte de dialogue
                },
                child: const Text('Non'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext)
                      .pop(); // Fermer la boîte de dialogue

                  // Supprimer l'heure de départ de la base de données
                  await _connection!
                      .query('DELETE FROM HeuresDeDeparts WHERE id = ?', [id]);

                  // Appeler une méthode pour afficher le SnackBar
                  _afficherSnackBar();
                },
                child: const Text('Oui'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Erreur lors de la suppression de l'heure de départ: $e");
    }
  }

  void _afficherSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Config.colors.bleuFonce2,
          content: const Text('Heure de départ supprimée'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _connection?.close();
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Heures de Départs',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(93, 12, 134, 195),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.access_time),
                  labelText: 'Heure de départ (HH:mm)',
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez choisir une heure de départ';
                  }
                  return null;
                },
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
                          _ajouterHeureDeDepart(selectedTime!);
                        }
                      },
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ajouter'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _streamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erreur: ${snapshot.error}'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final documents = snapshot.data ?? [];

                    // Vérification si la table est vide
                    if (documents.isEmpty) {
                      return const Center(
                        child: Text('Aucune donnée enregistrée'),
                      );
                    }

                    return ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        // Récupération de l'heure
                        final heure = documents[index]['heure'].toString();
                        final id = documents[index]['id'];

                        // Formatage de l'heure (comme dans le SnackBar)
                        final timeParts = heure.split(':');
                        final formattedTime =
                            '${timeParts[0]}:${timeParts[1].padLeft(2, '0')}';

                        return ListTile(
                          title: Text(
                              formattedTime), // Affichage de l'heure formatée
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _modifierHeureDeDepart(id, heure);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _supprimerHeureDeDepart(id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
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

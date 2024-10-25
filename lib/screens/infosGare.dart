import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mysql1/mysql1.dart';

class Informations extends StatefulWidget {
  @override
  _InformationsState createState() => _InformationsState();
}

class _InformationsState extends State<Informations> {
  final TextEditingController villeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController confirmTelephoneController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  MySqlConnection? _connection;

  final StreamController<List<Map<String, dynamic>>> _streamController =
      StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    _initialiserDB(); // Initialiser la connexion à la BD lors du démarrage
    _chargerDonnees(); // Charger initialement les données dans le stream
  }

  Future<void> _initialiserDB() async {
    try {
      _connection = await Connexion.connexionDB();
    } catch (e) {
      print('Erreur lors de la connexion à la base de données: $e');
      _connection = null; // Marquer la connexion comme échouée
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          "Informations Gares",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(93, 12, 134, 195),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamController.stream, // Utilisation du Stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final row = data[index];
                return ListTile(
                  title: Text(row['ville']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row['description']),
                      SizedBox(height: 5),
                      Text("Télephone : ${row['telephone']}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showBottomSheet(row: row),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Confirmer la suppression'),
                                content: Text(
                                    'Voulez-vous vraiment supprimer cette entrée ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: Text('Supprimer'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            await _supprimer(row['id']);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Text(
                'Aucune donnée disponible.',
                style: TextStyle(
                  color: Config.colors.bleuFonce2,
                  fontFamily: 'Lobster',
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBottomSheet(),
        child: Icon(Icons.add),
      ),
    );
  }

  // Charger les données initiales dans le Stream
  Future<void> _chargerDonnees() async {
    List<Map<String, dynamic>> data = await _recupDonnees();
    _streamController.add(data); // Ajouter les données au flux
  }

  Future<List<Map<String, dynamic>>> _recupDonnees() async {
    try {
      await _initialiserDB(); // Assurez-vous d'avoir une connexion

      if (_connection != null) {
        var results = await _connection!.query('SELECT * FROM InfosGares');
        return results
            .map((row) => {
                  'id': row['id'],
                  'ville': row['ville'],
                  'description': row['description'],
                  'telephone': row['telephone'],
                })
            .toList();
      } else {
        throw Exception(
            "Impossible d'établir une connexion à la base de données.");
      }
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      return [];
    }
  }

  Future<void> _ajouterInformations() async {
    final conn = await Connexion.connexionDB();

    try {
      await conn.query('''
      CREATE TABLE IF NOT EXISTS InfosGares (
        id INT AUTO_INCREMENT PRIMARY KEY,
        ville VARCHAR(50),
        description VARCHAR(255),
        telephone VARCHAR(15)
      )
    ''');

      await conn.query(
        'INSERT INTO InfosGares (ville, description, telephone) VALUES (?, ?, ?)',
        [
          villeController.text,
          descriptionController.text,
          telephoneController.text
        ],
      );

      _chargerDonnees(); // Recharger les données après ajout
    } catch (error) {
      print('Erreur lors de l\'ajout des informations: $error');
    } finally {
      await conn.close();
    }
  }

  void _showBottomSheet({Map<String, dynamic>? row}) {
    if (row != null) {
      villeController.text = row['ville'];
      descriptionController.text = row['description'];
      telephoneController.text = row['telephone'];
      confirmTelephoneController.text = row['telephone'];
    } else {
      villeController.clear();
      descriptionController.clear();
      telephoneController.clear();
      confirmTelephoneController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: villeController,
                  decoration: InputDecoration(
                    labelText: 'Ville',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entrer la ville';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  maxLines: 5,
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entrer la description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: telephoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entrer numéro de téléphone';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: confirmTelephoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Confirmer Téléphone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirmer numéro de téléphone';
                    }
                    if (value != telephoneController.text) {
                      return 'Les numéros de téléphone ne correspondent pas';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (row == null) {
                        await _ajouterInformations();
                      } else {
                        await _modifierInformations(row['id']);
                      }
                      Navigator.of(context).pop(); // Fermer la modal
                    }
                  },
                  child: Text(row == null ? 'Ajouter' : 'Modifier'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _modifierInformations(int id) async {
    final _conn = await Connexion.connexionDB();
    try {
      // Vérifiez la connexion
      var result = await _conn.query(
        'UPDATE InfosGares SET ville = ?, description = ?, telephone = ? WHERE id = ?',
        [
          villeController.text,
          descriptionController.text,
          telephoneController.text,
          id,
        ],
      );

      // Vérifier si la mise à jour a été effectuée
      if (result.affectedRows == 0) {
        print('Aucune ligne mise à jour. Vérifiez si l\'ID est correct.');
      } else {
        print('Mise à jour réussie de l\'enregistrement.');
        await _chargerDonnees(); // Recharger les données après modification
      }
    } catch (error) {
      print('Erreur lors de la modification ');
    } finally {
      await _conn.close();
    }
  }

  Future<void> _supprimer(int id) async {
    try {
      if (_connection == null) {
        _connection = await Connexion.connexionDB();
      }
      var result =
          await _connection!.query('DELETE FROM InfosGares WHERE id = ?', [id]);

      // Vérifier si la suppression a bien été effectuée
      if (result.affectedRows == 0) {
        print('Aucune ligne supprimée. Vérifiez si l\'ID est correct.');
      } else {
        print('Suppression réussie.');
        await _chargerDonnees(); // Recharger les données après suppression
      }
    } catch (error) {
      print('Erreur lors de la supression ');
    } finally {
      if (_connection != null) {
        await _connection!.close();
      }
    }
  }

  @override
  void dispose() {
    villeController.dispose();
    descriptionController.dispose();
    telephoneController.dispose();
    confirmTelephoneController.dispose();
    _streamController.close(); // Fermer le stream
    if (_connection != null) {
      _connection?.close();
    }
    super.dispose();
  }
}

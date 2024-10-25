import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mysql1/mysql1.dart';

class GareDorigine extends StatefulWidget {
  const GareDorigine({super.key});

  @override
  _GareDorigineState createState() => _GareDorigineState();
}

class _GareDorigineState extends State<GareDorigine> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _gareController = TextEditingController();
  List<Map<String, dynamic>> __gareDatasList = [];
  MySqlConnection? _connection;
  final StreamController<List<Map<String, dynamic>>> _streamController =
      StreamController();
  bool _isLoading = true; // Indicateur de chargement

  @override
  void initState() {
    super.initState();
    _initialiserDB();
  }

  // Initialise la connexion à la base de données MySQL
  Future<void> _initialiserDB() async {
    _connection = await Connexion.connexionDB();
    await verifEtCreationDeTable();
    await rafraichirDonnees();
  }

  // Vérifie et ouvre la connexion si elle est fermée
  Future<void> _verifierEtOuvrirConnexion() async {
    _connection = await Connexion.connexionDB();
  }

// Vérifie si la table existe et la crée si nécessaire
  Future<void> verifEtCreationDeTable() async {
    await _verifierEtOuvrirConnexion();
    if (_connection != null) {
      var result = await _connection!.query("SHOW TABLES LIKE 'GareDorigine'");

      // Si la table n'existe pas, la créer
      if (result.isEmpty) {
        await _connection!.query('''CREATE TABLE GareDorigine (
        id INT AUTO_INCREMENT PRIMARY KEY,
        gare VARCHAR(50)
      )''');
      }
    }
  }

  // Récupère les données de la table GareDorigine
  Future<void> rafraichirDonnees() async {
    setState(() {
      _isLoading = true; // Commencer le chargement
    });
    await _verifierEtOuvrirConnexion();
    if (_connection != null) {
      var results = await _connection!.query('SELECT * FROM GareDorigine');
      __gareDatasList = results
          .map((row) => {
                'id': row['id'],
                'gare': row['gare'],
              })
          .toList();
      _streamController.add(__gareDatasList);
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(93, 12, 134, 195),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        centerTitle: true,
        title: const Text(
          'Gare d\'origine ',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (_isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Aucune donnée disponible',
                style: TextStyle(
                  color: Config.colors.bleuFonce2,
                  fontFamily: 'Lobster',
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final _gareData = snapshot.data![index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Card(
                  margin: const EdgeInsets.all(4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_gareData['gare']),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _modifierGareDorigine(context, _gareData),
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
                                  await _supprimerGareDorigine(_gareData['id']);
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ajouterGareDorigine(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Ajout de prix des _gareDatas
  void _ajouterGareDorigine(BuildContext context) async {
    await _verifierEtOuvrirConnexion();
    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: true,
      context: context,
      builder: (BuildContext ctx) {
        return Wrap(
          children: [
            Padding(
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
                      decoration: const InputDecoration(labelText: 'gare'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un gare.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final gare = _gareController.text.trim();
                          await _verifierEtOuvrirConnexion();
                          await _connection!.query(
                              'INSERT INTO GareDorigine (gare) VALUES (?)',
                              [gare]);

                          _gareController.clear();
                          Navigator.of(context).pop();
                          rafraichirDonnees(); // Rafraîchir les données
                        }
                      },
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Modification du prix des _gareDatas
  void _modifierGareDorigine(
      BuildContext context, Map<String, dynamic> _gareData) async {
    await _verifierEtOuvrirConnexion();
    _gareController.text = _gareData['gare'];

    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: true,
      context: context,
      builder: (BuildContext ctx) {
        return Wrap(
          children: [
            Padding(
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
                      decoration: const InputDecoration(labelText: 'gare'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un gare.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final gare = _gareController.text.trim();
                          await _verifierEtOuvrirConnexion();
                          await _connection!.query(
                              'UPDATE GareDorigine SET gare = ? = ? WHERE id = ?',
                              [gare, _gareData['id']]);

                          _gareController.clear();
                          Navigator.of(context).pop();
                          rafraichirDonnees(); // Rafraîchir les données
                        }
                      },
                      child: const Text('Modifier'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Suppression du prix des _gareDatas
  Future<void> _supprimerGareDorigine(int id) async {
    await _verifierEtOuvrirConnexion();
    await _connection!.query('DELETE FROM GareDorigine WHERE id = ?', [id]);
    rafraichirDonnees(); // Rafraîchir les données
  }

  @override
  void dispose() {
    _streamController.close();
    _gareController.dispose();
    super.dispose();
  }
}

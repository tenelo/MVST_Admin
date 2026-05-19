import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';

class LignesStandard extends StatefulWidget {
  const LignesStandard({super.key});

  @override
  _LignesStandardState createState() => _LignesStandardState();
}

class _LignesStandardState extends State<LignesStandard> {
  // Clés distinctes pour chaque formulaire
  final _formKeyAjout = GlobalKey<FormState>();
  final _formKeyModif = GlobalKey<FormState>();
  final TextEditingController _prixController = TextEditingController();

  List<String> _gares = [];
  List<Map<String, dynamic>> _lignesList = [];
  bool _isLoading = true;

  // États de chargement pour chaque action
  bool _isAdding = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(apiUri('gares.php')),
        http.get(apiUri('api_lignes.php')),
      ]);
      if (!mounted) return;

      final garesData = jsonDecode(results[0].body);
      final lignesData = jsonDecode(results[1].body);

      setState(() {
        if (garesData['success'] == true) {
          _gares = List<Map<String, dynamic>>.from(
            garesData['gares'],
          ).map((g) => g['gare'].toString()).toList();
        }
        if (lignesData['success'] == true) {
          _lignesList = List<Map<String, dynamic>>.from(lignesData['lignes']);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _afficherMessage('Erreur de chargement: $e');
    }
  }

  Future<void> _rafraichirLignes() async {
    try {
      final response = await http.get(
        apiUri('api_lignes.php'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _lignesList = List<Map<String, dynamic>>.from(data['lignes']);
          });
        }
      }
    } catch (e) {
      if (mounted) _afficherMessage('Erreur de rafraîchissement: $e');
    }
  }

  // ── Ajouter avec loader ──────────────────────────────────────────────────
  Future<void> _ajouter(String depart, String destination, int prix) async {
    if (!mounted) return;
    setState(() => _isAdding = true);

    try {
      final response = await http.post(
        apiUri('api_lignes.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'ajouter',
          'depart': depart,
          'destination': destination,
          'ligne': '$depart $destination',
          'prix': prix,
          'type': 'standard',
        }),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _rafraichirLignes();
          _afficherMessage('Ligne ajoutée avec succès', isError: false);
        } else {
          _afficherMessage('Erreur: ${data['message'] ?? "Échec de l'ajout"}');
        }
      }
    } catch (e) {
      if (mounted) _afficherMessage('Erreur de connexion: $e');
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  // ── Modifier avec loader ─────────────────────────────────────────────────
  Future<void> _modifier(
    int id,
    String depart,
    String destination,
    int prix,
  ) async {
    if (!mounted) return;
    setState(() => _isUpdating = true);

    try {
      final response = await http.post(
        apiUri('api_lignes.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'modifier',
          'id': id,
          'depart': depart,
          'destination': destination,
          'ligne': '$depart $destination',
          'prix': prix,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _rafraichirLignes();
          _afficherMessage('Ligne modifiée avec succès', isError: false);
        } else {
          _afficherMessage(
            'Erreur: ${data['message'] ?? "Échec de la modification"}',
          );
        }
      }
    } catch (e) {
      if (mounted) _afficherMessage('Erreur de connexion: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ── Supprimer avec loader ────────────────────────────────────────────────
  Future<void> _supprimer(int id) async {
    if (!mounted) return;
    setState(() => _isDeleting = true);

    try {
      final response = await http.post(
        apiUri('api_lignes.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'supprimer', 'id': id}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _rafraichirLignes();
          _afficherMessage('Ligne supprimée avec succès', isError: false);
        } else {
          _afficherMessage(
            'Erreur: ${data['message'] ?? "Échec de la suppression"}',
          );
        }
      }
    } catch (e) {
      if (mounted) _afficherMessage('Erreur de connexion: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ── Afficher un message SnackBar ─────────────────────────────────────────
  void _afficherMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Loader overlay ───────────────────────────────────────────────────────
  Widget _buildLoaderOverlay({required bool isLoading, required Widget child}) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(93, 12, 134, 195),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Lignes Standard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _chargerDonnees,
          ),
        ],
      ),
      body: _buildLoaderOverlay(
        isLoading: _isDeleting, // Loader global pour la suppression
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _lignesList.isEmpty
            ? Center(
                child: Text(
                  'Aucune ligne disponible',
                  style: TextStyle(
                    color: Config.colors.authCardBackground,
                    fontFamily: 'Lobster',
                  ),
                ),
              )
            : ListView.builder(
                itemCount: _lignesList.length,
                itemBuilder: (context, index) {
                  final ligne = _lignesList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
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
                                Text(
                                  ligne['ligne'].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('${ligne['prix']} f'),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: _isUpdating
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.edit),
                                  onPressed: _isUpdating
                                      ? null
                                      : () => _afficherModalModifier(
                                          context,
                                          ligne,
                                        ),
                                ),
                                IconButton(
                                  icon: _isDeleting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.delete),
                                  onPressed: _isDeleting
                                      ? null
                                      : () async {
                                          final confirm =
                                              await _confirmerSuppression(
                                                context,
                                              );
                                          if (confirm == true) {
                                            await _supprimer(ligne['id']);
                                          }
                                        },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isAdding ? null : () => _afficherModalAjouter(context),
        child: _isAdding
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  // ── Modal Ajouter ────────────────────────────────────────────────────────
  void _afficherModalAjouter(BuildContext context) {
    String? departSelectionne;
    String? destinationSelectionnee;
    _prixController.clear();
    _formKeyAjout.currentState?.reset();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final destinationsDisponibles = _gares
              .where((g) => g != departSelectionne)
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20,
            ),
            child: Form(
              key: _formKeyAjout,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nouvelle ligne',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: departSelectionne,
                    decoration: const InputDecoration(labelText: 'Départ'),
                    items: _gares
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        departSelectionne = val;
                        if (destinationSelectionnee == val) {
                          destinationSelectionnee = null;
                        }
                      });
                    },
                    validator: (v) => v == null ? 'Choisissez un départ' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value:
                        destinationsDisponibles.contains(
                          destinationSelectionnee,
                        )
                        ? destinationSelectionnee
                        : null,
                    decoration: const InputDecoration(labelText: 'Destination'),
                    items: destinationsDisponibles
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => destinationSelectionnee = val),
                    validator: (v) =>
                        v == null ? 'Choisissez une destination' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _prixController,
                    decoration: const InputDecoration(labelText: 'Prix (f)'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Veuillez entrer un prix';
                      }
                      if (int.tryParse(v) == null) {
                        return 'Entrer un nombre valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Bouton avec loader intégré
                  ElevatedButton(
                    onPressed: _isAdding
                        ? null
                        : () async {
                            if (_formKeyAjout.currentState!.validate()) {
                              Navigator.of(
                                context,
                              ).pop(); // Ferme le modal d'abord
                              await _ajouter(
                                departSelectionne!,
                                destinationSelectionnee!,
                                int.parse(_prixController.text.trim()),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: _isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ajouter'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Modal Modifier ───────────────────────────────────────────────────────
  void _afficherModalModifier(
    BuildContext context,
    Map<String, dynamic> ligne,
  ) {
    String? departSelectionne = ligne['depart']?.toString();
    String? destinationSelectionnee = ligne['destination']?.toString();
    _prixController.text = ligne['prix'].toString();
    _formKeyModif.currentState?.reset();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final destinationsDisponibles = _gares
              .where((g) => g != departSelectionne)
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20,
            ),
            child: Form(
              key: _formKeyModif,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Modifier la ligne',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _gares.contains(departSelectionne)
                        ? departSelectionne
                        : null,
                    decoration: const InputDecoration(labelText: 'Départ'),
                    items: _gares
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        departSelectionne = val;
                        if (destinationSelectionnee == val) {
                          destinationSelectionnee = null;
                        }
                      });
                    },
                    validator: (v) => v == null ? 'Choisissez un départ' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value:
                        destinationsDisponibles.contains(
                          destinationSelectionnee,
                        )
                        ? destinationSelectionnee
                        : null,
                    decoration: const InputDecoration(labelText: 'Destination'),
                    items: destinationsDisponibles
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => destinationSelectionnee = val),
                    validator: (v) =>
                        v == null ? 'Choisissez une destination' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _prixController,
                    decoration: const InputDecoration(labelText: 'Prix (f)'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Veuillez entrer un prix';
                      }
                      if (int.tryParse(v) == null) {
                        return 'Entrer un nombre valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Bouton avec loader intégré
                  ElevatedButton(
                    onPressed: _isUpdating
                        ? null
                        : () async {
                            if (_formKeyModif.currentState!.validate()) {
                              Navigator.of(
                                context,
                              ).pop(); // Ferme le modal d'abord
                              await _modifier(
                                ligne['id'],
                                departSelectionne!,
                                destinationSelectionnee!,
                                int.parse(_prixController.text.trim()),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Modifier'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmerSuppression(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette ligne ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

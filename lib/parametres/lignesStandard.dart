import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';

class LignesStandard extends StatefulWidget {
  const LignesStandard({super.key});

  @override
  _LignesStandardState createState() => _LignesStandardState();
}

class _LignesStandardState extends State<LignesStandard> {
  final _formKeyAjout = GlobalKey<FormState>();
  final _formKeyModif = GlobalKey<FormState>();
  final TextEditingController _prixController = TextEditingController();

  List<String> _gares = [];
  List<Map<String, dynamic>> _lignesList = [];
  bool _isLoading = true;

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
        ApiClient.instance.get('gares.php'),
        ApiClient.instance.get('api_lignes.php'),
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
      final response = await ApiClient.instance.get('api_lignes.php');
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

  Future<void> _ajouter(String depart, String destination, int prix) async {
    if (!mounted) return;
    setState(() => _isAdding = true);
    try {
      final response = await ApiClient.instance.post(
        'api_lignes.php',
        body: {
          'action': 'ajouter',
          'depart': depart,
          'destination': destination,
          'ligne': '$depart $destination',
          'prix': prix,
          'type': 'standard',
        },
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

  Future<void> _modifier(
    int id,
    String depart,
    String destination,
    int prix,
  ) async {
    if (!mounted) return;
    setState(() => _isUpdating = true);
    try {
      final response = await ApiClient.instance.post(
        'api_lignes.php',
        body: {
          'action': 'modifier',
          'id': id,
          'depart': depart,
          'destination': destination,
          'ligne': '$depart $destination',
          'prix': prix,
        },
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

  Future<void> _supprimer(int id) async {
    if (!mounted) return;
    setState(() => _isDeleting = true);
    try {
      final response = await ApiClient.instance.post(
        'api_lignes.php',
        body: {'action': 'supprimer', 'id': id},
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
          'Lignes Standard',
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
      body: _buildLoaderOverlay(
        isLoading: _isDeleting,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: c.authAccent))
            : _lignesList.isEmpty
            ? Center(
                child: Text(
                  'Aucune ligne disponible',
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
                itemCount: _lignesList.length,
                itemBuilder: (context, index) {
                  final ligne = _lignesList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ligne['ligne'].toString(),
                                style: TextStyle(
                                  color: c.authCardBackground,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${ligne['prix']} f',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: _isUpdating
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: c.authAccent,
                                        ),
                                      )
                                    : Icon(Icons.edit, color: c.authAccent),
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
                                          color: Colors.red,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
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
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.authButton,
        foregroundColor: c.authTextPrimary,
        onPressed: _isAdding ? null : () => _afficherModalAjouter(context),
        child: _isAdding
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Config.colors.authTextPrimary,
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  void _afficherModalAjouter(BuildContext context) {
    final c = Config.colors;
    String? departSelectionne;
    String? destinationSelectionnee;
    _prixController.clear();
    _formKeyAjout.currentState?.reset();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: c.authCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final destinationsDisponibles = _gares
              .where((g) => g != departSelectionne)
              .toList();

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: _formKeyAjout,
              child: Column(
                children: [
                  Text(
                    'Nouvelle ligne',
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
                    child: DropdownButtonFormField<String>(
                      value: departSelectionne,
                      dropdownColor: c.authCardBackground,
                      iconEnabledColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        hintText: 'Départ',
                        hintStyle: TextStyle(color: c.authTextSecondary),
                      ),
                      items: _gares
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          departSelectionne = val;
                          if (destinationSelectionnee == val) {
                            destinationSelectionnee = null;
                          }
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Choisissez un départ' : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: c.authCardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1.5),
                    ),
                    child: DropdownButtonFormField<String>(
                      value:
                          destinationsDisponibles.contains(
                            destinationSelectionnee,
                          )
                          ? destinationSelectionnee
                          : null,
                      dropdownColor: c.authCardBackground,
                      iconEnabledColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        hintText: 'Destination',
                        hintStyle: TextStyle(color: c.authTextSecondary),
                      ),
                      items: destinationsDisponibles
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => destinationSelectionnee = val),
                      validator: (v) =>
                          v == null ? 'Choisissez une destination' : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: c.authCardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1.5),
                    ),
                    child: TextFormField(
                      controller: _prixController,
                      cursorColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        hintText: 'Prix (f)',
                        hintStyle: TextStyle(color: c.authTextSecondary),
                      ),
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
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isAdding
                        ? null
                        : () async {
                            if (_formKeyAjout.currentState!.validate()) {
                              Navigator.of(context).pop();
                              await _ajouter(
                                departSelectionne!,
                                destinationSelectionnee!,
                                int.parse(_prixController.text.trim()),
                              );
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
                    child: _isAdding
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.authTextPrimary,
                            ),
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

  void _afficherModalModifier(
    BuildContext context,
    Map<String, dynamic> ligne,
  ) {
    final c = Config.colors;
    String? departSelectionne = ligne['depart']?.toString();
    String? destinationSelectionnee = ligne['destination']?.toString();
    _prixController.text = ligne['prix'].toString();
    _formKeyModif.currentState?.reset();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: c.authCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final destinationsDisponibles = _gares
              .where((g) => g != departSelectionne)
              .toList();

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: _formKeyModif,
              child: Column(
                children: [
                  Text(
                    'Modifier la ligne',
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
                    child: DropdownButtonFormField<String>(
                      value: _gares.contains(departSelectionne)
                          ? departSelectionne
                          : null,
                      dropdownColor: c.authCardBackground,
                      iconEnabledColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        hintText: 'Départ',
                        hintStyle: TextStyle(color: c.authTextSecondary),
                      ),
                      items: _gares
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          departSelectionne = val;
                          if (destinationSelectionnee == val) {
                            destinationSelectionnee = null;
                          }
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Choisissez un départ' : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: c.authCardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1.5),
                    ),
                    child: DropdownButtonFormField<String>(
                      value:
                          destinationsDisponibles.contains(
                            destinationSelectionnee,
                          )
                          ? destinationSelectionnee
                          : null,
                      dropdownColor: c.authCardBackground,
                      iconEnabledColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        hintText: 'Destination',
                        hintStyle: TextStyle(color: c.authTextSecondary),
                      ),
                      items: destinationsDisponibles
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => destinationSelectionnee = val),
                      validator: (v) =>
                          v == null ? 'Choisissez une destination' : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: c.authCardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1.5),
                    ),
                    child: TextFormField(
                      controller: _prixController,
                      cursorColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        hintText: 'Prix (f)',
                        hintStyle: TextStyle(color: c.authTextSecondary),
                      ),
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
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isUpdating
                        ? null
                        : () async {
                            if (_formKeyModif.currentState!.validate()) {
                              Navigator.of(context).pop();
                              await _modifier(
                                ligne['id'],
                                departSelectionne!,
                                destinationSelectionnee!,
                                int.parse(_prixController.text.trim()),
                              );
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
                    child: _isUpdating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.authTextPrimary,
                            ),
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
          'Voulez-vous vraiment supprimer cette ligne ?',
          style: TextStyle(color: c.authTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(color: c.authTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

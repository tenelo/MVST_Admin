// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';

class GestionAdmins extends StatefulWidget {
  const GestionAdmins({super.key});

  @override
  _GestionAdminsState createState() => _GestionAdminsState();
}

class _GestionAdminsState extends State<GestionAdmins> {
  final _telephoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _roleSelectionne = 'admin';
  String? _gareSelectionnee;
  List<String> _listeGares = [];
  List<Map<String, dynamic>> _listeAdmins = [];
  bool _isLoading = false;
  bool _isLoadingListe = true;
  String? _erreur;
  String? _succes;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    await Future.wait([_recupererGares(), _recupererListeAdmins()]);
  }

  Future<void> _recupererGares() async {
    try {
      final response = await http.get(apiUri('gares.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _listeGares = List<String>.from(
              data['gares'].map((g) => g['gare'].toString()),
            );
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _recupererListeAdmins() async {
    setState(() => _isLoadingListe = true);
    try {
      final response = await http.get(apiUri('listeAdmins.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _listeAdmins = List<Map<String, dynamic>>.from(data['admins']);
          });
        }
      }
    } catch (e) {}
    if (mounted) setState(() => _isLoadingListe = false);
  }

  Future<void> _ajouterNumero() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gareSelectionnee == null) {
      setState(() => _erreur = 'Veuillez sélectionner une gare.');
      return;
    }

    setState(() {
      _isLoading = true;
      _erreur = null;
      _succes = null;
    });

    try {
      final response = await http.post(
        apiUri('ajouterNumeroAdmin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telephone': _telephoneController.text.trim(),
          'role': _roleSelectionne,
          'gare': _gareSelectionnee,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _succes = 'Numéro ajouté avec succès.';
            _telephoneController.clear();
            _gareSelectionnee = null;
            _roleSelectionne = 'admin';
          });
          await _recupererListeAdmins();
        } else {
          setState(() => _erreur = data['message'] ?? 'Erreur inconnue.');
        }
      }
    } catch (e) {
      setState(() => _erreur = 'Erreur réseau. Réessayez.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _modifierNumero(Map<String, dynamic> admin) async {
    final telephoneCtrl = TextEditingController(text: admin['telephone'] ?? '');
    String roleSelectionne = admin['role'] ?? 'admin';
    String? gareSelectionnee = admin['gare'];
    final formKey = GlobalKey<FormState>();
    String? erreurModal;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Config.colors.authCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final c = Config.colors;
          final sw = MediaQuery.of(ctx2).size.width;
          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: sw * 0.06,
              right: sw * 0.06,
              bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modifier les informations',
                    style: TextStyle(
                      color: c.authTextPrimary,
                      fontSize: sw * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ téléphone
                  Container(
                    decoration: BoxDecoration(
                      color: c.authBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1.5),
                    ),
                    child: TextFormField(
                      controller: telephoneCtrl,
                      maxLength: 10,
                      keyboardType: TextInputType.phone,
                      cursorColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'Ex: 0505050505',
                        hintStyle: TextStyle(color: c.authTextSecondary),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: c.authAccent,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Veuillez entrer un numéro';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                          return 'Numéro invalide (10 chiffres)';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Dropdown rôle
                  Container(
                    decoration: BoxDecoration(
                      color: c.authBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1.5),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: roleSelectionne,
                      dropdownColor: c.authCardBackground,
                      iconEnabledColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                          value: 'superadmin',
                          child: Text('Super Admin'),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => roleSelectionne = value!),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Rôle',
                        labelStyle: TextStyle(color: c.authTextSecondary),
                        prefixIcon: Icon(
                          Icons.admin_panel_settings_outlined,
                          color: c.authAccent,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Dropdown gare
                  Container(
                    decoration: BoxDecoration(
                      color: c.authBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1.5),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _listeGares.contains(gareSelectionnee)
                          ? gareSelectionnee
                          : null,
                      dropdownColor: c.authCardBackground,
                      iconEnabledColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      items: _listeGares.map((gare) {
                        return DropdownMenuItem<String>(
                          value: gare,
                          child: Text(
                            gare,
                            style: TextStyle(color: c.authTextPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setModalState(() => gareSelectionnee = value),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Gare',
                        labelStyle: TextStyle(color: c.authTextSecondary),
                        prefixIcon: Icon(
                          Icons.location_city_outlined,
                          color: c.authAccent,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),

                  if (erreurModal != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      erreurModal!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.authButton,
                        foregroundColor: c.authTextPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (gareSelectionnee == null) {
                          setModalState(
                            () =>
                                erreurModal = 'Veuillez sélectionner une gare.',
                          );
                          return;
                        }

                        try {
                          final response = await http.post(
                            apiUri('modifierNumeroAdmin.php'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'id': admin['id'],
                              'telephone': telephoneCtrl.text.trim(),
                              'role': roleSelectionne,
                              'gare': gareSelectionnee,
                            }),
                          );

                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);
                            if (data['success'] == true) {
                              Navigator.pop(ctx);
                              await _recupererListeAdmins();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.green,
                                    content: Text(
                                      'Informations modifiées avec succès.',
                                    ),
                                  ),
                                );
                              }
                            } else {
                              setModalState(
                                () => erreurModal =
                                    data['message'] ?? 'Erreur inconnue.',
                              );
                            }
                          }
                        } catch (e) {
                          setModalState(
                            () => erreurModal = 'Erreur réseau. Réessayez.',
                          );
                        }
                      },
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );

    telephoneCtrl.dispose();
  }

  Future<void> _supprimerNumero(String telephone) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Config.colors.authCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer ce numéro ?',
          style: TextStyle(
            color: Config.colors.authTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Le numéro $telephone sera supprimé de la liste des admins autorisés.',
          style: TextStyle(color: Config.colors.authTextSecondary),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: Config.colors.authTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmer != true) return;

    try {
      final response = await http.post(
        apiUri('supprimerNumeroAdmin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telephone': telephone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _recupererListeAdmins();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Numéro supprimé avec succès.'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Erreur lors de la suppression.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.authBackground,
      appBar: AppBar(
        backgroundColor: c.authCardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: c.authTextPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gestion des Admins',
          style: TextStyle(
            color: c.authTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: sw * 0.045,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: sw * 0.06,
          vertical: sh * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajouter un numéro',
              style: TextStyle(
                color: c.authTextPrimary,
                fontSize: sw * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sh * 0.02),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: c.authCardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1.5),
                    ),
                    child: TextFormField(
                      controller: _telephoneController,
                      maxLength: 10,
                      keyboardType: TextInputType.phone,
                      cursorColor: c.authAccent,
                      style: TextStyle(
                        color: c.authTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'Ex: 0505050505',
                        hintStyle: TextStyle(color: c.authTextSecondary),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: c.authAccent,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Veuillez entrer un numéro';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                          return 'Numéro invalide (10 chiffres)';
                        }
                        return null;
                      },
                    ),
                  ),

                  SizedBox(height: sh * 0.015),

                  Container(
                    decoration: BoxDecoration(
                      color: c.authCardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1.5),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _roleSelectionne,
                      dropdownColor: c.authCardBackground,
                      iconEnabledColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                          value: 'superadmin',
                          child: Text('Super Admin'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _roleSelectionne = value!),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Rôle',
                        labelStyle: TextStyle(color: c.authTextSecondary),
                        prefixIcon: Icon(
                          Icons.admin_panel_settings_outlined,
                          color: c.authAccent,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: sh * 0.015),

                  Container(
                    decoration: BoxDecoration(
                      color: c.authCardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.authBorder, width: 1.5),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _gareSelectionnee,
                      dropdownColor: c.authCardBackground,
                      iconEnabledColor: c.authAccent,
                      style: TextStyle(color: c.authTextPrimary),
                      items: _listeGares.map((gare) {
                        return DropdownMenuItem<String>(
                          value: gare,
                          child: Text(
                            gare,
                            style: TextStyle(color: c.authTextPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _gareSelectionnee = value),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Gare',
                        labelStyle: TextStyle(color: c.authTextSecondary),
                        prefixIcon: Icon(
                          Icons.location_city_outlined,
                          color: c.authAccent,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: sh * 0.015),

                  if (_erreur != null)
                    Text(
                      _erreur!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  if (_succes != null)
                    Text(
                      _succes!,
                      style: const TextStyle(color: Colors.green, fontSize: 13),
                    ),

                  SizedBox(height: sh * 0.015),

                  SizedBox(
                    width: double.infinity,
                    height: sh * 0.058,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _ajouterNumero,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.authButton,
                        foregroundColor: c.authTextPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: c.authTextPrimary,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Ajouter',
                              style: TextStyle(
                                fontSize: sw * 0.038,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sh * 0.04),

            Text(
              'Liste des admins autorisés',
              style: TextStyle(
                color: c.authTextPrimary,
                fontSize: sw * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: sh * 0.02),

            _isLoadingListe
                ? Center(child: CircularProgressIndicator(color: c.authAccent))
                : _listeAdmins.isEmpty
                ? Center(
                    child: Text(
                      'Aucun admin enregistré.',
                      style: TextStyle(color: c.authTextSecondary),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _listeAdmins.length,
                    itemBuilder: (context, index) {
                      final admin = _listeAdmins[index];
                      final bool compteExiste =
                          admin['nom'] != null &&
                          admin['nom'].toString().isNotEmpty;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: c.authCardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.authBorder, width: 1),
                        ),
                        child: ListTile(
                          leading: Icon(
                            compteExiste ? Icons.person : Icons.person_outline,
                            color: compteExiste ? Colors.green : c.authAccent,
                          ),
                          title: Text(
                            admin['telephone'] ?? '',
                            style: TextStyle(
                              color: c.authTextPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${admin['gare'] ?? ''} · ${admin['role'] ?? 'admin'}',
                                style: TextStyle(
                                  color: c.authAccent,
                                  fontSize: 12,
                                ),
                              ),
                              if (compteExiste)
                                Text(
                                  '${admin['nom'] ?? ''} ${admin['prenoms'] ?? ''}',
                                  style: TextStyle(
                                    color: c.authTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              Text(
                                compteExiste
                                    ? 'Compte créé'
                                    : 'En attente de création',
                                style: TextStyle(
                                  color: compteExiste
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bouton modifier visible uniquement si compte pas encore créé
                              if (!compteExiste)
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: c.authAccent,
                                  ),
                                  onPressed: () => _modifierNumero(admin),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _supprimerNumero(admin['telephone'] ?? ''),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            SizedBox(height: sh * 0.04),
          ],
        ),
      ),
    );
  }
}

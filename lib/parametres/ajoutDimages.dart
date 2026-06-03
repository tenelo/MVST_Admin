import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/models/models.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

const String _baseUrl = 'https://mvst.tenelo.cloud';

// ── ListeImages ───────────────────────────────────────────────────────────────
class ListeImages extends StatefulWidget {
  @override
  _ListeImagesState createState() => _ListeImagesState();
}

class _ListeImagesState extends State<ListeImages> {
  bool isLoading = false;
  List<ImageModel> images = [];
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _recupImages();
    _connecterSocket();
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  void _connecterSocket() {
    _socket = IO.io(
      'https://mvst.tenelo.cloud',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket.connect();
  }

  void _notifierClients() {
    if (_socket.connected) {
      _socket.emit('images_modifiees');
    } else {
      _socket.off('connect');
      _socket.onConnect((_) => _socket.emit('images_modifiees'));
    }
  }

  Future<void> _recupImages() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/gestionImages.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            images = List<ImageModel>.from(
              data['images'].map((i) => ImageModel.fromJson(i)),
            );
          });
        }
      }
    } catch (e) {
    } finally {
      setState(() => isLoading = false);
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
          'Gestion des images',
          style: TextStyle(
            color: c.authTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: sw * 0.045,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: c.authAccent))
          : images.isEmpty
          ? Center(
              child: Text(
                'Aucune image disponible',
                style: TextStyle(
                  color: c.authTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.06,
                vertical: sh * 0.02,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) =>
                  _buildImageCard(images[index], c),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.authButton,
        foregroundColor: c.authTextPrimary,
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AjouterImages()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildImageCard(ImageModel image, dynamic c) {
    final String lienImage = '$_baseUrl/${image.lien_image}';
    final bool isActif = image.statut.toLowerCase() == 'actif';

    return GestureDetector(
      onTap: () =>
          _afficherImageEnGrand(lienImage, image.titre, image.description),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.authBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image en haut ─────────────────────────────────────────
            if (image.lien_image.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: ColorFiltered(
                      colorFilter: isActif
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            )
                          : const ColorFilter.matrix([
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ]),
                      child: Image.network(
                        lienImage,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 160,
                          color: c.authCardBackground,
                          child: Icon(
                            Icons.error_outline_outlined,
                            color: c.authAccent,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Badge statut
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActif
                            ? const Color.fromARGB(255, 35, 177, 127)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActif ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActif ? 'Actif' : 'Inactif',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              // Pas d'image : icône centrée
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: isActif
                      ? c.authAccent.withValues(alpha: 0.07)
                      : Colors.grey.withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: c.authBorder, width: 1),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.campaign_rounded,
                        color: isActif ? c.authAccent : Colors.grey,
                        size: 48,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActif
                              ? const Color.fromARGB(255, 35, 177, 127)
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActif ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActif ? 'Actif' : 'Inactif',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Textes et boutons en dessous ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          image.titre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isActif ? c.authCardBackground : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          image.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isActif
                                ? c.authCardBackground.withValues(alpha: 0.8)
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Boutons
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: c.authAccent),
                        onPressed: () => _showEditDialog(image),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(image),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildImageCard(ImageModel image, dynamic c) {
  //   final String lienImage = '$_baseUrl/${image.lien_image}';
  //   final bool isActif = image.statut.toLowerCase() == 'actif';

  //   return GestureDetector(
  //     onTap: () =>
  //         _afficherImageEnGrand(lienImage, image.titre, image.description),
  //     child: Container(
  //       margin: const EdgeInsets.only(bottom: 10),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(12),
  //         border: Border.all(color: c.authBorder, width: 1),
  //       ),
  //       child: Stack(
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Padding(
  //                 padding: const EdgeInsets.all(8.0),
  //                 child: Container(
  //                   width: 110,
  //                   height: 100,
  //                   decoration: BoxDecoration(
  //                     color: isActif
  //                         ? c.authAccent.withValues(alpha: 0.07)
  //                         : Colors.grey.withValues(alpha: 0.07),
  //                     border: Border.all(
  //                       color: isActif ? c.authAccent : Colors.grey,
  //                       width: 1.0,
  //                     ),
  //                     borderRadius: BorderRadius.circular(8.0),
  //                   ),
  //                   child: image.lien_image.isNotEmpty
  //                       ? ClipRRect(
  //                           borderRadius: BorderRadius.circular(8.0),
  //                           child: ColorFiltered(
  //                             colorFilter: isActif
  //                                 ? const ColorFilter.mode(
  //                                     Colors.transparent,
  //                                     BlendMode.multiply,
  //                                   )
  //                                 : const ColorFilter.matrix([
  //                                     0.2126,
  //                                     0.7152,
  //                                     0.0722,
  //                                     0,
  //                                     0,
  //                                     0.2126,
  //                                     0.7152,
  //                                     0.0722,
  //                                     0,
  //                                     0,
  //                                     0.2126,
  //                                     0.7152,
  //                                     0.0722,
  //                                     0,
  //                                     0,
  //                                     0,
  //                                     0,
  //                                     0,
  //                                     1,
  //                                     0,
  //                                   ]),
  //                             child: Image.network(
  //                               lienImage,
  //                               width: 110,
  //                               height: 100,
  //                               fit: BoxFit.cover,
  //                               errorBuilder: (context, error, stackTrace) =>
  //                                   Icon(
  //                                     Icons.error_outline_outlined,
  //                                     color: c.authAccent,
  //                                     size: 40,
  //                                   ),
  //                             ),
  //                           ),
  //                         )
  //                       : Icon(
  //                           Icons.campaign_rounded,
  //                           color: isActif ? c.authAccent : Colors.grey,
  //                           size: 36,
  //                         ),
  //                 ),
  //               ),
  //               Expanded(
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(8.0),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         image.titre,
  //                         style: TextStyle(
  //                           fontWeight: FontWeight.bold,
  //                           color: isActif ? c.authCardBackground : Colors.grey,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         image.description,
  //                         maxLines: 10,
  //                         overflow: TextOverflow.ellipsis,
  //                         style: TextStyle(
  //                           color: isActif
  //                               ? c.authCardBackground.withValues(alpha: 0.9)
  //                               : Colors.grey[500],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               _buildActionButtons(image, c),
  //             ],
  //           ),
  //           // ── Badge statut ─────────────────────────────────────────────
  //           Positioned(
  //             top: 6,
  //             left: 6,
  //             child: Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
  //               decoration: BoxDecoration(
  //                 color: isActif
  //                     ? const Color.fromARGB(255, 35, 177, 127)
  //                     : Colors.grey,
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Icon(
  //                     isActif ? Icons.visibility : Icons.visibility_off,
  //                     color: Colors.white,
  //                     size: 11,
  //                   ),
  //                   const SizedBox(width: 3),
  //                   Text(
  //                     isActif ? 'Actif' : 'Inactif',
  //                     style: const TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 10,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Future<void> _afficherImageEnGrand(
    String imageUrl,
    String titre,
    String description,
  ) async {
    final c = Config.colors;
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: c.authCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, s) => Icon(
                    Icons.error_outline_outlined,
                    color: c.authAccent,
                    size: 50,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                titre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: c.authTextPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                description,
                textAlign: TextAlign.justify,
                style: TextStyle(color: c.authTextSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Ok',
                style: TextStyle(
                  color: c.authAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ImageModel image, dynamic c) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: c.authAccent),
          onPressed: () => _showEditDialog(image),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteDialog(image),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(ImageModel image) async {
    final c = Config.colors;
    final titreController = TextEditingController(text: image.titre);
    final descriptionController = TextEditingController(
      text: image.description,
    );
    final List<String> statuts = ['Actif', 'Inactif'];
    String statutSelectionne =
        image.statut[0].toUpperCase() + image.statut.substring(1);
    bool isUpdating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.authCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Modifier les informations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.authTextPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _dialogField(controller: titreController, hint: 'Titre', c: c),
              const SizedBox(height: 10),
              _dialogField(
                controller: descriptionController,
                hint: 'Description',
                c: c,
                maxLines: 5,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: c.authCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.authBorder, width: 1.5),
                ),
                child: DropdownButtonFormField<String>(
                  value: statutSelectionne,
                  dropdownColor: c.authCardBackground,
                  iconEnabledColor: c.authAccent,
                  style: TextStyle(color: c.authTextPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    hintStyle: TextStyle(color: c.authTextSecondary),
                  ),
                  items: statuts
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModal(() => statutSelectionne = val);
                  },
                ),
              ),
              if (isUpdating)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: CircularProgressIndicator(color: c.authAccent),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.authTextSecondary,
                        side: BorderSide(color: c.authBorder),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isUpdating
                          ? null
                          : () async {
                              setModal(() => isUpdating = true);
                              await _modifierImage(
                                image.id,
                                titreController.text,
                                descriptionController.text,
                                statutSelectionne,
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop();
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
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String hint,
    required dynamic c,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.authCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.authBorder, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        cursorColor: c.authAccent,
        style: TextStyle(color: c.authTextPrimary),
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintText: hint,
          hintStyle: TextStyle(color: c.authTextSecondary),
        ),
      ),
    );
  }

  Future<void> _modifierImage(
    int id,
    String titre,
    String description,
    String statut,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/gestionImages.php'),
        body: {
          'action': 'modifier',
          'id': id.toString(),
          'titre': titre,
          'description': description,
          'statut': statut,
        },
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) _notifierClients();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: data['success'] == true
              ? Config.colors.authCardBackground
              : Colors.red,
          content: Text(
            data['message'],
            style: TextStyle(color: Config.colors.authTextPrimary),
          ),
        ),
      );
      _recupImages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la modification')),
      );
    }
  }

  Future<void> _showDeleteDialog(ImageModel image) async {
    final c = Config.colors;
    bool isDeleting = false;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: c.authCardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              'Suppression',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voulez-vous vraiment supprimer cette image ?',
                style: TextStyle(color: c.authTextSecondary),
              ),
              if (isDeleting)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(color: c.authAccent),
                ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    setState(() => isDeleting = true);
                    await _supprimerImage(image.id);
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    'Oui',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Non',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: c.authTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _supprimerImage(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/gestionImages.php'),
        body: {'action': 'supprimer', 'id': id.toString()},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) _notifierClients();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: data['success'] == true
              ? Config.colors.authCardBackground
              : Colors.red,
          content: Text(
            data['message'],
            style: TextStyle(color: Config.colors.authTextPrimary),
          ),
        ),
      );
      _recupImages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression')),
      );
    }
  }
}

// ── AjouterImages ─────────────────────────────────────────────────────────────
class AjouterImages extends StatefulWidget {
  const AjouterImages({Key? key}) : super(key: key);
  @override
  _AjouterImagesState createState() => _AjouterImagesState();
}

class _AjouterImagesState extends State<AjouterImages> {
  final TextEditingController titreImage = TextEditingController();
  final TextEditingController detailsImage = TextEditingController();
  String? selectedOption;
  final List<String> options = ['Actif', 'Inactif'];
  File? _image;
  bool isLoading = false;
  bool _avecImage = true;
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _socket = IO.io(
      'https://mvst.tenelo.cloud',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket.connect();
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          "Gestion d'images",
          style: TextStyle(
            color: c.authTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: sw * 0.045,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.06, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Switch type ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: c.authCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.authBorder, width: 1.5),
                ),
                child: Row(
                  children: [
                    Text(
                      'Type :',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: c.authTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Avec image'),
                            selected: _avecImage,
                            selectedColor: c.authButton,
                            labelStyle: TextStyle(
                              color: _avecImage
                                  ? c.authTextPrimary
                                  : c.authTextSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setState(() {
                              _avecImage = true;
                              _image = null;
                            }),
                          ),
                          ChoiceChip(
                            label: const Text('Information seule'),
                            selected: !_avecImage,
                            selectedColor: c.authButton,
                            labelStyle: TextStyle(
                              color: !_avecImage
                                  ? c.authTextPrimary
                                  : c.authTextSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setState(() {
                              _avecImage = false;
                              _image = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Sélection image ──────────────────────────────────────────
              if (_avecImage) ...[
                GestureDetector(
                  onTap: _image == null ? _selectImage : null,
                  child: _buildImagePreview(c),
                ),
                const SizedBox(height: 8),
              ],

              _buildTextField(
                titreImage,
                _avecImage ? "Titre de l'image" : "Titre de l'information",
                c,
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                label: 'Sélectionner statut',
                items: options,
                selectedItem: selectedOption,
                c: c,
                onChanged: (value) => setState(() => selectedOption = value),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez choisir le statut'
                    : null,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                detailsImage,
                _avecImage ? "Détails de l'image" : "Contenu de l'information",
                c,
                maxLines: 10,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : _uploadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.authButton,
                  foregroundColor: c.authTextPrimary,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(dynamic c) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.authBorder, width: 1.5),
        color: c.authCardBackground,
      ),
      child: _image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _image!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 50,
                  color: c.authAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sélectionner une image',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.authTextSecondary,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    dynamic c, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.authCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.authBorder, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        cursorColor: c.authAccent,
        style: TextStyle(color: c.authTextPrimary),
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintText: label,
          hintStyle: TextStyle(color: c.authTextSecondary),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedItem,
    required dynamic c,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.authCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.authBorder, width: 1.5),
      ),
      child: DropdownButtonFormField<T>(
        value: selectedItem,
        dropdownColor: c.authCardBackground,
        iconEnabledColor: c.authAccent,
        // couleur du texte dans le dropdown
        style: TextStyle(color: c.authTextPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          hintText: label,
          hintStyle: TextStyle(color: c.authTextPrimary),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Future<void> _uploadData() async {
    final c = Config.colors;
    if (titreImage.text.isEmpty ||
        detailsImage.text.isEmpty ||
        selectedOption == null ||
        (_avecImage && _image == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: c.authCardBackground,
          content: Text(
            _avecImage && _image == null
                ? 'Veuillez sélectionner une image'
                : 'Veuillez remplir tous les champs',
            style: TextStyle(color: c.authTextPrimary),
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/gestionImages.php'),
      );
      if (_avecImage && _image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('lien_image', _image!.path),
        );
      }
      request.fields['action'] = 'ajouter';
      request.fields['titre'] = titreImage.text;
      request.fields['description'] = detailsImage.text;
      request.fields['statut'] = selectedOption!;
      if (!_avecImage) request.fields['sans_image'] = '1';

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (data['success'] == true) {
        if (_socket.connected) {
          _socket.emit('images_modifiees');
        } else {
          _socket.onConnect((_) => _socket.emit('images_modifiees'));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color.fromARGB(255, 35, 177, 127),
              content: Text(
                data['message'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 800));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ListeImages()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                data['message'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }
}

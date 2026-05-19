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
  late IO.Socket _socket; // ← AJOUTÉ

  @override
  void initState() {
    super.initState();
    _recupImages();
    _connecterSocket(); // ← AJOUTÉ
  }

  @override
  void dispose() {
    _socket.disconnect(); // ← AJOUTÉ
    _socket.dispose(); // ← AJOUTÉ
    super.dispose();
  }

  // ── Socket.IO ─────────────────────────────────────────────────────────────

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(93, 12, 134, 195),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Gestion des images',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(93, 12, 134, 195),
              ),
            )
          : images.isEmpty
          ? const Center(
              child: Text(
                'Aucune image disponible',
                style: TextStyle(
                  color: Color.fromARGB(93, 12, 134, 195),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ListView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) => _buildImageCard(images[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AjouterImages()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildImageCard(ImageModel image) {
    final String lienImage = '$_baseUrl/${image.lien_image}';
    final bool isActif = image.statut.toLowerCase() == 'actif';

    return GestureDetector(
      onTap: () =>
          _afficherImageEnGrand(lienImage, image.titre, image.description),
      child: Card(
        shadowColor: isActif ? Colors.lightBlueAccent : Colors.grey,
        elevation: 4,
        child: Stack(
          children: [
            // ── Contenu principal ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    width: 120,
                    height: 110,
                    decoration: BoxDecoration(
                      color: isActif
                          ? Colors.blue.withValues(alpha: 0.07)
                          : Colors.grey.withValues(alpha: 0.07),
                      border: Border.all(
                        color: isActif ? Colors.blue : Colors.grey,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: image.lien_image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: ColorFiltered(
                              colorFilter: isActif
                                  ? const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.multiply,
                                    )
                                  : const ColorFilter.matrix([
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0, 0, 0, 1, 0,
                                    ]),
                              child: Image.network(
                                lienImage,
                                width: 120,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.error_outline_outlined,
                                      color: Colors.blue,
                                      size: 50,
                                    ),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.campaign_rounded,
                            color: isActif ? Colors.blue : Colors.grey,
                            size: 40,
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          image.titre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isActif ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          image.description,
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActif ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(image),
              ],
            ),
            // ── Badge statut ───────────────────────────────────────────
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isActif ? 'Actif' : 'Inactif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
    );
  }

  Future<void> _afficherImageEnGrand(
    String imageUrl,
    String titre,
    String description,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
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
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.error_outline_outlined,
                    color: Colors.blue,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(description, textAlign: TextAlign.justify),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Ok',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ImageModel image) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _showEditDialog(image),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete,
            color: Color.fromARGB(255, 233, 75, 64),
          ),
          onPressed: () => _showDeleteDialog(image),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(ImageModel image) async {
    final titreController = TextEditingController(text: image.titre);
    final descriptionController = TextEditingController(
      text: image.description,
    );
    final List<String> statuts = ['Actif', 'Inactif'];
    String statutSelectionne =
        image.statut[0].toUpperCase() + image.statut.substring(1);
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Center(
            child: Text(
              'Modifier les informations',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titreController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                TextField(
                  maxLines: 5,
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: statutSelectionne,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: statuts
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => statutSelectionne = val);
                  },
                ),
                if (isUpdating)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() => isUpdating = true);
                    await _modifierImage(
                      image.id,
                      titreController.text,
                      descriptionController.text,
                      statutSelectionne,
                    );
                    setState(() => isUpdating = false);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
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
      if (data['success'] == true) _notifierClients(); // ← AJOUTÉ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: data['success'] == true
              ? const Color.fromARGB(255, 35, 113, 177)
              : Colors.red,
          content: Text(
            data['message'],
            style: const TextStyle(color: Colors.white),
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
    bool isDeleting = false;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Center(
            child: Text(
              'Suppression',
              style: TextStyle(
                color: Color.fromARGB(255, 233, 75, 64),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Voulez-vous vraiment supprimer cette image ?'),
              if (isDeleting)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
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
                      color: Color.fromARGB(255, 233, 75, 64),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Non',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
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
      if (data['success'] == true) _notifierClients(); // ← AJOUTÉ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: data['success'] == true
              ? const Color.fromARGB(255, 35, 113, 177)
              : Colors.red,
          content: Text(
            data['message'],
            style: const TextStyle(color: Colors.white),
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
    // ── Socket.IO ────────────────────────────────────────────────────
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
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion d\'images'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Switch type ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Type :',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Avec image'),
                            selected: _avecImage,
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                              color: _avecImage ? Colors.white : Colors.blue,
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
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                              color: !_avecImage ? Colors.white : Colors.blue,
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

              // ── Sélection image (uniquement si "Avec image") ────────────
              if (_avecImage) ...[
                GestureDetector(
                  onTap: _image == null ? _selectImage : null,
                  child: _buildImagePreview(),
                ),
                const SizedBox(height: 4),
              ],

              _buildTextField(titreImage, _avecImage ? "Titre de l'image" : "Titre de l'information"),
              const SizedBox(height: 4),
              _buildDropdown(
                label: 'Sélectionner statut',
                items: options,
                selectedItem: selectedOption,
                onChanged: (value) => setState(() => selectedOption = value),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez choisir le statut'
                    : null,
              ),
              const SizedBox(height: 4),
              _buildTextField(
                detailsImage,
                _avecImage ? "Détails de l'image" : "Contenu de l'information",
                maxLines: 10,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isLoading ? null : _uploadData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Ajouter',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: _image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
                  color: Config.colors.bleuA,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sélectionner une image',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Config.colors.bleuA,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedItem,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: selectedItem,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
      iconEnabledColor: Colors.blue,
      items: items
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(item.toString())),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Future<void> _uploadData() async {
    if (titreImage.text.isEmpty ||
        detailsImage.text.isEmpty ||
        selectedOption == null ||
        (_avecImage && _image == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color.fromARGB(255, 35, 113, 177),
          content: Text(
            _avecImage && _image == null
                ? "Veuillez sélectionner une image"
                : "Veuillez remplir tous les champs",
            style: const TextStyle(color: Colors.white),
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
              backgroundColor: const Color.fromARGB(255, 213, 115, 66),
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
            "Erreur : $e",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 213, 76, 66),
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

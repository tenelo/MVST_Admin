import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/models/models.dart';
import 'package:mysql1/mysql1.dart';

class ListeImages extends StatefulWidget {
  @override
  _ListeImagesState createState() => _ListeImagesState();
}

class _ListeImagesState extends State<ListeImages> {
  bool isLoading = false;
  List<ImageModel> images = [];
  MySqlConnection? conn;

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
    _fetchImages();
  }

  Future<void> _connectToDatabase() async {
    try {
      conn = await Connexion.connexionDB();
    } catch (e) {
      print('Erreur de connexion à la base de données: $e');
    }
  }

  Future<void> _fetchImages() async {
    setState(() {
      isLoading = true;
    });

    try {
      final results = await conn!.query('SELECT * FROM images');
      setState(() {
        images = results.map((row) => ImageModel.fromJson(row.fields)).toList();
      });
    } catch (e) {
      print('Erreur lors du chargement des images: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    conn?.close();
    super.dispose();
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
        title: Text(
          'Gestion des images',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                return _buildImageCard(image);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AjouterImages()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildImageCard(ImageModel image) {
    return Card(
      shadowColor: Colors.lightBlueAccent,
      elevation: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              image.url,
              width: 120,
              height: 110,
              fit: BoxFit.cover,
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    image.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          _buildActionButtons(image),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ImageModel image) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => _showEditDialog(image),
        ),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => _showDeleteDialog(image),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(ImageModel image) async {
    final TextEditingController titreController =
        TextEditingController(text: image.titre);
    final TextEditingController descriptionController =
        TextEditingController(text: image.description);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier l\'image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titreController,
              decoration: InputDecoration(labelText: 'Titre'),
            ),
            TextField(
              maxLines: 5,
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              setState(() => isLoading = true);
              await _modifierImageDansMySQL(
                  image.id, titreController.text, descriptionController.text);
              _fetchImages();
              Navigator.of(context).pop();
            },
            child: Text('Enregistrer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(ImageModel image) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer cette image ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Oui'),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      await _supprimerImageDeMySQL(image.id);
      _fetchImages();
    }
  }

  Future<void> _modifierImageDansMySQL(
      String id, String titre, String description) async {
    try {
      await conn!.query(
        'UPDATE images SET titre = ?, description = ? WHERE id = ?',
        [titre, description, id],
      );
      print('Image modifiée dans MySQL avec succès.');
    } catch (e) {
      print('Erreur lors de la modification dans MySQL: $e');
    }
  }

  Future<void> _supprimerImageDeMySQL(String id) async {
    try {
      await conn!.query('DELETE FROM images WHERE id = ?', [id]);
      print('Image supprimée de MySQL avec succès.');
    } catch (e) {
      print('Erreur lors de la suppression de MySQL: $e');
    }
  }
}

///////////////////////////////////////////

class AjouterImages extends StatefulWidget {
  const AjouterImages({Key? key}) : super(key: key);

  @override
  _AjouterImagesState createState() => _AjouterImagesState();
}

class _AjouterImagesState extends State<AjouterImages> {
  final TextEditingController titreImage = TextEditingController();
  final TextEditingController detailsImage = TextEditingController();
  File? _image;
  bool isLoading = false;
  MySqlConnection? conn; // Connexion à la base de données

  @override
  void initState() {
    super.initState();
    _connectToDatabase(); // Connexion à la base de données
  }

  Future<void> _connectToDatabase() async {
    try {
      conn = await Connexion.connexionDB();
    } catch (e) {
      print('Erreur de connexion à la base de données: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.bleuFonce2),
        centerTitle: true,
        title: Text(
          'Ajouter une Image',
          style: TextStyle(
            color: Config.colors.bleuFonce2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _image == null ? _selectImage : null,
                child: _buildImagePreview(),
              ),
              const SizedBox(height: 16),
              _buildTextField(titreImage, "Titre de l'image"),
              const SizedBox(height: 8),
              _buildTextField(detailsImage, "Détails de l'image", maxLines: 10),
              const SizedBox(height: 8),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
      persistentFooterButtons: [
        Text(
          "MVST",
          style:
              TextStyle(fontFamily: 'Lobster', color: Config.colors.bleuFonce2),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Config.colors.bleuFonce2),
      ),
      child: _image == null
          ? Center(child: Text('Sélectionner une image'))
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _image!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _saveImage,
      child: isLoading ? CircularProgressIndicator() : Text('Ajouter l\'image'),
    );
  }

  Future<void> _saveImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner une image.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Upload image and get the URL
      String imageUrl = await _uploadImage(_image!);
      await _ajouterImageDansMySQL(
          titreImage.text, detailsImage.text, imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image ajoutée avec succès.')),
      );
      Navigator.of(context).pop(); // Retourne à la page précédente
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de l\'image.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    String uploadUrl =
        'https://srv1582-files.hstgr.io/95223698796713ad/files/public_html/appmobile/mvst/uploads/upload.php';

    // Créer un multipart request
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

    // Ajouter le fichier à la requête
    var pic = await http.MultipartFile.fromPath('image', image.path);
    request.files.add(pic);

    // Envoyer la requête
    var response = await request.send();

    if (response.statusCode == 200) {
      // Si le téléchargement a réussi, obtenir l'URL de l'image
      String responseBody = await response.stream.bytesToString();
      // Assurez-vous que votre script PHP renvoie l'URL de l'image
      return responseBody; // ou parsez pour obtenir l'URL si nécessaire
    } else {
      throw Exception('Erreur lors du téléchargement: ${response.statusCode}');
    }
  }

  Future<void> _ajouterImageDansMySQL(
      String titre, String description, String url) async {
    try {
      await conn!.query(
        'INSERT INTO images (titre, description, url) VALUES (?, ?, ?)',
        [titre, description, url],
      );
      print('Image ajoutée dans MySQL avec succès.');
    } catch (e) {
      print('Erreur lors de l\'ajout dans MySQL: $e');
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    conn?.close(); // Assurez-vous de fermer la connexion
    super.dispose();
  }
}

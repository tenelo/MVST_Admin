import 'dart:convert';
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
  final String baseUrl = 'https://tenelodata-tech.com/mvst/';

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
    _recupImages();
  }

  Future<void> _connectToDatabase() async {
    conn = await Connexion.connexionDB();
  }

  Future<void> _recupImages() async {
    setState(() {
      isLoading = true;
    });

    try {
      conn ??= await Connexion.connexionDB();
      final results = await conn!.query('SELECT * FROM Images');
      setState(() {
        images = results.map((row) {
          return ImageModel.fromJson({
            'id': row['id'],
            'titre': row['titre'].toString(),
            'description': row['description'].toString(),
            'statut': row['statut'].toString(),
            'lien_image': row['lien_image'].toString(),
          });
        }).toList();
      });
    } catch (e) {
      conn = await Connexion.connexionDB();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
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
          ? Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(93, 12, 134, 195),
              ),
            )
          : images.isEmpty
              ? Center(
                  child: Text(
                    'Aucune image disponible',
                    style: TextStyle(
                        color: Color.fromARGB(93, 12, 134, 195),
                        fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final image = images[index];
                    return _buildImageCard(image);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AjouterImages()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildImageCard(ImageModel image) {
    final String _lienImage = baseUrl + image.lien_image;
    print("Construction de la carte pour l'image : $_lienImage");
    return Card(
      shadowColor: Colors.lightBlueAccent,
      elevation: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              _lienImage,
              width: 120,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print("Erreur lors du chargement de l'image : $error");
                return Icon(Icons.error_outline_outlined,
                    color: Colors.blue, size: 50);
              },
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
          icon: Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _showEditDialog(image),
        ),
        IconButton(
          icon: Icon(
            Icons.delete,
            color: const Color.fromARGB(255, 233, 75, 64),
          ),
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
    final TextEditingController statutController =
        TextEditingController(text: image.statut);

    final List<String> statuts = ['Actif', 'Inactif'];
    String statutSelectionne = image.statut;

    bool isUpdating = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(
              child: Text(
                'Modifier les informations',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
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
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  iconEnabledColor: Colors.blue,
                  value: statutController.text,
                  decoration: InputDecoration(labelText: 'Statut'),
                  items: statuts
                      .map((statut) => DropdownMenuItem(
                            value: statut,
                            child: Text(statut),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      statutSelectionne = val;
                      statutController.text = val;
                    }
                  },
                ),
                if (isUpdating)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      setState(() => isUpdating = true);
                      await _modifierImageDansMySQL(
                        image.id,
                        titreController.text,
                        descriptionController.text,
                        statutSelectionne,
                      );
                      setState(() => isUpdating = false);
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Enregistrer',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _modifierImageDansMySQL(
      int id, String titre, String description, String statut) async {
    try {
      conn ??= await Connexion.connexionDB();
      var result = await conn!.query(
        'UPDATE Images SET titre = ?, description = ?, statut = ? WHERE id = ?',
        [titre, description, statut, id],
      );

      if (result.affectedRows! > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 35, 113, 177),
            content: Text(
              'Informations modifiées avec succès.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aucune modification n\'a été effectuée.')),
        );
      }
      setState(() {
        _recupImages();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification de l\'image.')),
      );
    }
  }

  Future<void> _showDeleteDialog(ImageModel image) async {
    bool isDeleting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(
              child: Text(
                'Suppression',
                style: TextStyle(
                    color: const Color.fromARGB(255, 233, 75, 64),
                    fontWeight: FontWeight.bold),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                    child:
                        Text('Voulez-vous vraiment supprimer cette image ?')),
                if (isDeleting)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
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
                      await _supprimerImage(image);
                      Navigator.of(context).pop(true);
                    },
                    child: Text(
                      'Oui',
                      style: TextStyle(
                          color: const Color.fromARGB(255, 233, 75, 64),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Non',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _supprimerImage(ImageModel image) async {
    try {
      var url = Uri.parse('https://tenelodata-tech.com/mvst/upload.php');

      var response = await http.post(
        url,
        body: {
          'action': 'delete',
          'id': image.id.toString(),
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] != null) {
          // Image supprimée avec succès du serveur, maintenant supprimer dans la base de données
          var dbResponse = await conn!.query(
            'DELETE FROM Images WHERE id = ?',
            [image.id],
          );

          if (dbResponse.affectedRows! > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color.fromARGB(255, 35, 113, 177),
                content: Text(
                  "Image supprimée avec succès.",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: const Color.fromARGB(255, 46, 46, 46),
                content: Text(
                  'Erreur : L\'enregistrement n\'a pas pu être supprimé.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        } else if (jsonResponse['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: const Color.fromARGB(255, 46, 46, 46),
              content: Text(
                'Erreur lors de la suppression sur le serveur.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: const Color.fromARGB(255, 46, 46, 46),
            content: Text(
              'Erreur de connexion au serveur.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color.fromARGB(255, 46, 46, 46),
          content: Text(
            'Erreur lors de la suppression de l\'image',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() {
        _recupImages();
        isLoading = false;
      });
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
  String? selectedOption;
  final List<String> options = ['Actif', 'Inactif'];
  File? _image;
  bool isLoading = false;
  MySqlConnection? conn;

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
  }

  Future<void> _connectToDatabase() async {
    conn = await Connexion.connexionDB();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion d\'images'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _image == null ? _selectImage : null,
                child: _buildImagePreview(),
              ),
              const SizedBox(height: 4),
              _buildTextField(titreImage, "Titre de l'image"),
              const SizedBox(height: 4),
              _buildDropdown(
                label: 'Sélectionner statut',
                items: options,
                selectedItem: selectedOption,
                onChanged: (value) {
                  setState(() {
                    selectedOption = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez choisir le statut';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              _buildTextField(detailsImage, "Détails de l'image", maxLines: 10),
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
                            color: Colors.white, fontWeight: FontWeight.w700),
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
                  size: 50,
                  Icons.photo_library_outlined,
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

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
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
        labelStyle: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
      iconEnabledColor: Colors.blue,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child:
                  Text(item.toString(), style: TextStyle(color: Colors.black)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Future<void> _uploadData() async {
    if (titreImage.text.isEmpty ||
        detailsImage.text.isEmpty ||
        _image == null ||
        selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromARGB(255, 35, 113, 177),
          content: Text(
            "Veuillez remplir tous les champs,",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://tenelodata-tech.com/mvst/upload.php'),
      );

      // Ajouter l'image
      request.files.add(await http.MultipartFile.fromPath(
          'lien_image', _image!.path)); // Correction : suppression de l'espace

      // Ajouter les autres champs
      request.fields['titre'] = titreImage.text;
      request.fields['description'] = detailsImage.text;
      request.fields['statut'] = selectedOption!; // Ajout du champ statut

      // Envoyer la requête
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 35, 113, 177),
            content: Text(
              "Image ajoutée avec succès",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ListeImages(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 213, 76, 66),
            content: Text(
              "L'image n'a pas pu être ajoutée.",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 213, 76, 66),
          content: Text(
            "Erreur : $e",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

/*
  Future<void> _uploadData() async {
    if (titreImage.text.isEmpty ||
        detailsImage.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromARGB(255, 35, 113, 177),
          content: Text(
            "Veuillez remplir tous les champs et ajouter une image",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }
    // Assure-toi que la variable est vérifiée avant utilisation.
    if (_image == null) {
      return;
    }
    setState(() {
      isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://tenelodata-tech.com/mvst/upload.php'),
      );

      // Ajouter l'image
      request.files
          .add(await http.MultipartFile.fromPath('lienImage', _image!.path));

      // Ajouter les autres champs
      request.fields['titre'] = titreImage.text;
      request.fields['description'] = detailsImage.text;

      // Envoyer la requête
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 35, 113, 177),
            content: Text(
              "Image ajoutée avec succès",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ListeImages(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 213, 76, 66),
            content: Text(
              "L'Image n'a pu être ajoutée",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
*/
  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /*
  Future<void> _selectImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          print("IMAGE SELECTIONNEE $pickedFile");
          _image = File(pickedFile.path);
        });
      } else {
        print("Aucune image sélectionnée.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Aucune image sélectionnée"),
          ),
        );
      }
    } catch (e) {
      print("Erreur lors de la sélection de l'image : $e");
    }
  }
*/
  @override
  void dispose() {
    super.dispose();
  }
}

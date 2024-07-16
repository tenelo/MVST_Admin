import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/models/models.dart';

class ListeImages extends StatefulWidget {
  @override
  _ListeImagesState createState() => _ListeImagesState();
}

class _ListeImagesState extends State<ListeImages> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.bleuFonce2),
        centerTitle: true,
        title: Text(
          'Gestion des images',
          style: TextStyle(
              color: Config.colors.bleuFonce2, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('images')
            .orderBy('dateCreation', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final List<ImageModel> images = snapshot.data!.docs
              .map((doc) => ImageModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return Card(
                shadowColor: Colors.lightBlueAccent,
                elevation: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Card(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          image.url,
                          width: 120,
                          height: 110,
                          fit: BoxFit.cover,
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
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                image.description),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            TextEditingController titreController =
                                TextEditingController(text: image.titre);
                            TextEditingController descriptionController =
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
                                      decoration:
                                          InputDecoration(labelText: 'Titre'),
                                    ),
                                    TextField(
                                      maxLines: 5,
                                      controller: descriptionController,
                                      decoration: InputDecoration(
                                          labelText: 'Description'),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      setState(() {
                                        isLoading = true;
                                      });

                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('images')
                                            .doc(image.id)
                                            .update({
                                          'titre': titreController.text,
                                          'description':
                                              descriptionController.text,
                                        });
                                      } catch (e) {
                                        print('Error updating image: $e');
                                      } finally {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: Text('Enregistrer'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Annuler'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            bool confirmDelete = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Confirmation'),
                                content: Text(
                                    'Voulez-vous vraiment supprimer cette image ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: Text('Non'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: Text('Oui'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmDelete) {
                              try {
                                // Suppression de l'image de Firestore
                                await FirebaseFirestore.instance
                                    .collection('images')
                                    .doc(image.id)
                                    .delete();
                                // Suppression de l'image du stockage Firebase
                                await FirebaseStorage.instance
                                    .refFromURL(image.url)
                                    .delete();
                              } catch (e) {
                                print('Error deleting image: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Erreur lors de la suppression de l\'image.'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AjouterImages()),
          ).then((_) {
            setState(() {});
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AjouterImages extends StatefulWidget {
  const AjouterImages({Key? key}) : super(key: key);

  @override
  _AjouterImagesState createState() => _AjouterImagesState();
}

class _AjouterImagesState extends State<AjouterImages> {
  final TextEditingController titreImage = TextEditingController();
  final TextEditingController detailsImage = TextEditingController();
  final Reference _storage = FirebaseStorage.instance.ref('images');
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.bleuFonce2),
        centerTitle: true,
        title: Text(
          'Ajouter une Image',
          style: TextStyle(
              color: Config.colors.bleuFonce2, fontWeight: FontWeight.bold),
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
                onTap: _image == null
                    ? () async {
                        final XFile? image = await _imagePicker.pickImage(
                            source: ImageSource.gallery);
                        setState(() {
                          _image = image != null
                              ? File(
                                  image.path,
                                )
                              : null;
                        });
                      }
                    : null,
                child: _image != null
                    ? Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                            border:
                                Border.all(color: Config.colors.bleuFonce2)),
                        child: kIsWeb
                            ? Image.network(_image!.path)
                            : Image.file(
                                _image!,
                                fit: BoxFit.cover,
                              ),
                      )
                    : Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                            border:
                                Border.all(color: Config.colors.bleuFonce2)),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.perm_media_outlined,
                                size: 70,
                                color: Config.colors.bleuFonce2,
                              ),
                              Text(
                                'Sélectionner une image',
                                style: TextStyle(
                                    color: Config.colors.bleuFonce2,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                      ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Config.colors.bleuFonce2),
                    color: Colors.white54,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: TextField(
                  controller: titreImage,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Titre de l'image",
                    labelStyle: TextStyle(
                        color: Config.colors.bleuFonce2,
                        fontWeight: FontWeight.bold),
                    fillColor: Config.colors.bleuFonce2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Config.colors.bleuFonce2),
                    color: Colors.white54,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: TextField(
                  maxLines: 10,
                  controller: detailsImage,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  decoration: InputDecoration(
                    fillColor: Colors.white38,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black)),
                    labelText: "Détails de l'image",
                    labelStyle: TextStyle(
                        color: Config.colors.bleuFonce2,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading || _image == null
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });
                          final _titreImage = titreImage.text.trim();
                          final _detailsImage = detailsImage.text.trim();
                          final _nonImage = _image!.path.split('/').last;

                          // Créer une nouvelle référence dans le stockage Firebase
                          final newImageRef = _storage.child(_nonImage);

                          try {
                            // Télécharger l'image sélectionnée avec des métadonnées personnalisées
                            await newImageRef.putFile(
                                _image!,
                                SettableMetadata(customMetadata: {
                                  "titre": _titreImage,
                                  "description": _detailsImage
                                }));

                            // Obtenir l'URL de l'image
                            String imageUrl =
                                await newImageRef.getDownloadURL();

                            // Enregistrer les informations de l'image dans Firestore
                            await FirebaseFirestore.instance
                                .collection('images')
                                .add({
                              'url': imageUrl,
                              'titre': _titreImage,
                              'description': _detailsImage,
                              'dateCreation': FieldValue.serverTimestamp(),
                            });

                            Navigator.pop(
                                context); // Retour à la page précédente
                          } on FirebaseException catch (error) {
                            print(error);
                          } finally {
                            setState(() {
                              isLoading = false;
                              _image = null;
                              titreImage.clear();
                              detailsImage.clear();
                            });

                            ScaffoldMessenger.of(context)
                              ..removeCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                backgroundColor: Config.colors.bleuFonce2,
                                content: Text(
                                  'Ajouté avec succès',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                duration: Duration(seconds: 3),
                              ));
                          }
                        },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
      persistentFooterButtons: [
        Text(
          "MVST",
          style:
              TextStyle(fontFamily: 'Lobster', color: Config.colors.bleuFonce2),
        )
      ],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';

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
  final CollectionReference informations =
      FirebaseFirestore.instance.collection('infosGares');

  final _formKey = GlobalKey<FormState>();

  void _showBottomSheet({DocumentSnapshot? document}) {
    if (document != null) {
      villeController.text = document['ville'];
      descriptionController.text = document['description'];
      telephoneController.text = document['telephone'];
      confirmTelephoneController.text = document['telephone'];
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
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                    ),
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
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                    ),
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
                    labelText: 'Telephone',
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                    ),
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
                    labelText: 'Confirmer Telephone',
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                    ),
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
                      if (document == null) {
                        await informations.add({
                          'ville': villeController.text,
                          'description': descriptionController.text,
                          'telephone': telephoneController.text,
                        });
                      } else {
                        await informations.doc(document.id).update({
                          'ville': villeController.text,
                          'description': descriptionController.text,
                          'telephone': telephoneController.text,
                        });
                      }
                      Navigator.pop(
                          context); // Ferme la bottom sheet après l'opération
                    }
                  },
                  child: Text(document == null ? 'Ajouter' : 'Modifier'),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteItem(String id) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Êtes-vous sûr de vouloir supprimer cet élément?'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () async {
                await informations.doc(id).delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Config.colors.bleuFonce2,
        ),
        centerTitle: true,
        title: Text(
          'Informations sur les gares',
          style: TextStyle(
            color: Config.colors.bleuFonce,
            fontFamily: 'Lobster',
          ),
        ),
      ),
      body: StreamBuilder(
        stream: informations.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(
              'Aucune donnée',
              style: TextStyle(
                color: Config.colors.bleuFonce2,
                fontFamily: 'Lobster',
              ),
            ));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var document = snapshot.data!.docs[index];
              return ListTile(
                title: Text(document['ville']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document['description']),
                    Text('Téléphone: ${document['telephone']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showBottomSheet(document: document),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteItem(document.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBottomSheet(),
        child: Icon(Icons.add),
      ),
    );
  }
}

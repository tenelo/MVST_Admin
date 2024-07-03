import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';

class HeureDepart extends StatefulWidget {
  const HeureDepart({Key? key}) : super(key: key);

  @override
  _HeureDepartState createState() => _HeureDepartState();
}

class _HeureDepartState extends State<HeureDepart> {
  TimeOfDay? selectedTime;
  final TextEditingController _timeController = TextEditingController();
  bool _isSaving = false; // Ajout d'une nouvelle variable d'état

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Heures de Départs',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(93, 12, 134, 195),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.access_time),
                  labelText: 'Heure de départ (HH:mm)',
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez choisir une heure de départ';
                  }
                  return null;
                },
                onTap: () async {
                  selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selectedTime != null) {
                    _timeController.text = selectedTime!.format(context);
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isSaving = true;
                          });

                          _addHeureDeDepart(selectedTime!).then((_) {
                            setState(() {
                              _isSaving = false;
                            });
                          });
                        }
                      },
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ajouter'),
                style: ElevatedButton.styleFrom(),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('heuresDeDeparts')
                      .orderBy('dateCreation', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erreur: ${snapshot.error}'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final documents = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final heure = documents[index]['heure'] as String;
                        final docId = documents[index].id;
                        return ListTile(
                          title: Text(heure),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editHeureDeDepart(docId, heure);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteHeureDeDepart(docId);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addHeureDeDepart(TimeOfDay time) async {
    setState(() {
      _isSaving = true; // Commencer l'enregistrement
    });

    String formattedTime =
        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    await FirebaseFirestore.instance.collection('heuresDeDeparts').add({
      'heure': formattedTime,
      'dateCreation': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        _isSaving = false;
        _timeController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Config.colors.bleuFonce2,
          content: Text('Heure de départ ajoutée : $formattedTime'),
        ),
      );
    }
  }

  Future<void> _editHeureDeDepart(String docId, String heure) async {
    selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.parse(heure.split(':')[0]),
          minute: int.parse(heure.split(':')[1])),
    );
    if (selectedTime != null) {
      String formattedTime =
          '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}';
      await FirebaseFirestore.instance
          .collection('heuresDeDeparts')
          .doc(docId)
          .update({'heure': formattedTime});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Config.colors.bleuFonce2,
          content: Text('Heure de départ modifiée : $formattedTime'),
        ),
      );
    }
  }

  Future<void> _deleteHeureDeDepart(String docId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text(
              'Voulez-vous vraiment supprimer cette heure de départ ?'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Ferme la boîte de dialogue
                  },
                  child: const Text('Non'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Ferme la boîte de dialogue
                    await FirebaseFirestore.instance
                        .collection('heuresDeDeparts')
                        .doc(docId)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Config.colors.bleuFonce2,
                        content: const Text('Heure de départ supprimée'),
                      ),
                    );
                  },
                  child: const Text('Oui'),
                ),
              ],
            )
          ],
        );
      },
    );
  }
}

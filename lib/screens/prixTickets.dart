import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PrixTickets extends StatefulWidget {
  const PrixTickets({super.key});

  @override
  _PrixTicketsState createState() => _PrixTicketsState();
}

class _PrixTicketsState extends State<PrixTickets> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _axeController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prix des Tickets'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('prixDesTickets').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucune donnée disponible'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return Padding(
                padding: const EdgeInsets.only(
                    left: 12, top: 4, right: 12, bottom: 4),
                child: Card(
                  margin: const EdgeInsets.all(4),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 12.0, top: 4, right: 12.0, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  doc['axe'],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  doc['prix'].toString(),
                                ),
                              ],
                            )
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _modifierPrixDesTickets(context, doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _supprimerPrixDesTickets(context, doc),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ajouterPrixDesTickets(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _ajouterPrixDesTickets(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: true,
      context: context,
      builder: (BuildContext ctx) {
        return Wrap(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _axeController,
                      decoration: const InputDecoration(labelText: 'Axe'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un axe.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _prixController,
                      decoration: const InputDecoration(labelText: 'Prix'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un prix.';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final axe = _axeController.text.trim();
                          final prix = int.parse(_prixController.text.trim());

                          FirebaseFirestore.instance
                              .collection('prixDesTickets')
                              .add({
                            'axe': axe,
                            'prix': prix,
                          });

                          _axeController.clear();
                          _prixController.clear();
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _modifierPrixDesTickets(
      BuildContext context, DocumentSnapshot? documentSnapshot) {
    if (documentSnapshot != null) {
      _axeController.text = documentSnapshot['axe'];
      _prixController.text = documentSnapshot['prix'].toString();
    }

    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 120),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _axeController,
                      decoration: const InputDecoration(labelText: 'Axe'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un axe.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _prixController,
                      decoration: const InputDecoration(labelText: 'Prix'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un prix.';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final axe = _axeController.text.trim();
                          final prix = int.parse(_prixController.text.trim());

                          FirebaseFirestore.instance
                              .collection('prixDesTickets')
                              .doc(documentSnapshot!.id)
                              .update({'axe': axe, 'prix': prix});

                          _axeController.clear();
                          _prixController.clear();
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Modifier'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _supprimerPrixDesTickets(
      BuildContext context, DocumentSnapshot? documentSnapshot) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer Prix'),
        content: const Text('Voulez-vous vraiment supprimer cet élément ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      FirebaseFirestore.instance
          .collection('prixDesTickets')
          .doc(documentSnapshot!.id)
          .delete();
    }
  }
}


/*
class PrixDesTickets {
  final String documentId;
  final String axe;
  final int prix;

  PrixDesTickets({
    required this.documentId,
    required this.axe,
    required this.prix,
  });

  factory PrixDesTickets.fromSnapshot(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    return PrixDesTickets(
      documentId: document.id,
      axe: data['axe'] ?? '',
      prix: data['prix'] ?? 0,
    );
  }
}

class PrixDesTicketsScreen extends StatefulWidget {
  const PrixDesTicketsScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<PrixDesTicketsScreen> createState() => _PrixDesTicketsScreenState();
}

class _PrixDesTicketsScreenState extends State<PrixDesTicketsScreen> {
  var formKey = GlobalKey<FormState>();
  String? dropdownvalueBat;
  String? selectedValue;
  List<String> listeBatiments = [];

  final TextEditingController _axe = TextEditingController();
  final TextEditingController _prix = TextEditingController();
  final CollectionReference axe =
      FirebaseFirestore.instance.collection('prixtickets');

  Future<void> _creerOuModifier(
      [DocumentSnapshot? documentSnapshot, String? id]) async {
    String action = 'créer';
    if (documentSnapshot != null) {
      action = 'modifier';
      _axe.text = documentSnapshot['axe'];
      _prix.text = documentSnapshot['prix'].toString();
    }
    await showModalBottomSheet(
        isScrollControlled: true,
        isDismissible: true,
        context: context,
        builder: (BuildContext ctx) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 120),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _axe,
                        decoration: const InputDecoration(
                          labelText: 'Axe',
                          iconColor: Color.fromARGB(255, 255, 149, 0),
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 255, 149, 0),
                          ),
                        ),
                        validator: (oeufRclt) {
                          if (oeufRclt!.isEmpty) {
                            return "Entrez l'axe";
                          } else {
                            return null;
                          }
                        },
                      ),
                      TextFormField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        controller: _prix,
                        decoration: const InputDecoration(
                          labelText: 'Prix',
                          iconColor: Color.fromARGB(255, 255, 149, 0),
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 255, 149, 0),
                          ),
                        ),
                        validator: (oeufCes) {
                          if (oeufCes!.isEmpty) {
                            return "Entrez le prix";
                          } else {
                            return null;
                          }
                        },
                      ),
                      Center(
                          child: ElevatedButton(
                              child: Text(
                                action == 'créer' ? 'Créer' : 'Modifier',
                              ),
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  if (action == 'créer') {
                                    // AJOUTER
                                  }
                                  if (action == 'modifier') {
                                    if ("batDeVerification" ==
                                        dropdownvalueBat) {
                                      await axe
                                          .doc("idbandeProd")
                                          .collection('ergJournaliers')
                                          .doc(documentSnapshot!.id)
                                          .update({
                                        "jour": "jour",
                                        "mois": "mois",
                                      });
                                    }
                                    _axe.text = '';
                                    _prix.text = '';
                                    dropdownvalueBat = '';

                                    Navigator.of(context).pop();
                                  }
                                }
                              }))
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }

  @override
  void initState() {}

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 242, 255, 0)),
        centerTitle: true,
        elevation: 1,
        backgroundColor: const Color.fromARGB(255, 255, 149, 0),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bandes').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Erreur : ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          bool linearProgressIndicatorDisplayed = false;
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Aucune donnée disponible'),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              return StreamBuilder<QuerySnapshot>(
                stream: document.reference
                    .collection('ergJournaliers')
                    .orderBy('dateDeCreation', descending: true)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> ergSnapshot) {
                  if (ergSnapshot.hasError) {
                    return Text('Erreur : ${ergSnapshot.error}');
                  }

                  if (ergSnapshot.connectionState == ConnectionState.waiting) {
                    if (!linearProgressIndicatorDisplayed) {
                      linearProgressIndicatorDisplayed = true;
                      return const LinearProgressIndicator();
                    }
                    return Container();
                  } else if (ergSnapshot.data!.docs.isEmpty) {
                    return Container();
                  }
                  return Column(
                    children: ergSnapshot.data!.docs
                        .map((DocumentSnapshot ergDocument) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, top: 8, right: 8, bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Date : ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        children: [
                                          Text(ergDocument['date']),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        "Quantité d'oeuf collecté : ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(ergDocument['oeufscollectes']
                                          .toString()),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        "Batiment : ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        children: [
                                          Text(ergDocument['batiment']),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 40,
                            ),
                            Row(
                              children: [
                                IconButton(
                                    onPressed: () async {},
                                    icon: const Icon(Icons.edit)),
                                IconButton(
                                  onPressed: () async {},
                                  icon: const Icon(Icons.delete),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _axe.text = '';
          _prix.text = '';
          dropdownvalueBat = '';
          _creerOuModifier();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
*/
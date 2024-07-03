import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mvst_admin/config/config.dart';

class Profil extends StatefulWidget {
  const Profil(
      {super.key, required this.idUtilisateur, required this.userProfil});
  final String idUtilisateur;
  final String userProfil;

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _prenoms = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _residence = TextEditingController();

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    CollectionReference usersCollection = _firestore.collection('utilisateurs');

    try {
      QuerySnapshot querySnapshot =
          await usersCollection.where('id', isEqualTo: userId).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        return userDoc.data() as Map<String, dynamic>?;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 8),
            backgroundColor: Config.colors.bleuFonce2,
            content: Text(
              'Aucun utilisateur trouvé avec l\'ID "$userId".',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          backgroundColor: Config.colors.bleuFonce2,
          content: Text(
            'Erreur lors de la récupération des données de l\'utilisateur : $e',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Config.colors.bleuFonce2,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: getUserData(widget.idUtilisateur),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SpinKitThreeBounce(
                    color: Config.colors.bleuFonce2,
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data == null) {
                return Text('Aucun utilisateur trouvé.');
              } else {
                final userData = snapshot.data!;
                return Column(
                  children: [
                    Container(
                      width: 120.0,
                      height: 120.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Config.colors.jauneBlanc,
                          width: 2.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'MVST',
                          style: TextStyle(
                            color: Config.colors.bleuClaire,
                            fontSize: 24,
                            fontFamily: 'Lobster',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                "Nom: ",
                                style: TextStyle(
                                  color: Config.colors.bleuClaire,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                              const SizedBox(
                                width: 90,
                              ),
                              Text(
                                "${userData['nom']}",
                                style: TextStyle(
                                  color: Config.colors.bleuClaire,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                "Prénoms: ",
                                style: TextStyle(
                                  color: Config.colors.bleuClaire,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                              const SizedBox(
                                width: 90,
                              ),
                              Text(
                                "${userData['prenoms']}",
                                style: TextStyle(
                                  color: Config.colors.bleuClaire,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                "Téléphone: ",
                                style: TextStyle(
                                  color: Config.colors.bleuClaire,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                              const SizedBox(
                                width: 90,
                              ),
                              Text(
                                "${userData['telephone']}",
                                style: TextStyle(
                                  color: Config.colors.bleuClaire,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                "Lieu de résidence: ",
                                style: TextStyle(
                                  color: Config.colors.bleuClaire,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                              const SizedBox(
                                width: 90,
                              ),
                              Text(
                                "${userData['residence']}",
                                style: TextStyle(
                                  color: Config.colors.bleuClaire,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 80,
                          ),
                          GestureDetector(
                            onTap: () {
                              var id = userData['id'];
                              _nom.text = userData['nom'];
                              _prenoms.text = userData['prenoms'];
                              _telephone.text = userData['telephone'];
                              _residence.text = userData['residence'];
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) {
                                  String nom = _nom.text;
                                  String prenoms = _prenoms.text;
                                  String telephone = _telephone.text;
                                  String residence = _residence.text;
                                  return Container(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: _nom,
                                          decoration: InputDecoration(
                                            labelText: 'Nom',
                                            hintText: userData['nom'],
                                          ),
                                        ),
                                        TextField(
                                          controller: _prenoms,
                                          decoration: InputDecoration(
                                            labelText: 'Prénoms',
                                            hintText: userData['prenoms'],
                                          ),
                                        ),
                                        TextField(
                                          controller: _telephone,
                                          keyboardType: TextInputType.phone,
                                          decoration: InputDecoration(
                                            labelText: 'Téléphone',
                                            hintText: userData['telephone'],
                                          ),
                                        ),
                                        TextField(
                                          controller: _residence,
                                          decoration: InputDecoration(
                                            labelText: 'Lieu de résidence',
                                            hintText: userData['residence'],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            editerDocument(
                                              context,
                                              id,
                                              nom,
                                              prenoms,
                                              telephone,
                                              residence,
                                            );
                                            Navigator.pop(context);
                                          },
                                          child: Text('Enregistrer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  'Modifier',
                                  style: TextStyle(
                                      color: Config.colors.bleuClaire),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Icon(Icons.edit),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                );
              }
            },
          ),
        ),
      ),
      persistentFooterButtons: [
        Text(
          "${widget.userProfil}",
          style: TextStyle(
            fontFamily: 'Lobster',
            color: Config.colors.bleuClaire,
          ),
        )
      ],
    );
  }
}

Future<void> editerDocument(BuildContext ctx, String documentId, String nom,
    String prenoms, String telephone, String residence) async {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentReference documentRef =
      _firestore.collection('utilisateurs').doc(documentId);

  try {
    await documentRef.update({
      "nom": nom,
      "prenoms": prenoms,
      "telephone": telephone,
      "residence": residence,
    });
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 8),
        backgroundColor: Config.colors.bleuFonce2,
        content: Text(
          'Modifications apportées avec succès',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  } catch (e) {}
}

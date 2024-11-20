import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/models/models.dart';
import 'package:mysql1/mysql1.dart';

class ListeImages2 extends StatefulWidget {
  const ListeImages2({super.key});

  @override
  _ListeImages2State createState() => _ListeImages2State();
}

class _ListeImages2State extends State<ListeImages2> {
  bool isLoading = false;
  List<ImageModel> _images = [];
  final List<String> statutOptions = ['Résidant', 'non-résidant'];

  MySqlConnection? conn;
  final String baseUrl = 'https://tenelodata-tech.com/mvst/';

  @override
  void initState() {
    super.initState();
    _initConnection();
    _recupListeImages2s();
  }

  Future<void> _initConnection() async {
    conn = await Connexion.connexionDB();
  }

  Future<void> _recupListeImages2s() async {
    setState(() {
      isLoading = true;
    });

    try {
      conn ??= await Connexion.connexionDB();

      final results = await conn!.query('SELECT * FROM Images');
      setState(() {
        _images =
            results.map((row) => ImageModel.fromJson(row.fields)).toList();
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
        title: const Text(
          'ListeImages2s',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final image = _images[index];
                return _buildListeImages2Card(image);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListeImages2Card(ImageModel image) {
    final String imageUrl = baseUrl + image.lien_image;
    return GestureDetector(
      onTap: () => {}
      /* showDialog(
        context: context,
        builder: (context) => _buildDetailsDialog(context, image),
      )*/
      ,
      child: Card(
        shadowColor: Colors.lightBlueAccent,
        elevation: 4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl,
                width: 120,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error_outline_outlined,
                      color: Colors.blueAccent);
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
                      '${image.titre} ${image.titre}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            // _buildActionButtons(image),
          ],
        ),
      ),
    );
  }
/*
  Widget _buildActionButtons(ImageModel image) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.edit,
            color: Colors.blue,
          ),
          onPressed: () => _showEditDialog(image),
        ),
        IconButton(
          icon:
              const Icon(Icons.delete, color: Color.fromARGB(255, 205, 59, 48)),
          onPressed: () => _showDeleteDialog(image),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(ImageModel ListeImages2) async {
    final TextEditingController nomController =
        TextEditingController(text: ListeImages2.nom);
    final TextEditingController prenomsController =
        TextEditingController(text: ListeImages2.prenoms);
    final TextEditingController telController =
        TextEditingController(text: ListeImages2.telephone);
    final TextEditingController statutController =
        TextEditingController(text: ListeImages2.statut);

    await showDialog(
      context: context,
      builder: (context) {
        statutController.text = ListeImages2.statut;

        return AlertDialog(
          title: Center(
            child: Text(
              'Modifier les informations de ${ListeImages2.nom + ListeImages2.prenoms}',
              style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: prenomsController,
                decoration: const InputDecoration(labelText: 'Prénoms'),
              ),
              TextField(
                maxLength: 10,
                keyboardType: TextInputType.phone,
                controller: telController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              DropdownButtonFormField<String>(
                value: statutController.text.isNotEmpty
                    ? statutController.text
                    : null,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: statutOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    statutController.text = newValue;
                  }
                },
                icon: Icon(Icons.arrow_drop_down,
                    color: Config.colors.couleurPrimaire),
                dropdownColor: Colors.white,
              ),
            ],
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
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() => isLoading = true);
                    await _modifierListeImages2DansMySQL(
                      ListeImages2,
                      nomController.text,
                      prenomsController.text,
                      telController.text,
                      statutController.text,
                    );
                    await _recupListeImages2s();
                    setState(() => isLoading = false);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(ImageModel ListeImages2) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(
          child: Text(
            'Suppression',
            style: TextStyle(
                color: Color.fromARGB(255, 214, 64, 53),
                fontWeight: FontWeight.w900),
          ),
        ),
        content: Text(
            'Voulez-vous vraiment supprimer ${ListeImages2.nom + ListeImages2.prenoms} ?'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Non',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Oui',
                  style: TextStyle(
                      color: Color.fromARGB(255, 214, 64, 53),
                      fontWeight: FontWeight.w900),
                ),
              ),
            ],
          )
        ],
      ),
    );

    if (confirmDelete) {
      await _supprimerListeImages2DeMySQL(ListeImages2);
      _recupListeImages2s();
    }
  }

  Future<void> _modifierListeImages2DansMySQL(ImageModel ListeImages2,
      String nom, String prenoms, String tel, String statut) async {
    try {
      conn ??= await Connexion.connexionDB();
      await conn!.query(
        'UPDATE ListeImages2 SET nom = ?, prenoms = ?, telephone = ?, statut = ? WHERE id = ?',
        [nom, prenoms, tel, statut, ListeImages2.id],
      );
    } catch (e) {}
  }

  Future<void> _supprimerListeImages2DeMySQL(
      ImageModel ListeImages2) async {
    try {
      var url = Uri.parse('https://tenelodata-tech.com/seke/upload.php');

      var response = await http.post(
        url,
        body: {
          'action': 'delete',
          'id': ListeImages2.id.toString(),
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color.fromARGB(255, 35, 113, 177),
              content: Text(
                "ListeImages2 supprimé avec succès.",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        } else if (jsonResponse['error'] != null) {}
      } else {}
    } catch (e) {}
  }
*/
}

/*
Widget _buildDetailsDialog(
    BuildContext context, ImageModel ListeImages2) {
  return Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Détails du ListeImages2',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Config.colors.couleurPrimaireB,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Image recto avec gestion des erreurs
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ListeImages2.imagePathRecto,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Image verso avec gestion des erreurs
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ListeImages2.imagePathVerso,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Informations du ListeImages2
          _buildInfoRow('Nom', ListeImages2.nom),
          const SizedBox(height: 8),
          _buildInfoRow('Prénoms', ListeImages2.prenoms),
          const SizedBox(height: 8),
          _buildInfoRow('Téléphone', ListeImages2.telephone),
          const SizedBox(height: 8),
          _buildInfoRow('Statut', ListeImages2.statut),
          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ok'),
            ),
          ),
        ],
      ),
    ),
  );
}
*/
Widget _buildInfoRow(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
      const Divider(
        thickness: 1,
        color: Colors.grey, // Couleur de la ligne en bas
      ),
    ],
  );
}

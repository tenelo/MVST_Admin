import 'package:cloud_firestore/cloud_firestore.dart';

class ImageModel {
  final String id;
  final String url;
  final String titre;
  final String description;

  ImageModel({
    required this.id,
    required this.url,
    required this.titre,
    required this.description,
  });

  // Méthode pour créer une instance d'ImageModel à partir de JSON
  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'] ??
          '', // Assurez-vous que 'id' correspond à votre base de données
      url: json['url'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
    );
  }

  // Méthode existante pour Firestore
  factory ImageModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ImageModel(
      id: doc.id,
      url: data['url'] ?? '',
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
    );
  }
}

import 'package:flutter/material.dart';

class ImageModel {
  final int id;
  final String titre;
  final String description;
  final String statut;
  final String lien_image;

  ImageModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.statut,
    required this.lien_image,
  });

  // Méthode pour créer une instance d'ImageModel à partir de JSON
  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      titre: json['titre'],
      description: json['description'],
      statut: json['statut'],
      lien_image: json['lien_image'] ?? '',
    );
  }
}

Widget porte() {
  return Row(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            color: const Color.fromARGB(255, 89, 87, 87),
            width: 1,
          ),
        ),
        height: 23,
        width: 8,
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            color: const Color.fromARGB(255, 89, 87, 87),
            width: 1,
          ),
        ),
        height: 24,
        width: 10,
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            color: const Color.fromARGB(255, 89, 87, 87),
            width: 1,
          ),
        ),
        height: 25,
        width: 12,
      ),
    ],
  );
}

// Classe pour représenter un ticket
class PlacesTickets {
  final String nom;
  final String telephone;
  final String depart;
  final String destination;
  final int place;

  PlacesTickets({
    required this.nom,
    required this.telephone,
    required this.depart,
    required this.destination,
    required this.place,
  });
  @override
  String toString() {
    return 'PlacesTickets(nom: $nom, telephone: $telephone, depart: $depart, destination: $destination, place: $place)';
  }
}

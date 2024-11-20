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
      lien_image: json['lien_image'],
    );
  }
}

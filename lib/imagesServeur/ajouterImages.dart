// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:mvst_admin/config/config.dart';
// import 'package:mvst_admin/models/models.dart';

// const String _baseUrl = 'https://mvst.tenelo.cloud';

// class ListeImages2 extends StatefulWidget {
//   const ListeImages2({super.key});

//   @override
//   _ListeImages2State createState() => _ListeImages2State();
// }

// class _ListeImages2State extends State<ListeImages2> {
//   bool isLoading = false;
//   List<ImageModel> _images = [];

//   @override
//   void initState() {
//     super.initState();
//     _recupListeImages2s();
//   }

//   // ── Charger les images via PHP ─────────────────────────────────────────────
//   Future<void> _recupListeImages2s() async {
//     if (mounted) setState(() => isLoading = true);
//     try {
//       final response = await http.get(
//         Uri.parse('$_baseUrl/gestionImages.php'),
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['success'] == true && mounted) {
//           setState(() {
//             _images = List<ImageModel>.from(
//               data['images'].map((i) => ImageModel.fromJson(i)),
//             );
//           });
//         }
//       }
//     } catch (e) {}
//     if (mounted) setState(() => isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(93, 12, 134, 195),
//         iconTheme: const IconThemeData(color: Colors.white),
//         centerTitle: true,
//         title: const Text('Images', style: TextStyle(color: Colors.white)),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _recupListeImages2s,
//           ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _images.isEmpty
//               ? Center(
//                   child: Text(
//                     'Aucune image disponible',
//                     style: TextStyle(
//                         color: Config.colors.authCardBackground,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 )
//               : ListView.builder(
//                   itemCount: _images.length,
//                   itemBuilder: (context, index) {
//                     final image = _images[index];
//                     return _buildListeImages2Card(image);
//                   },
//                 ),
//     );
//   }

//   Widget _buildListeImages2Card(ImageModel image) {
//     final String imageUrl = '$_baseUrl/${image.lien_image}';
//     return Card(
//       shadowColor: Colors.lightBlueAccent,
//       elevation: 4,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8.0),
//             child: Image.network(
//               imageUrl,
//               width: 120,
//               height: 110,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) => const Icon(
//                   Icons.error_outline_outlined,
//                   color: Colors.blueAccent),
//             ),
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     image.titre,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     image.description,
//                     maxLines: 3,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

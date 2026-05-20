// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:mvst_admin/config/config.dart';
// import 'package:mvst_admin/mesfonctions/mesfonctions.dart';

// class PrixTickets extends StatefulWidget {
//   const PrixTickets({super.key});

//   @override
//   _PrixTicketsState createState() => _PrixTicketsState();
// }

// class _PrixTicketsState extends State<PrixTickets> {
//   final _formKeyAjout = GlobalKey<FormState>();
//   final _formKeyModif = GlobalKey<FormState>();
//   final TextEditingController _prixController = TextEditingController();

//   List<Map<String, dynamic>> _prixList = [];
//   List<Map<String, dynamic>> _lignesSansPrix = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _rafraichirDonnees();
//   }

//   @override
//   void dispose() {
//     _prixController.dispose();
//     super.dispose();
//   }

//   Future<void> _rafraichirDonnees() async {
//     if (mounted) setState(() => _isLoading = true);
//     try {
//       final results = await Future.wait([
//         http.get(apiUri('api_lignes.php?type=standard')),
//         http.get(apiUri('api_lignes.php?type=standard&sans_prix=1')),
//       ]);

//       if (mounted) {
//         final prixData = jsonDecode(results[0].body);
//         final sansPrixData = jsonDecode(results[1].body);

//         setState(() {
//           if (prixData['success'] == true) {
//             _prixList = List<Map<String, dynamic>>.from(
//               prixData['lignes'],
//             ).where((l) => (l['prix'] as int) > 0).toList();
//           }
//           if (sansPrixData['success'] == true) {
//             _lignesSansPrix = List<Map<String, dynamic>>.from(
//               sansPrixData['lignes'],
//             );
//           }
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _ajouter(int idLigne, int prix) async {
//     try {
//       final ligne = _lignesSansPrix.firstWhere((l) => l['id'] == idLigne);
//       await http.post(
//         apiUri('api_lignes.php'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'action': 'modifier',
//           'id': idLigne,
//           'depart': ligne['depart'],
//           'destination': ligne['destination'],
//           'ligne': ligne['ligne'],
//           'prix': prix,
//         }),
//       );
//       await _rafraichirDonnees();
//     } catch (e) {}
//   }

//   Future<void> _modifier(
//     int id,
//     String depart,
//     String destination,
//     String ligne,
//     int prix,
//   ) async {
//     try {
//       await http.post(
//         apiUri('api_lignes.php'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'action': 'modifier',
//           'id': id,
//           'depart': depart,
//           'destination': destination,
//           'ligne': ligne,
//           'prix': prix,
//         }),
//       );
//       await _rafraichirDonnees();
//     } catch (e) {}
//   }

//   void _afficherMessage(String message, {bool isError = true}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         duration: const Duration(seconds: 3),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(93, 12, 134, 195),
//         iconTheme: const IconThemeData(color: Colors.white),
//         centerTitle: true,
//         title: const Text(
//           'Prix des Tickets',
//           style: TextStyle(color: Colors.white),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _rafraichirDonnees,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _prixList.isEmpty
//           ? Center(
//               child: Text(
//                 'Aucune donnée disponible',
//                 style: TextStyle(
//                   color: Config.colors.authCardBackground,
//                   fontFamily: 'Lobster',
//                 ),
//               ),
//             )
//           : ListView.builder(
//               itemCount: _prixList.length,
//               itemBuilder: (context, index) {
//                 final ticket = _prixList[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 4,
//                   ),
//                   child: Card(
//                     margin: const EdgeInsets.all(4),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 ticket['ligne'].toString(),
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               Text('${ticket['prix']} f'),
//                             ],
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.edit),
//                             onPressed: () =>
//                                 _afficherModalModifier(context, ticket),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//       floatingActionButton: _lignesSansPrix.isEmpty
//           ? null
//           : FloatingActionButton(
//               onPressed: () => _afficherModalAjouter(context),
//               child: const Icon(Icons.add),
//             ),
//     );
//   }

//   void _afficherModalAjouter(BuildContext context) {
//     int? ligneSelectionnee;
//     _prixController.clear();

//     showModalBottomSheet(
//       isScrollControlled: true,
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (ctx2, setModalState) {
//           return Padding(
//             padding: EdgeInsets.only(
//               top: 20,
//               left: 20,
//               right: 20,
//               bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20,
//             ),
//             child: Form(
//               key: _formKeyAjout,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Ajouter un prix',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 12),

//                   // Dropdown lignes sans prix
//                   DropdownButtonFormField<int>(
//                     value: ligneSelectionnee,
//                     decoration: const InputDecoration(labelText: 'Ligne'),
//                     items: _lignesSansPrix
//                         .map(
//                           (l) => DropdownMenuItem<int>(
//                             value: l['id'] as int,
//                             child: Text(l['ligne'].toString()),
//                           ),
//                         )
//                         .toList(),
//                     onChanged: (val) =>
//                         setModalState(() => ligneSelectionnee = val),
//                     validator: (v) => v == null ? 'Choisissez une ligne' : null,
//                   ),

//                   const SizedBox(height: 8),

//                   TextFormField(
//                     controller: _prixController,
//                     decoration: const InputDecoration(labelText: 'Prix (f)'),
//                     keyboardType: TextInputType.number,
//                     validator: (v) {
//                       if (v == null || v.isEmpty) {
//                         return 'Veuillez entrer un prix';
//                       }
//                       if (int.tryParse(v) == null || int.parse(v) <= 0) {
//                         return 'Entrer un nombre valide supérieur à 0';
//                       }
//                       return null;
//                     },
//                   ),

//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () async {
//                       if (_formKeyAjout.currentState!.validate()) {
//                         Navigator.of(context).pop();
//                         await _ajouter(
//                           ligneSelectionnee!,
//                           int.parse(_prixController.text.trim()),
//                         );
//                         _afficherMessage(
//                           'Prix ajouté avec succès',
//                           isError: false,
//                         );
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 45),
//                     ),
//                     child: const Text('Ajouter'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _afficherModalModifier(
//     BuildContext context,
//     Map<String, dynamic> ticket,
//   ) {
//     _prixController.text = ticket['prix'].toString();

//     showModalBottomSheet(
//       isScrollControlled: true,
//       context: context,
//       builder: (ctx) => Padding(
//         padding: EdgeInsets.only(
//           top: 20,
//           left: 20,
//           right: 20,
//           bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
//         ),
//         child: Form(
//           key: _formKeyModif,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Modifier le prix',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 12),

//               // Ligne en lecture seule
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 14,
//                   horizontal: 12,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade200,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   ticket['ligne'].toString(),
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 15,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 8),

//               TextFormField(
//                 controller: _prixController,
//                 decoration: const InputDecoration(labelText: 'Prix (f)'),
//                 keyboardType: TextInputType.number,
//                 validator: (v) {
//                   if (v == null || v.isEmpty) {
//                     return 'Veuillez entrer un prix';
//                   }
//                   if (int.tryParse(v) == null || int.parse(v) <= 0) {
//                     return 'Entrer un nombre valide supérieur à 0';
//                   }
//                   return null;
//                 },
//               ),

//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (_formKeyModif.currentState!.validate()) {
//                     Navigator.of(context).pop();
//                     await _modifier(
//                       ticket['id'],
//                       ticket['depart'].toString(),
//                       ticket['destination'].toString(),
//                       ticket['ligne'].toString(),
//                       int.parse(_prixController.text.trim()),
//                     );
//                     _afficherMessage(
//                       'Prix modifié avec succès',
//                       isError: false,
//                     );
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 45),
//                 ),
//                 child: const Text('Modifier'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

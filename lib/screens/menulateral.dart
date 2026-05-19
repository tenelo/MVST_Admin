// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:mvst_admin/screens/ticketsDuJourScannes.dart';
// import 'package:mvst_admin/screens/tousLesDepartsDuJour.dart';

// class MenuLateral extends StatefulWidget {
//   const MenuLateral(
//       {super.key,
//       required this.gare,
//       required this.uid,
//       required this.tailleEcran,
//       required this.date,
//       required this.dateNormale});
//   final String gare;
//   final String uid;
//   final int tailleEcran;
//   final String date;
//   final String dateNormale;
//   @override
//   State<MenuLateral> createState() => _MenuLateralState();
// }

// class _MenuLateralState extends State<MenuLateral> {
//   // Index de la page actuellement sélectionnée
//   int _selectedIndex = 0;
//   late final List<Widget> _pages;

//   @override
//   void initState() {
//     super.initState();
//     _pages = [
//       TicketsDuJourScannes(
//         date: widget.date,
//         gare: widget.gare,
//         uid: widget.uid,
//       ),
//       TousLesDepartsDuJour(
//         date: widget.date,
//         dateNormale: widget.dateNormale,
//         tailleEcran: widget.tailleEcran,
//         gare: widget.gare,
//         uid: widget.uid,
//       ),
//     ];
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       body: widget.tailleEcran > 7
//           ? ecranTablette(screenHeight)
//           : ecranMoyen(screenHeight),
//     );
//   }

//   Widget ecranMoyen(double taille) {
//     return Row(
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(10),
//           child: Container(
//             width: 65,
//             height: taille * 0.2,
//             color: Colors.blue.shade700,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildSidebarItemEcranMoyen(
//                   icon: CupertinoIcons.tickets,
//                   index: 0,
//                 ),
//                 _buildSidebarItemEcranMoyen(
//                   icon: Icons.bar_chart,
//                   index: 1,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // Contenu principal
//         Expanded(
//           child: _pages[_selectedIndex],
//         ),
//       ],
//     );
//   }

//   Widget ecranTablette(double taille) {
//     return Row(
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(10),
//           child: Container(
//             width: 100,
//             height: taille * 0.2,
//             color: Colors.blue.shade700,
//             child: Column(
//               children: [
//                 const SizedBox(height: 40),
//                 _buildSidebarItemTablette(
//                   icon: CupertinoIcons.tickets,
//                   text: 'Scannés',
//                   index: 0,
//                 ),
//                 _buildSidebarItemTablette(
//                   icon: Icons.bar_chart,
//                   text: 'Départs',
//                   index: 1,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // Contenu principal
//         Expanded(
//           child: _pages[_selectedIndex],
//         ),
//       ],
//     );
//   }

//   // Widget pour les éléments du menu latéral
//   Widget _buildSidebarItemEcranMoyen(
//       {required IconData icon, required int index}) {
//     return ListTile(
//       leading: Icon(icon,
//           color: _selectedIndex == index ? Colors.amber : Colors.white),
//       selected: _selectedIndex == index,
//       onTap: () {
//         setState(() {
//           _selectedIndex = index;
//         });
//       },
//     );
//   }

//   Widget _buildSidebarItemTablette(
//       {required IconData icon, required String text, required int index}) {
//     return ListTile(
//       contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
//       horizontalTitleGap: 4,
//       leading: Icon(icon,
//           color: _selectedIndex == index ? Colors.amber : Colors.white),
//       title: Text(
//         text,
//         style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: _selectedIndex == index ? Colors.amber : Colors.white),
//       ),
//       selected: _selectedIndex == index,
//       onTap: () {
//         setState(() {
//           _selectedIndex = index;
//         });
//       },
//     );
//   }
// }

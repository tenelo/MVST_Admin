import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst_admin/bloc/bolc.dart';
import 'package:mvst_admin/bloc/event.dart';
import 'package:mvst_admin/bloc/state.dart';

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('AFFICHAGE DE LA DEUXIEME PAGE');
    return Scaffold(
      appBar: AppBar(title: Text('AFFICHAGE 2')),
      body: BlocBuilder<BlocListePlaces, StateListePlaces>(
        builder: (context, state) {
          if (state is ListPlacesLoaded) {
            final listeEntiers = state.integers;
            return ListView.builder(
              itemCount: listeEntiers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(listeEntiers[index].toString()),
                );
              },
            );
          } else if (state is ListPlacesError) {
            return Center(child: Text(state.message));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<BlocListePlaces>().add(ChargerLaList());
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}

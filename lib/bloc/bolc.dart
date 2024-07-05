import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst_admin/bloc/event.dart';
import 'package:mvst_admin/bloc/state.dart';

class BlocListePlaces extends Bloc<EventListePlaces, StateListePlaces> {
  BlocListePlaces() : super(ListPlacesInitial()) {
    on<ChargerLaList>(_onLoadEntierList);
  }

  Future<void> _onLoadEntierList(
      ChargerLaList event, Emitter<StateListePlaces> emit) async {
    emit(ListPlacesInitial());
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('tickets').get();
      final List<int> integers =
          snapshot.docs.map((doc) => doc['place'] as int).toList();
      emit(ListPlacesLoaded(integers));
    } catch (e) {
      emit(ListPlacesError('Échec de la récupération des données'));
      print("ERREUR : $e");
    }
  }
}

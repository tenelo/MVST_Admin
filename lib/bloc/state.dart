import 'package:equatable/equatable.dart';

abstract class StateListePlaces extends Equatable {
  const StateListePlaces();

  @override
  List<Object> get props => [];
}

class ListPlacesInitial extends StateListePlaces {}

class ListPlacesLoaded extends StateListePlaces {
  final List<int> integers;

  const ListPlacesLoaded(this.integers);

  @override
  List<Object> get props => [integers];
}

class ListPlacesError extends StateListePlaces {
  final String message;

  const ListPlacesError(this.message);

  @override
  List<Object> get props => [message];
}

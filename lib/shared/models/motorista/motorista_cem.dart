import 'lista_cem.dart';

class MotoristaCem {
  List<Cem>? listaCem;

  MotoristaCem({this.listaCem});

  factory MotoristaCem.fromJson(Map<String, dynamic> json) {
    return MotoristaCem(
      listaCem: (json['cems'] as List<dynamic>?)
          ?.map((e) => Cem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cems': listaCem?.map((e) => e.toJson()).toList(),
    };
  }

  MotoristaCem copyWith({
    List<Cem>? listaCem,
  }) {
    return MotoristaCem(
      listaCem: listaCem ?? this.listaCem,
    );
  }
}

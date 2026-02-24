import 'package:delivery_front/shared/models/motorista/models/motoristas_proximos.dart';

class ListaMotoristaProximos {
  List<MotoristasProximos>? listaSolicitacoes;

  ListaMotoristaProximos({this.listaSolicitacoes});

  factory ListaMotoristaProximos.fromJson(Map<String, dynamic> json) {
    return ListaMotoristaProximos(
      listaSolicitacoes: (json['motoristas'] as List<dynamic>?)
          ?.map((e) => MotoristasProximos.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'motoristas': listaSolicitacoes?.map((e) => e.toJson()).toList(),
    };
  }
}

import 'dart:convert';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/shared/models/consultaRequest.dart';
import 'package:delivery_front/shared/models/filter_model.dart';
import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return FilterScreenState();
  }
}

class FilterScreenState extends State<FilterScreen> {
  bool isPaid = false;
  bool isFree = false;
  bool isLatest = false;
  bool isOld = false;
  bool isFilter = false;

  DateTimeRange? _selectedDateRange = DateTimeRange(
      start: ApiBaseHelper.findFirstDateOfTheWeek(DateTime.now()),
      end: ApiBaseHelper.findLastDateOfTheWeek(DateTime.now()));

  List<String> selected = List.empty(growable: true);
  List<BookF> filter_three = [
    BookF(ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA.toString(),
        "Nova corrida", false),
    BookF(ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA.toString(),
        "Corrida aceita", false),
    BookF(ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA.toString(),
        "Corridas concluídas", false),
    BookF(ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA.toString(), "Canceladas",
        false),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Pesquisar"),
        backgroundColor: Colors.black,
        actions: [
          MaterialButton(
              child: Text(
                "Limpar",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  filter_three.forEach((element) {
                    element.isSelected = false;
                  });

                  isFilter = false;
                  isPaid = false;
                  isFree = false;
                  isLatest = false;
                  isOld = false;

                  _selectedDateRange = DateTimeRange(
                      start:
                          ApiBaseHelper.findFirstDateOfTheWeek(DateTime.now()),
                      end: ApiBaseHelper.findLastDateOfTheWeek(DateTime.now()));
                });
              }),
          MaterialButton(
              onPressed: () {
                Map<String, dynamic> filters = Map();
                filters['isPaid'] = (isPaid) ? 1 : 0;
                filters['isFree'] = (isFree) ? 1 : 0;
                filters['Latest'] = (isLatest) ? 1 : 0;
                filters['Old'] = (isOld) ? 1 : 0;
                filters['cat'] = (selected);
                String inValues =
                    selected.toString().replaceAll("[", "").replaceAll("]", "");
                ConsultaRequest request = ConsultaRequest(
                    numSeq: null,
                    codEmpresa: null,
                    codMotorista: null,
                    dtaIni: _selectedDateRange!.start,
                    dtaFim: _selectedDateRange!.end,
                    inInfro: inValues);
                Navigator.pop(context, request.toJson());
              },
              child: Text(
                "Aplicar",
                style: TextStyle(color: Colors.white),
              ))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text("Sort By", style: TextStyle(color: Colors.red)),
                // SizedBox(
                //   height: 10,
                // ),
                // Row(children: [
                //   Text(
                //       "Data inicial ${ApiBaseHelper.getDtaFormatadaSemHora(_selectedDateRange!.start)}  - Data final: ${ApiBaseHelper.getDtaFormatadaSemHora(_selectedDateRange!.end)}",
                //       style: TextStyle(color: Colors.black)),
                //   SizedBox(
                //     width: 20,
                //   ),
                //   FloatingActionButton(
                //       onPressed: () async {
                //         final DateTimeRange? result = await showDateRangePicker(
                //           context: context,
                //           firstDate: DateTime(2022, 1, 1),
                //           lastDate: DateTime(2030, 12, 31),
                //           currentDate: DateTime.now(),
                //           locale: Locale('pt', 'BR'),
                //           saveText: 'Concluir',
                //         );

                //         if (result != null) {
                //           // Rebuild the UI
                //           print(result.start.toString());
                //           setState(() {
                //             _selectedDateRange = result;
                //           });
                //         }
                //       },
                //       child: Icon(Icons.calendar_month)),
                // ]),
                // Row(children: [
                //   Checkbox(
                //       value: isPaid,
                //       onChanged: (value) {
                //         setState(() {
                //           isPaid = value!;
                //           isFilter = true;
                //         });
                //       }),
                //   Text("Paid", style: TextStyle(color: Colors.red)),
                // ]),
                // Row(children: [
                //   Checkbox(
                //       value: isFree,
                //       onChanged: (value) {
                //         setState(() {
                //           isFree = value!;
                //           isFilter = true;
                //         });
                //       }),
                //   Text("Free", style: TextStyle(color: Colors.red)),
                // ]),
                // SizedBox(
                //   height: 20,
                // ),
                // Divider(
                //   height: 2,
                //   color: Colors.grey,
                // ),
                // Text("Sort By", style: TextStyle(color: Colors.deepPurple)),
                // SizedBox(
                //   height: 10,
                // ),
                // Row(children: [
                //   Checkbox(
                //       value: isLatest,
                //       onChanged: (value) {
                //         setState(() {
                //           isLatest = value!;
                //         });
                //       }),
                //   Text("Latest", style: TextStyle(color: Colors.deepPurple)),
                // ]),
                // Row(children: [
                //   Checkbox(
                //       value: isOld,
                //       onChanged: (value) {
                //         setState(() {
                //           isOld = value!;
                //         });
                //       }),
                //   Text("Old", style: TextStyle(color: Colors.deepPurple)),
                // ]),
                // SizedBox(
                //   height: 20,
                // ),
                // Divider(
                //   height: 2,
                //   color: Colors.grey,
                // ),

                SizedBox(
                  height: 10,
                ),
                Text("Filtrar por:", style: TextStyle(color: Colors.black)),
                SizedBox(
                  height: 10,
                ),

                Text("Data:", style: TextStyle(color: Colors.black)),
                SizedBox(
                  height: 10,
                ),
                Divider(
                  height: 2,
                  color: Colors.grey,
                ),
                SizedBox(
                  height: 10,
                ),

                Text(
                    "Data inicial: ${ApiBaseHelper.getDtaFormatadaSemHora(_selectedDateRange!.start)}",
                    style: TextStyle(color: Colors.black)),
                SizedBox(
                  height: 10,
                ),
                Row(children: [
                  Text(
                      "Data final: ${ApiBaseHelper.getDtaFormatadaSemHora(_selectedDateRange!.end)}",
                      style: TextStyle(color: Colors.black)),
                  SizedBox(
                    width: 25,
                  ),
                  FloatingActionButton(
                      heroTag: "consultaDate",
                      onPressed: () async {
                        final DateTimeRange? result = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2022, 1, 1),
                          lastDate: DateTime(2030, 12, 31),
                          currentDate: DateTime.now(),
                          initialDateRange: DateTimeRange(
                              start: ApiBaseHelper.findFirstDateOfTheWeek(
                                  DateTime.now()),
                              end: ApiBaseHelper.findLastDateOfTheWeek(
                                  DateTime.now())),
                          locale: Locale('pt', 'BR'),
                          saveText: 'Concluir',
                        );

                        if (result != null) {
                          // Rebuild the UI
                          print(result.start.toString());
                          setState(() {
                            _selectedDateRange = result;
                          });
                        }
                      },
                      child: Icon(Icons.calendar_month)),
                ]),
                SizedBox(
                  height: 20,
                ),

                Text("Tipo:", style: TextStyle(color: Colors.black)),
                SizedBox(
                  height: 10,
                ),
                Divider(
                  height: 2,
                  color: Colors.grey,
                ),
                SizedBox(
                  height: 10,
                ),
                Wrap(
                  spacing: 8,
                  direction: Axis.horizontal,
                  children: techChips(filter_three, Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> techChips(List<BookF> _chipsList, color) {
    List<Widget> chips = [];
    for (int i = 0; i < _chipsList.length; i++) {
      Widget item = Padding(
        padding: const EdgeInsets.only(left: 10, right: 5),
        child: FilterChip(
          selectedColor: color,
          label: Text(_chipsList[i].filter_title),
          labelStyle: TextStyle(color: Colors.white),
          backgroundColor: color,
          selected: _chipsList[i].isSelected,
          checkmarkColor: Colors.white,
          onSelected: (bool value) {
            if (value) {
              selected.add(_chipsList[i].filter_id);
            } else {
              selected.remove(_chipsList[i].filter_id);
            }
            setState(() {
              _chipsList[i].isSelected = value;
            });
          },
        ),
      );
      chips.add(item);
    }
    return chips;
  }
}

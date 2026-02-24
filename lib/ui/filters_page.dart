import 'package:flutter/material.dart';
import 'theme_components.dart';

class FiltersPage extends StatefulWidget {
  final Function(DateTimeRange?, Set<String>)? onApplyFilters;
  final DateTimeRange? initialRange;
  final Set<String> initialTypes;

  const FiltersPage({
    Key? key,
    this.onApplyFilters,
    this.initialRange,
    this.initialTypes = const {},
  }) : super(key: key);

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  DateTimeRange? selectedRange;
  final List<String> types = ["Nova corrida", "Corrida aceita", "Corridas concluídas", "Canceladas"];
  final Set<String> selectedTypes = {};

  @override
  void initState() {
    super.initState();
    selectedRange = widget.initialRange;
    selectedTypes.addAll(widget.initialTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: const AppAppBar(title: "Filtros", showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Filtrar por:", style: kTitleStyle),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Data:", style: kSubtitleStyle),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(now.year - 2),
                          lastDate: DateTime(now.year + 2),
                        );
                        if (picked != null) {
                          setState(() => selectedRange = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: kBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedRange == null
                              ? "Selecionar intervalo"
                              : "${selectedRange!.start.day}/${selectedRange!.start.month}/${selectedRange!.start.year} - ${selectedRange!.end.day}/${selectedRange!.end.month}/${selectedRange!.end.year}",
                          style: kSubtitleStyle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Tipo:", style: kSubtitleStyle),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: types.map((t) {
                        final active = selectedTypes.contains(t);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              active ? selectedTypes.remove(t) : selectedTypes.add(t);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: active ? kPrimaryRed : kBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: active ? kPrimaryRed : Colors.transparent),
                            ),
                            child: Text(t, style: TextStyle(color: active ? Colors.white : Colors.black87)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          selectedRange = null;
                          selectedTypes.clear();
                        });
                      },
                      child: const Text("Limpar"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      label: "Aplicar",
                      onTap: () {
                        if (widget.onApplyFilters != null) {
                          widget.onApplyFilters!(selectedRange, selectedTypes);
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delivery_front/shared/models/destino_corrida.dart';
import 'package:geocoding/geocoding.dart';

/// Widget moderno para múltiplas paradas — estilo Rappi/iFood
/// - Drag & drop para reordenar
/// - Auto-geocodificação ao sair do campo
/// - Timeline visual (bolinha + linha vertical)
class MultiplosDestinosWidget extends StatefulWidget {
  final List<DestinoCorrida> destinos;
  final Function(List<DestinoCorrida>) onDestinosChanged;
  final bool enabled;

  const MultiplosDestinosWidget({
    Key? key,
    required this.destinos,
    required this.onDestinosChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<MultiplosDestinosWidget> createState() =>
      _MultiplosDestinosWidgetState();
}

class _MultiplosDestinosWidgetState extends State<MultiplosDestinosWidget> {
  late List<DestinoCorrida> _destinos;

  @override
  void initState() {
    super.initState();
    _destinos = List.from(widget.destinos);
    if (_destinos.isEmpty) {
      _destinos.add(DestinoCorrida(ordem: 1));
    }
  }

  void _adicionarDestino() {
    setState(() {
      _destinos.add(DestinoCorrida(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ordem: _destinos.length + 1,
      ));
      widget.onDestinosChanged(_destinos);
    });
  }

  void _removerDestino(int index) {
    if (_destinos.length <= 1) return;
    setState(() {
      _destinos.removeAt(index);
      _atualizarOrdem();
      widget.onDestinosChanged(_destinos);
    });
  }

  void _atualizarOrdem() {
    for (int i = 0; i < _destinos.length; i++) {
      _destinos[i] = _destinos[i].copyWith(ordem: i + 1);
    }
  }

  void _atualizarDestino(int index, DestinoCorrida destino) {
    setState(() {
      _destinos[index] = destino;
      widget.onDestinosChanged(_destinos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.route_rounded, color: Color(0xFFE53935), size: 18),
              const SizedBox(width: 6),
              Text(
                'Paradas de entrega',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        // Lista de destinos (Column simples — ReorderableListView não funciona dentro de dialog)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _destinos.length; i++)
              _DestinoCard(
                key: ValueKey(_destinos[i].id ?? 'destino_$i'),
                destino: _destinos[i],
                index: i,
                isFirst: i == 0,
                isLast: i == _destinos.length - 1,
                total: _destinos.length,
                enabled: widget.enabled,
                onChanged: (d) => _atualizarDestino(i, d),
                onRemoved: () => _removerDestino(i),
              ),
          ],
        ),
        // Botão adicionar parada
        if (widget.enabled) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _adicionarDestino,
              icon: const Icon(Icons.add_location_alt_outlined,
                  color: Color(0xFFE53935), size: 18),
              label: Text(
                '+ Adicionar parada',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFE53935),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE53935)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card individual de destino
// ─────────────────────────────────────────────────────────────────────────────
class _DestinoCard extends StatefulWidget {
  final DestinoCorrida destino;
  final int index;
  final bool isFirst;
  final bool isLast;
  final int total;
  final bool enabled;
  final Function(DestinoCorrida) onChanged;
  final VoidCallback onRemoved;

  const _DestinoCard({
    Key? key,
    required this.destino,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.total,
    required this.enabled,
    required this.onChanged,
    required this.onRemoved,
  }) : super(key: key);

  @override
  State<_DestinoCard> createState() => _DestinoCardState();
}

class _DestinoCardState extends State<_DestinoCard> {
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _obsController = TextEditingController();

  final _enderecoFocus = FocusNode();

  bool _geocodificando = false;
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _enderecoController.text = widget.destino.desEnderecoEntrega ?? '';
    _numeroController.text = widget.destino.desNumeroEndereco ?? '';
    _complementoController.text = widget.destino.desComplemento ?? '';
    _telefoneController.text = widget.destino.desTelefone ?? '';
    _obsController.text = widget.destino.desObsEntrega ?? '';

    // Auto-geocodificação ao sair do campo
    _enderecoFocus.addListener(() {
      if (!_enderecoFocus.hasFocus) {
        _autoGeocodificar();
      }
    });

    // Expandir automaticamente se destino ainda não tem endereço
    _expandido = widget.destino.desEnderecoEntrega?.isEmpty ?? true;
  }

  @override
  void dispose() {
    _enderecoController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _telefoneController.dispose();
    _obsController.dispose();
    _enderecoFocus.dispose();
    super.dispose();
  }

  Future<void> _autoGeocodificar() async {
    final endereco = _enderecoController.text.trim();
    final numero = _numeroController.text.trim();
    if (endereco.isEmpty) return;
    // Já tem coordenadas para esse mesmo endereço? Não refaz
    if (widget.destino.desLatitudeEntrega != null &&
        widget.destino.desEnderecoEntrega == endereco) return;

    if (!mounted) return;
    setState(() => _geocodificando = true);

    try {
      final query = numero.isNotEmpty ? '$endereco, $numero' : endereco;
      final locations = await locationFromAddress(query);
      if (!mounted) return;
      if (locations.isNotEmpty) {
        widget.onChanged(widget.destino.copyWith(
          desEnderecoEntrega: endereco,
          desNumeroEndereco: numero,
          desLatitudeEntrega: locations.first.latitude,
          desLongitudeEntrega: locations.first.longitude,
        ));
      }
    } catch (_) {
      // silencioso — coordenadas são opcionais
    } finally {
      if (mounted) setState(() => _geocodificando = false);
    }
  }

  void _salvar() {
    widget.onChanged(widget.destino.copyWith(
      desEnderecoEntrega: _enderecoController.text.trim(),
      desNumeroEndereco: _numeroController.text.trim(),
      desComplemento: _complementoController.text.trim(),
      desTelefone: _telefoneController.text.trim(),
      desObsEntrega: _obsController.text.trim(),
    ));
  }

  Color get _dotColor =>
      widget.isFirst ? const Color(0xFF43A047) : const Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final temEndereco = _enderecoController.text.isNotEmpty;
    final temCoordenadas = widget.destino.desLatitudeEntrega != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline visual
          Column(
            children: [
              const SizedBox(height: 14),
              // Bolinha
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _dotColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${widget.destino.ordem}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Linha de conexão (exceto último)
              if (!widget.isLast)
                Container(
                  width: 2,
                  height: 48,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_dotColor, const Color(0xFFE53935)],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          // Card do destino
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: temCoordenadas
                      ? const Color(0xFF43A047).withOpacity(0.4)
                      : Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  // Cabeçalho clicável
                  InkWell(
                    onTap: () => setState(() => _expandido = !_expandido),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isFirst ? 'Entrega principal' : 'Parada ${widget.destino.ordem}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  temEndereco
                                      ? _enderecoController.text
                                      : 'Toque para preencher o endereço',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: temEndereco
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.grey.shade400,
                                    fontStyle: temEndereco
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Indicador de coordenadas
                          if (_geocodificando)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE53935),
                              ),
                            )
                          else if (temCoordenadas)
                            const Icon(Icons.check_circle,
                                size: 16, color: Color(0xFF43A047))
                          else if (temEndereco)
                            const Icon(Icons.location_searching,
                                size: 16, color: Colors.orange),
                          if (widget.enabled) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.drag_handle_rounded,
                                color: Colors.grey, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Campos expandidos
                  if (_expandido) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        children: [
                          // Endereço
                          TextFormField(
                            controller: _enderecoController,
                            focusNode: _enderecoFocus,
                            enabled: widget.enabled,
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Endereço *',
                              labelStyle: GoogleFonts.poppins(fontSize: 13),
                              hintText: 'Rua, Avenida, etc.',
                              prefixIcon: const Icon(Icons.location_on_outlined,
                                  size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                            ),
                            onChanged: (_) => _salvar(),
                          ),
                          const SizedBox(height: 8),
                          // Número + Complemento
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _numeroController,
                                  enabled: widget.enabled,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: 'Nº',
                                    labelStyle:
                                        GoogleFonts.poppins(fontSize: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 12),
                                  ),
                                  onChanged: (_) => _salvar(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  controller: _complementoController,
                                  enabled: widget.enabled,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: 'Complemento',
                                    labelStyle:
                                        GoogleFonts.poppins(fontSize: 13),
                                    hintText: 'Apto, Bloco…',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 12),
                                  ),
                                  onChanged: (_) => _salvar(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Telefone
                          TextFormField(
                            controller: _telefoneController,
                            enabled: widget.enabled,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Telefone do destinatário',
                              labelStyle: GoogleFonts.poppins(fontSize: 13),
                              prefixIcon: const Icon(Icons.phone_outlined,
                                  size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                            ),
                            onChanged: (_) => _salvar(),
                          ),
                          const SizedBox(height: 8),
                          // Observações
                          TextFormField(
                            controller: _obsController,
                            enabled: widget.enabled,
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Observação',
                              labelStyle: GoogleFonts.poppins(fontSize: 13),
                              hintText: 'Deixar na portaria, ligar antes…',
                              prefixIcon: const Icon(Icons.note_outlined,
                                  size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                            ),
                            maxLines: 2,
                            onChanged: (_) => _salvar(),
                          ),
                          // Botão remover (destinos extras)
                          if (widget.enabled && widget.total > 1) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: widget.onRemoved,
                                icon: const Icon(Icons.delete_outline,
                                    size: 16, color: Colors.red),
                                label: Text(
                                  'Remover parada',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

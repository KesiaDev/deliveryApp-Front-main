import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delivery_front/shared/models/destino_corrida.dart';
import 'package:geocoding/geocoding.dart';

/// Widget para gerenciar múltiplos destinos em uma corrida
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
  State<MultiplosDestinosWidget> createState() => _MultiplosDestinosWidgetState();
}

class _MultiplosDestinosWidgetState extends State<MultiplosDestinosWidget> {
  late List<DestinoCorrida> _destinos;

  @override
  void initState() {
    super.initState();
    _destinos = List.from(widget.destinos);
    // Se não houver destinos, cria um inicial
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
      _atualizarOrdem();
      widget.onDestinosChanged(_destinos);
    });
  }

  void _removerDestino(int index) {
    if (_destinos.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('É necessário ter pelo menos um destino')),
      );
      return;
    }

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

  void _moverDestino(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _destinos.removeAt(oldIndex);
      _destinos.insert(newIndex, item);
      _atualizarOrdem();
      widget.onDestinosChanged(_destinos);
    });
  }

  void _atualizarDestino(int index, DestinoCorrida destino) {
    setState(() {
      _destinos[index] = destino;
      widget.onDestinosChanged(_destinos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Destinos de Entrega',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              if (widget.enabled)
                TextButton.icon(
                  onPressed: _adicionarDestino,
                  icon: Icon(Icons.add, size: 18, color: Colors.red),
                  label: Text(
                    'Adicionar',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          if (_destinos.length > 1)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A ordem dos destinos define a sequência de entregas',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 12),
          ...List.generate(_destinos.length, (index) {
            return _DestinoItem(
              destino: _destinos[index],
              index: index,
              total: _destinos.length,
              enabled: widget.enabled,
              onChanged: (destino) => _atualizarDestino(index, destino),
              onRemoved: () => _removerDestino(index),
              onMoveUp: index > 0 ? () => _moverDestino(index, index - 1) : null,
              onMoveDown: index < _destinos.length - 1
                  ? () => _moverDestino(index, index + 1)
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

class _DestinoItem extends StatefulWidget {
  final DestinoCorrida destino;
  final int index;
  final int total;
  final bool enabled;
  final Function(DestinoCorrida) onChanged;
  final VoidCallback onRemoved;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _DestinoItem({
    Key? key,
    required this.destino,
    required this.index,
    required this.total,
    required this.enabled,
    required this.onChanged,
    required this.onRemoved,
    this.onMoveUp,
    this.onMoveDown,
  }) : super(key: key);

  @override
  State<_DestinoItem> createState() => _DestinoItemState();
}

class _DestinoItemState extends State<_DestinoItem> {
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();
  bool _buscandoCoordenadas = false;

  @override
  void initState() {
    super.initState();
    _enderecoController.text = widget.destino.desEnderecoEntrega ?? '';
    _numeroController.text = widget.destino.desNumeroEndereco ?? '';
    _complementoController.text = widget.destino.desComplemento ?? '';
    _telefoneController.text = widget.destino.desTelefone ?? '';
    _obsController.text = widget.destino.desObsEntrega ?? '';
  }

  @override
  void dispose() {
    _enderecoController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _telefoneController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _buscarCoordenadas() async {
    final endereco = _enderecoController.text.trim();
    final numero = _numeroController.text.trim();

    if (endereco.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Digite o endereço primeiro')),
      );
      return;
    }

    setState(() {
      _buscandoCoordenadas = true;
    });

    try {
      final enderecoCompleto = numero.isNotEmpty
          ? '$endereco, $numero'
          : endereco;
      
      final locations = await locationFromAddress(enderecoCompleto);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        widget.onChanged(
          widget.destino.copyWith(
            desLatitudeEntrega: location.latitude,
            desLongitudeEntrega: location.longitude,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coordenadas encontradas!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Endereço não encontrado')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar coordenadas: $e')),
      );
    } finally {
      setState(() {
        _buscandoCoordenadas = false;
      });
    }
  }

  void _atualizarDestino() {
    widget.onChanged(
      widget.destino.copyWith(
        desEnderecoEntrega: _enderecoController.text.trim(),
        desNumeroEndereco: _numeroController.text.trim(),
        desComplemento: _complementoController.text.trim(),
        desTelefone: _telefoneController.text.trim(),
        desObsEntrega: _obsController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.destino.isCompleto
              ? Colors.green.withOpacity(0.3)
              : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.destino.ordem}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Destino ${widget.destino.ordem}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.enabled) ...[
                if (widget.onMoveUp != null)
                  IconButton(
                    icon: Icon(Icons.arrow_upward, size: 20),
                    onPressed: widget.onMoveUp,
                    tooltip: 'Mover para cima',
                  ),
                if (widget.onMoveDown != null)
                  IconButton(
                    icon: Icon(Icons.arrow_downward, size: 20),
                    onPressed: widget.onMoveDown,
                    tooltip: 'Mover para baixo',
                  ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: widget.total > 1 ? widget.onRemoved : null,
                  tooltip: 'Remover destino',
                ),
              ],
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _enderecoController,
            enabled: widget.enabled,
            decoration: InputDecoration(
              labelText: 'Endereço *',
              hintText: 'Rua, Avenida, etc.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.location_on),
            ),
            onChanged: (_) => _atualizarDestino(),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _numeroController,
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    labelText: 'Número',
                    hintText: '123',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => _atualizarDestino(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _complementoController,
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    labelText: 'Complemento',
                    hintText: 'Apto, Bloco, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => _atualizarDestino(),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _telefoneController,
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    labelText: 'Telefone',
                    hintText: '(11) 99999-9999',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  onChanged: (_) => _atualizarDestino(),
                ),
              ),
              SizedBox(width: 12),
              if (widget.enabled)
                ElevatedButton.icon(
                  onPressed: _buscandoCoordenadas ? null : _buscarCoordenadas,
                  icon: _buscandoCoordenadas
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.search, size: 18),
                  label: Text('Buscar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
          if (widget.destino.desLatitudeEntrega != null &&
              widget.destino.desLongitudeEntrega != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coordenadas: ${widget.destino.desLatitudeEntrega!.toStringAsFixed(6)}, ${widget.destino.desLongitudeEntrega!.toStringAsFixed(6)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12),
          TextField(
            controller: _obsController,
            enabled: widget.enabled,
            decoration: InputDecoration(
              labelText: 'Observações',
              hintText: 'Informações adicionais sobre este destino',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
            onChanged: (_) => _atualizarDestino(),
          ),
        ],
      ),
    );
  }
}

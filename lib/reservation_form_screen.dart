import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'reservation_model.dart';
import 'database_helper.dart';

/// Tela de Formulário de Reservas (Criação e Edição).
/// Implementa o padrão de interface de entrada de dados com validações.
/// Responsabilidades:
/// 1. Coletar dados do hóspede e da reserva;
/// 2. Validar integridade referencial (datas, quartos ocupados);
/// 3. Construir o objeto [Reservation] e salvar/atualizar no banco via [DatabaseHelper].

class ReservationFormScreen extends StatefulWidget {
  final Reservation? reservation;

  const ReservationFormScreen({super.key, this.reservation});

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Lista dos quartos disponíveis na pousada:
  final List<String> _roomList = [
    'D2',
    'D3',
    'D4',
    'N1 (suite)',
    'N2 (suite)',
    'N3',
    'N4 (suite)',
    'N5 (suite)',
    'N6 (suite)',
    'F1',
    'F2 (suite)',
    'F3 (suite)',
    'F4',
  ];

  /// Lista dinâmica que guarda os quartos indisponíveis (via _checkAvailability):
  List<String> _unavailableRooms = [];

  /// Máscaras de Input.
  var maskCPF = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  var maskPhone = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  /// Controladores (Gerenciamento de Estado dos Campos).
  final _guestNameController = TextEditingController();
  final _guestCPFController = TextEditingController();
  final _guestCityController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _guestsController = TextEditingController();
  final _companionNamesController = TextEditingController();
  final _chargedAmountController = TextEditingController();
  final _paymentDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _checkInDateController = TextEditingController();
  final _checkInTimeController = TextEditingController();
  final _checkOutDateController = TextEditingController();
  final _checkOutTimeController = TextEditingController();

  /// FocusNodes para melhor acessibilidade e navegação em caso de erro.
  final _guestNameFocus = FocusNode();
  final _guestCPFFocus = FocusNode();
  final _guestPhoneFocus = FocusNode();
  final _roomNumberFocus = FocusNode();
  final _guestsFocus = FocusNode();
  final _companionNamesFocus = FocusNode();
  final _checkInDateFocus = FocusNode();
  final _checkOutDateFocus = FocusNode();
  final _chargedAmountFocus = FocusNode();
  final _paymentDateFocus = FocusNode();

  // Estados padrão de certos campos (no formulário).
  String _reservationType = 'daily';
  String _paymentStatus = 'pending';
  String _status = 'scheduled';
  bool _showCompanions = false; // Controla visibilidade do campo de acompanhantes.

  @override
  void initState() {
    super.initState();
    // Se for edição, popula os campos com dados existentes.
    if (widget.reservation != null) {
      final res = widget.reservation!;
      _guestNameController.text = res.guestName;
      _guestCPFController.text = res.guestCPF;
      _guestCityController.text = res.guestCity;
      _guestPhoneController.text = res.guestPhone;

      // Garante que o quarto antigo apareça mesmo se removido da lista fixa (caso a lista mude no futuro).
      _roomNumberController.text = res.roomNumber;

      _guestsController.text = res.guests.toString();
      _companionNamesController.text = res.companionNames ?? '';
      _chargedAmountController.text = res.chargedAmount.toStringAsFixed(2);
      _paymentDateController.text = res.paymentDate ?? '';
      _notesController.text = res.notes ?? '';
      _checkInDateController.text = res.checkInDate;
      _checkInTimeController.text = res.checkInTime;
      _checkOutDateController.text = res.checkOutDate;
      _checkOutTimeController.text = res.checkOutTime;
      _reservationType = res.reservationType;
      _paymentStatus = res.paymentStatus;
      _status = res.status;

      /// Condição necessária para que o campo de acompanhantes mostre-se.
      if (res.guests > 1) _showCompanions = true;

    /// Validação inicial de disponibilidade.
      _checkAvailability();
    } else {
      _guestsController.text = "1";
    }
  }

  @override
  void dispose() {
    /// Liberação de recursos para evitar vazamento de memória.
    _guestNameController.dispose();
    _guestCPFController.dispose();
    _guestCityController.dispose();
    _guestPhoneController.dispose();
    _roomNumberController.dispose();
    _guestsController.dispose();
    _companionNamesController.dispose();
    _chargedAmountController.dispose();
    _paymentDateController.dispose();
    _notesController.dispose();
    _checkInDateController.dispose();
    _checkInTimeController.dispose();
    _checkOutDateController.dispose();
    _checkOutTimeController.dispose();
    _guestNameFocus.dispose();
    _guestCPFFocus.dispose();
    _guestPhoneFocus.dispose();
    _roomNumberFocus.dispose();
    _guestsFocus.dispose();
    _companionNamesFocus.dispose();
    _checkInDateFocus.dispose();
    _checkOutDateFocus.dispose();
    _chargedAmountFocus.dispose();
    _paymentDateFocus.dispose();
    super.dispose();
  }

  /// Algoritmo de detecção de conflito de datas.
  /// Popula [_unavailableRooms] com quartos que já possuem reserva "pendente" ou "check-in" no intervalo de datas selecionado.
  /// Substitua a função _checkAvailability existente por esta versão.
  Future<void> _checkAvailability() async {
    // Se não houver data de check-in E check-out preenchidas, não valida ainda.
    if (_checkInDateController.text.isEmpty || _checkOutDateController.text.isEmpty) return;

    try {
      // Constrói intervalos da nova reserva (usando times se existirem, senão defaults pelo tipo)
      DateTime newStart = _buildDateTime(
        dateString: _checkInDateController.text,
        timeString: _checkInTimeController.text,
        reservationType: _reservationType,
        isStart: true,
        fallbackIsCheckOutDate: false,
      );
      DateTime newEnd = _buildDateTime(
        dateString: _checkOutDateController.text,
        timeString: _checkOutTimeController.text,
        reservationType: _reservationType,
        isStart: false,
        // para overnight, se checkOut == checkIn e não houver time, precisa ir para o dia seguinte 08:00
        fallbackIsCheckOutDate: true,
      );

      // Se por alguma razão newEnd <= newStart, garante que seja posterior (assume atravessou meia-noite)
      if (!newEnd.isAfter(newStart)) {
        newEnd = newEnd.add(const Duration(days: 1));
      }

      // Busca todas as reservas
      List<Reservation> allReservations = await DatabaseHelper.instance.readAllReservations();

      List<String> busyRooms = [];

      for (var res in allReservations) {
        // Ignora a própria reserva quando estivermos editando
        if (widget.reservation != null && res.id == widget.reservation!.id) continue;

        if (res.status == 'scheduled' || res.status == 'checked-in') {
          try {
            // Constrói intervalo da reserva existente (usando os campos salvos nela)
            DateTime existingStart = _buildDateTime(
              dateString: res.checkInDate,
              timeString: res.checkInTime,
              reservationType: res.reservationType,
              isStart: true,
              fallbackIsCheckOutDate: false,
            );
            DateTime existingEnd = _buildDateTime(
              dateString: res.checkOutDate,
              timeString: res.checkOutTime,
              reservationType: res.reservationType,
              isStart: false,
              fallbackIsCheckOutDate: true,
            );

            if (!existingEnd.isAfter(existingStart)) {
              existingEnd = existingEnd.add(const Duration(days: 1));
            }

            // Verifica interseção (overlap)
            bool overlap = newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart);
            if (overlap) {
              busyRooms.add(res.roomNumber);
            }
          } catch (e) {
            // Se alguma reserva tiver dados estranhos, ignora ela (não bloqueia toda a checagem)
            debugPrint('Ignorando reserva com data/hora inválida: ${res.id} -> $e');
          }
        }
      }

      setState(() {
        _unavailableRooms = busyRooms;
      });
    } catch (e) {
      debugPrint("Erro ao checar disponibilidade: $e");
    }
  }

  /// Helper que tenta montar um DateTime do dateString + timeString.
  /// - isStart: se true, monta o início; se false, o fim
  /// - fallbackIsCheckOutDate: se true, quando for overnight e checkOut == checkIn sem hora, ajusta fim para o dia seguinte 08:00
  DateTime _buildDateTime({
    required String dateString,
    required String timeString,
    required String reservationType,
    required bool isStart,
    required bool fallbackIsCheckOutDate,
  }) {
    // parse data base (yyyy-MM-dd)
    final DateTime baseDate = DateTime.parse(dateString);

    // tenta parse do timeString em 'HH:mm' (24h). Se falhar, usa defaults por tipo.
    int hour = -1;
    int minute = 0;
    if (timeString.trim().isNotEmpty) {
      try {
        // limpa espaços e tenta 'HH:mm'
        final parts = timeString.trim().split(':');
        if (parts.length >= 1) {
          hour = int.parse(parts[0]);
          if (parts.length >= 2) minute = int.parse(parts[1]);
        }
      } catch (_) {
        // fallback: ignore timeString e use default abaixo
        hour = -1;
      }
    }

    // Se usuário forneceu hora válida, retorna combinação direta
    if (hour >= 0) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    }

    // Sem hora fornecida, usa defaults segundo reservationType e se estamos construindo start/end:
    switch (reservationType) {
      case 'rest':
      // Rest: 07:00 - 17:00 (por dia)
        if (isStart) {
          return DateTime(baseDate.year, baseDate.month, baseDate.day, 7, 0);
        } else {
          // fim no dia de checkOut às 17:00
          return DateTime(baseDate.year, baseDate.month, baseDate.day, 17, 0);
        }
      case 'overnight':
      // Overnight: 20:00 do dia de checkin -> 08:00 do dia seguinte (ou do checkOut)
        if (isStart) {
          return DateTime(baseDate.year, baseDate.month, baseDate.day, 20, 0);
        } else {
          // Se fallbackIsCheckOutDate true e checkOut == checkIn, assume 08:00 do dia seguinte
          // Aqui baseDate é a checkOutDate passada para a função. Se checkOutDate == checkInDate,
          // deve-se retornar 08:00 do próximo dia (adiciona 1 dia).
          DateTime candidate = DateTime(baseDate.year, baseDate.month, baseDate.day, 8, 0);
          if (fallbackIsCheckOutDate) {
            // se o fim ficou igual ou anterior ao start por ausência de times, empurra 1 dia.
            return candidate;
          }
          return candidate;
        }
      case 'daily':
      default:
      // Daily: ocupa o(s) dias inteiros — start = 00:00 do checkIn, end = 23:59:59 do checkOut
        if (isStart) {
          return DateTime(baseDate.year, baseDate.month, baseDate.day, 0, 0);
        } else {
          return DateTime(baseDate.year, baseDate.month, baseDate.day, 23, 59, 59);
        }
    }
  }

  /// Função que abre o DatePicker e atualiza o controller:
  /// Inclui validação lógica (Check-out deve ser após Check-in).
  Future<void> _selectDate(TextEditingController controller, {bool isCheckOut = false}) async {
    DateTime initial = DateTime.now();
    try {
      if (controller.text.isNotEmpty) {
        initial = DateTime.parse(controller.text);
      }
    } catch (_) {}

    DateTime? picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2024), lastDate: DateTime(2030));

    if (!mounted) return; // Segurança contra chamadas assíncronas em widget desmontado.

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });

      // Se for check-out, valida na hora se existe check-in e se é posterior/igual.
      if (isCheckOut && _checkInDateController.text.isNotEmpty) {
        try {
          final dtIn = DateTime.parse(_checkInDateController.text);
          final dtOut = DateTime.parse(_checkOutDateController.text);
          if (dtOut.isBefore(dtIn)) {
            // mostra erro e limpa o campo recém-preenchido.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data de check-out não pode ser anterior à data de check-in.'), backgroundColor: Colors.red),
            );
            setState(() {
              _checkOutDateController.text = '';
            });
          }
        } catch (_) {
        }
      }

      // Se não for check-out (ou se for check-in) e já houver check-out preenchido, valida a consistência.
      if (!isCheckOut && _checkOutDateController.text.isNotEmpty) {
        try {
          final dtIn = DateTime.parse(_checkInDateController.text);
          final dtOut = DateTime.parse(_checkOutDateController.text);
          if (dtOut.isBefore(dtIn)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data de check-out não pode ser anterior à data de check-in.'), backgroundColor: Colors.red),
            );

            setState(() {
              _checkOutDateController.text = '';
            });
          }
        } catch (_) {}
      }

      // Sempre que mudar a data, verifica a disponibilidade novamente.
      await _checkAvailability();
    }
  }

  /// Função para abrir um seletor de tempo e atualizar o TextEditingController.
  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        final localizations = MaterialLocalizations.of(context);
        controller.text = localizations.formatTimeOfDay(picked, alwaysUse24HourFormat: true);
      });
    }
  }

  // Recolhe erros para mostrar no AlertDialog.
  List<String> _collectFieldErrors() {
    final errors = <String>[];

    // Nome do hóspede principal:
    if (_guestNameController.text.trim().isEmpty) errors.add('Nome do hóspede é obrigatório.');

    // CPF:
    if (_guestCPFController.text.trim().isEmpty) {
      errors.add('CPF é obrigatório.');
    } else if (_guestCPFController.text.trim().length < 14) {
      errors.add('CPF incompleto.');
    }

    // Telefone:
    if (_guestPhoneController.text.trim().isEmpty) {
      errors.add('Telefone é obrigatório.');
    } else if (_guestPhoneController.text.trim().length < 15) {
      errors.add('Telefone incompleto.');
    }

    // Quarto:
    if (_roomNumberController.text.trim().isEmpty) errors.add('Quarto é obrigatório.');

    // Verifica se o quarto escolhido está na lista de indisponíveis.
    if (_unavailableRooms.contains(_roomNumberController.text)) {
      errors.add('O quarto ${_roomNumberController.text} está ocupado nestas datas.');
    }

    // Número de Hóspedes e nome dos acompanhantes:
    if (_guestsController.text.trim().isEmpty) {
      errors.add('Quantidade de hóspedes é obrigatória.');
    } else {
      final guestCount = int.tryParse(_guestsController.text) ?? 0;
      if (guestCount < 1) {
        errors.add('O número mínimo de hóspedes é 1.');
      } else {
        if (guestCount > 1 && _companionNamesController.text.trim().isEmpty) {
          errors.add('Informe os nomes dos acompanhantes.');
        }
      }
    }

    // Datas:
    if (_checkInDateController.text.trim().isEmpty) {
      errors.add('Data de check-in é obrigatória.');
    }
    if (_checkOutDateController.text.trim().isEmpty) {
      errors.add('Data de check-out é obrigatória.');
    }
    if (_checkInDateController.text.trim().isNotEmpty && _checkOutDateController.text.trim().isNotEmpty) {
      try {
        final dtIn = DateTime.parse(_checkInDateController.text.trim());
        final dtOut = DateTime.parse(_checkOutDateController.text.trim());
        if (dtOut.isBefore(dtIn)) {
          errors.add('Data de check-out não pode ser anterior à data de check-in.');
        }
      } catch (_) {
        errors.add('Formato de data inválido (use aaaa-mm-dd).');
      }
    }

    // Valor :
    if (_chargedAmountController.text.trim().isEmpty) {
      errors.add('Valor cobrado é obrigatório.');
    }

    /// Condição necessária para status da reserva ser "check-out" e para o status do pagamento ser "Pago":
    if (_status == 'checked-out' && _paymentStatus != 'paid') {
      errors.add('Só é possível fazer check-out após o pagamento.');
    }
    if (_paymentStatus == 'paid' && _paymentDateController.text.trim().isEmpty) {
      errors.add('Data do pagamento é obrigatória quando o status for Pago.');
    }

    // Mais uma condição necessária para status da reserva ser "check-out" e para status da reserva ser "check-in":
    if (_status == 'checked-in' && _checkInTimeController.text.trim().isEmpty) {
      errors.add('Horário de check-in obrigatório quando status = Check-in.');
    }
    if (_status == 'checked-out' && _checkOutTimeController.text.trim().isEmpty) {
      errors.add('Horário de check-out obrigatório quando status = Check-out.');
    }

    return errors;
  }

  /// Lógica para focar no campo errado e abrir o teclado/dropdown
  void _focusFirstInvalidField() {
    if (_guestNameController.text.trim().isEmpty) {
      _guestNameFocus.requestFocus();
      return;
    }
    if (_guestCPFController.text.trim().isEmpty || _guestCPFController.text.trim().length < 14) {
      _guestCPFFocus.requestFocus();
      return;
    }
    if (_guestPhoneController.text.trim().isEmpty || _guestPhoneController.text.trim().length < 15) {
      _guestPhoneFocus.requestFocus();
      return;
    }
    if (_roomNumberController.text.trim().isEmpty) {
      _roomNumberFocus.requestFocus();
      return;
    }
    if (_guestsController.text.trim().isEmpty) {
      _guestsFocus.requestFocus();
      return;
    }
    final guestCount = int.tryParse(_guestsController.text) ?? 1;
    if (guestCount > 1 && _companionNamesController.text.trim().isEmpty) {
      _companionNamesFocus.requestFocus();
      return;
    }
    if (_checkInDateController.text.trim().isEmpty) {
      _checkInDateFocus.requestFocus();
      return;
    }
    if (_checkOutDateController.text.trim().isEmpty) {
      _checkOutDateFocus.requestFocus();
      return;
    }
    if (_chargedAmountController.text.trim().isEmpty) {
      _chargedAmountFocus.requestFocus();
      return;
    }
  }

  /// Função para salvar a reserva:
  Future<void> _saveReservation() async {
    await _checkAvailability(); // Última checagem de segurança antes de salvar
    final isValidForm = _formKey.currentState!.validate(); // Executa os validators inline do Form
    final errors = _collectFieldErrors(); // Recolhe erros detalhados

    if (!isValidForm || errors.isNotEmpty) {
      // Mostra diálogo com a lista de erros
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Corrigir campos'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: errors.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text('• $e'))).toList(),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );

      // foca o primeiro campo inválido
      _focusFirstInvalidField();
      return;
    }

    /// Função interna para formatar TimeOfDay
    String formatTimeOfDayInternal(TimeOfDay t) {
      final localizations = MaterialLocalizations.of(context);
      return localizations.formatTimeOfDay(t, alwaysUse24HourFormat: true);
    }

    /// Tratamento de Horários (Pergunta ao usuário se faltar, quando clicado no botão de ação)
    Future<bool> askAndFillTime(TextEditingController controller, String label) async {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$label obrigatório'),
          content: Text('A reserva não possui o $label. Deseja escolher um horário, usar o horário atual ou cancelar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'choose'), child: const Text('Escolher horário')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'now'), child: const Text('Usar agora')),
          ],
        ),
      );

      if (!mounted) return false;

      if (choice == null || choice == 'cancel') return false;

      if (choice == 'now') {
        final now = TimeOfDay.fromDateTime(DateTime.now());
        controller.text = formatTimeOfDayInternal(now);
        return true;
      }

      if (choice == 'choose') {
        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (picked == null) return false;
        controller.text = formatTimeOfDayInternal(picked);
        return true;
      }
      return false;
    }

    bool needsCheckInTime = _status == 'checked-in' && _checkInTimeController.text.trim().isEmpty;
    bool needsCheckOutTime = _status == 'checked-out' && _checkOutTimeController.text.trim().isEmpty;

    if (needsCheckInTime) {
      final ok = await askAndFillTime(_checkInTimeController, 'Horário Check-in');
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salvamento cancelado: horário de check-in obrigatório.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (needsCheckOutTime) {
      final ok = await askAndFillTime(_checkOutTimeController, 'Horário Check-out');
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salvamento cancelado: horário de check-out obrigatório.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    /// Conversão segura de valores monetários (tratamento de vírgula e ponto):
    String valorString = _chargedAmountController.text.replaceAll(',', '.');
    double valorFinal = double.tryParse(valorString) ?? 0.0;

    final reservation = Reservation(
      id: widget.reservation?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      reservationType: _reservationType,
      guestName: _guestNameController.text.trim(),
      guestCPF: _guestCPFController.text.trim(),
      guestCity: _guestCityController.text.trim(),
      guestPhone: _guestPhoneController.text.trim(),
      roomNumber: _roomNumberController.text.trim(),
      checkInDate: _checkInDateController.text.trim(),
      checkInTime: _checkInTimeController.text.trim(),
      checkOutDate: _checkOutDateController.text.trim(),
      checkOutTime: _checkOutTimeController.text.trim(),
      chargedAmount: valorFinal,
      paymentStatus: _paymentStatus,
      status: _status,
      guests: int.tryParse(_guestsController.text) ?? 1,
      notes: _notesController.text.trim(),
      companionNames: _companionNamesController.text.trim(),
      paymentDate: _paymentDateController.text.trim(),
    );

    try {
      if (widget.reservation == null) {
        await DatabaseHelper.instance.create(reservation);
      } else {
        await DatabaseHelper.instance.update(reservation);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  /// Widgets Auxiliares de UI
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 10),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputStyle(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      suffixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reservation == null ? 'Nova Reserva' : 'Editar Reserva',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Tipo de Reserva *'),
                DropdownButtonFormField<String>(
                  initialValue: _reservationType,
                  decoration: _inputStyle(''),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Diária (24h)')),
                    DropdownMenuItem(value: 'overnight', child: Text('Pernoite (20h-08h)')),
                    DropdownMenuItem(value: 'rest', child: Text('Descanso (07h-17h)')),
                  ],
                  onChanged: (v) => setState(() => _reservationType = v!),
                ),

                _buildLabel('Hóspede Principal *'),
                TextFormField(
                  controller: _guestNameController,
                  focusNode: _guestNameFocus,
                  decoration: _inputStyle('Ex: Alfred Pennyworth'),
                  validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                ),

                _buildLabel('CPF *'),
                TextFormField(
                  controller: _guestCPFController,
                  focusNode: _guestCPFFocus,
                  inputFormatters: [maskCPF],
                  decoration: _inputStyle('XXX.XXX.XXX-XX'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    if (v.length < 14) return 'CPF incompleto';
                    return null;
                  },
                ),

                _buildLabel('Cidade de Origem'),
                TextFormField(controller: _guestCityController, decoration: _inputStyle('Ex: Cidade de Góias')),

                _buildLabel('Telefone *'),
                TextFormField(
                  controller: _guestPhoneController,
                  focusNode: _guestPhoneFocus,
                  inputFormatters: [maskPhone],
                  decoration: _inputStyle('(XX) 9XXXX-XXXX'),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    if (v.length < 15) return 'Telefone incompleto';
                    return null;
                  },
                ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Check-in *'),
                          TextFormField(
                            controller: _checkInDateController,
                            focusNode: _checkInDateFocus,
                            decoration: _inputStyle('aaaa-mm-dd', icon: Icons.calendar_today),
                            readOnly: true,
                            onTap: () => _selectDate(_checkInDateController, isCheckOut: false),
                            validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Check-out *'),
                          TextFormField(
                            controller: _checkOutDateController,
                            focusNode: _checkOutDateFocus,
                            decoration: _inputStyle('aaaa-mm-dd', icon: Icons.calendar_today),
                            readOnly: true,
                            onTap: () => _selectDate(_checkOutDateController, isCheckOut: true),
                            validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Horário Check-in'),
                          TextFormField(
                            controller: _checkInTimeController,
                            decoration: _inputStyle('Insira a hora', icon: Icons.access_time),
                            readOnly: true,
                            onTap: () => _selectTime(_checkInTimeController),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Horário Check-out'),
                          TextFormField(
                            controller: _checkOutTimeController,
                            decoration: _inputStyle('Insira a hora', icon: Icons.access_time),
                            readOnly: true,
                            onTap: () => _selectTime(_checkOutTimeController),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Quarto *'),
                          DropdownButtonFormField<String>(
                            initialValue: _roomList.contains(_roomNumberController.text) ? _roomNumberController.text : null,
                            decoration: _inputStyle('Selecione'),
                            focusNode: _roomNumberFocus,
                            items: _roomList.map((room) {
                              bool isTaken = _unavailableRooms.contains(room);
                              bool isCurrentRoom = widget.reservation != null && widget.reservation!.roomNumber == room;
                              bool isDisabled = isTaken && !isCurrentRoom;
                              return DropdownMenuItem(
                                value: room,
                                enabled: !isDisabled,
                                child: Text(
                                  isDisabled ? '$room (Ocupado)' : room,
                                  style: TextStyle(
                                    color: isDisabled ? Colors.grey : Colors.black87,
                                    decoration: isDisabled ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _roomNumberController.text = val;
                                });
                              }
                            },
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Obrigatório';
                              if (_unavailableRooms.contains(v) && (widget.reservation?.roomNumber != v)) {
                                return 'Quarto Ocupado!';
                              }
                              return null;
                            },
                            onTap: () {
                              if (_checkInDateController.text.isEmpty || _checkOutDateController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Selecione as datas primeiro para ver a disponibilidade real.')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Hóspedes *'),
                          TextFormField(
                            controller: _guestsController,
                            focusNode: _guestsFocus,
                            decoration: _inputStyle('Qtd'),
                            keyboardType: TextInputType.number,
                            /// Lógica para mostrar/esconder campo de acompanhantes
                            onChanged: (value) {
                              setState(() {
                                int count = int.tryParse(value) ?? 1;
                                // mostra campo de acompanhantes somente se > 1
                                _showCompanions = count > 1;
                                // se menor que 2, limpa os nomes dos acompanhantes imediatamente
                                if (count < 2) {
                                  _companionNamesController.text = '';
                                }
                              });
                            },
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Obrigatório';
                              final parsed = int.tryParse(v);
                              if (parsed == null) return 'Número inválido';
                              if (parsed < 1) return 'Mínimo 1 hóspede';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (_showCompanions) ...[
                  _buildLabel('Nome dos Acompanhantes *'),
                  TextFormField(
                    controller: _companionNamesController,
                    focusNode: _companionNamesFocus,
                    decoration: _inputStyle('Ex: João Silva, Maria Costa...'),
                    validator: (v) {
                      final guestCount = int.tryParse(_guestsController.text) ?? 1;
                      if (guestCount > 1 && (v == null || v.trim().isEmpty)) return 'Obrigatório';
                      return null;
                    },
                  ),
                ],

                _buildLabel('Valor Cobrado *'),
                TextFormField(
                  controller: _chargedAmountController,
                  focusNode: _chargedAmountFocus,
                  decoration: _inputStyle('0,00'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                ),

                _buildLabel('Status do Pagamento *'),
                DropdownButtonFormField<String>(
                  initialValue: _paymentStatus,
                  decoration: _inputStyle(''),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pendente')),
                    DropdownMenuItem(value: 'paid', child: Text('Pago')),
                  ],
                  onChanged: (v) => setState(() => _paymentStatus = v!),
                ),
                if (_paymentStatus == 'paid') ...[
                  _buildLabel('Data do Pagamento *'),
                  TextFormField(
                    controller: _paymentDateController,
                    focusNode: _paymentDateFocus,
                    decoration: _inputStyle('aaaa-mm-dd', icon: Icons.calendar_today),
                    readOnly: true,
                    onTap: () => _selectDate(_paymentDateController, isCheckOut: false),
                    validator: (v) {
                      if (_paymentStatus == 'paid' && (v == null || v.isEmpty)) {
                        return 'Obrigatório';
                      }
                      return null;
                    },
                  ),
                ],

                _buildLabel('Status da Reserva *'),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: _inputStyle(''),
                  items: const [
                    DropdownMenuItem(value: 'scheduled', child: Text('Agendada')),
                    DropdownMenuItem(value: 'checked-in', child: Text('Check-in Feito')),
                    DropdownMenuItem(value: 'checked-out', child: Text('Check-out Feito')),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),

                _buildLabel('Observações'),
                TextFormField(controller: _notesController, decoration: _inputStyle('Ex: Pegou 4 cobertas...'), maxLines: 3),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveReservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF030213),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('SALVAR', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
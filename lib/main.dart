import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'reservation_model.dart';
import 'database_helper.dart';
import 'reservation_form_screen.dart';
import 'splash_screen.dart';

/// Arquivo principal da aplicação Pousada Acalanto.
/// Contém:
/// - Configuração do `MaterialApp` e tema global;
/// - `HomePage` com listagem, filtros por status, ações (check-in, check-out, editar, excluir);
/// - Funções de cálculo de faturamento e atualização de status.

void main() {
  runApp(const MyApp());
}

/// Define o tema global e a rota inicial (SplashScreen):
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pousada Acalanto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF030213)),
        useMaterial3: true,
        // Define o estilo padrão dos Cards para toda a aplicação
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    // Controlador para as abas (Todas, Pendente, Check-in, Check-out)
    with
        SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Reservation> reservations = [];
  bool isLoading = true;

  // Variáveis para a pesquisa
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    refreshReservations();
  }

  // Liberação de recursos
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Função que busca as reservas no banco de dados local e atualiza a tela:
  Future refreshReservations() async {
    setState(() => isLoading = true);
    reservations = await DatabaseHelper.instance.readAllReservations();
    setState(() => isLoading = false);
  }

  /// Função que calcula e exibe o faturamento mensal:
  /// Exibe um diálogo com o faturamento mensal, permitindo alterar mês/ano.
  void _showMonthlyRevenue() {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    final yearController = TextEditingController(text: selectedYear.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        // StatefulBuilder permite atualizar o estado APENAS dentro do Dialog
        return StatefulBuilder(
          builder: (context, setState) {
            double total = 0.0;
            int count = 0;
            // Atualiza o ano baseado no input, se for inválido usa 0
            int calcYear = int.tryParse(yearController.text) ?? 0;

            // Filtra e soma reservas pagas no mês/ano selecionado
            for (var res in reservations) {
              try {
                if (res.paymentStatus == 'paid' && res.paymentDate != null && res.paymentDate!.isNotEmpty) {
                  DateTime payDate = DateTime.parse(res.paymentDate!);

                  if (payDate.month == selectedMonth && payDate.year == calcYear) {
                    total += res.chargedAmount;
                    count++;
                  }
                }
              } catch (e) {
                // Ignora erro de parse
              }
            }

            /// Configuração do Dropdown
            final List<Map<String, dynamic>> months = [
              {'val': 1, 'label': 'Janeiro'},
              {'val': 2, 'label': 'Fevereiro'},
              {'val': 3, 'label': 'Março'},
              {'val': 4, 'label': 'Abril'},
              {'val': 5, 'label': 'Maio'},
              {'val': 6, 'label': 'Junho'},
              {'val': 7, 'label': 'Julho'},
              {'val': 8, 'label': 'Agosto'},
              {'val': 9, 'label': 'Setembro'},
              {'val': 10, 'label': 'Outubro'},
              {'val': 11, 'label': 'Novembro'},
              {'val': 12, 'label': 'Dezembro'},
            ];

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.monetization_on, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text('Faturamento', style: TextStyle(fontSize: 20)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selecione o período:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Dropdown Mês
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: selectedMonth,
                                isExpanded: true,
                                items: months.map((m) {
                                  return DropdownMenuItem<int>(value: m['val'], child: Text(m['label']));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => selectedMonth = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Input Ano
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: yearController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              hintText: 'Ano',
                            ),
                            onChanged: (val) {
                              setState(() {}); // Recalcula ao digitar
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),

                    Center(
                      child: Text(
                        'R\$ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF030213)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text('$count pagamentos encontrados.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ),
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
            );
          },
        );
      },
    );
  }

  /// Função que atualiza status (verificações, coleta de horário e pagamento quando necessário):
  Future<void> _updateReservationStatus(Reservation res, String newStatus) async {
    String formatTimeOfDay(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    /// Verifica se o novo status requer horário e/ou pagamento/data do pagamento:
    bool needsCheckInTime = newStatus == 'checked-in' && (res.checkInTime.trim().isEmpty);
    bool needsCheckOutTime = newStatus == 'checked-out' && (res.checkOutTime.trim().isEmpty);

    /// Condição: Para check-out exige pagamento e data de pagamento
    bool requiresPaidForCheckout =
        newStatus == 'checked-out' && (res.paymentStatus != 'paid' || res.paymentDate == null || res.paymentDate!.trim().isEmpty);

    /// Condição: Se for check-out e pagamento não está quitado e falta data, mostra opções:
    if (requiresPaidForCheckout) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pagamento pendente e sem data'),
          content: const Text(
            'O pagamento não está registrado e falta a data do pagamento. Deseja marcar como pago e escolher data, editar a reserva ou cancelar?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'edit'), child: const Text('Editar')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'mark_paid_date'), child: const Text('Marcar como Pago e escolher data')),
          ],
        ),
      );

      if (choice == null || choice == 'cancel') {
        return;
      } else if (choice == 'edit') {
        // Abre formulário para editar (o usuário pode marcar como pago e definir a data)
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => ReservationFormScreen(reservation: res)));
        await refreshReservations();
        return;
      } else if (choice == 'mark_paid_date') {
        if (!mounted) return;
        // Abre date picker para escolher a data do pagamento
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );

        if (picked == null) return; // usuário cancelou
        final paymentDateStr = DateFormat('yyyy-MM-dd').format(picked);

        // Atualiza a reserva com paymentStatus = 'paid' e paymentDate preenchida
        res = Reservation(
          id: res.id,
          reservationType: res.reservationType,
          guestName: res.guestName,
          guestCPF: res.guestCPF,
          guestCity: res.guestCity,
          guestPhone: res.guestPhone,
          roomNumber: res.roomNumber,
          checkInDate: res.checkInDate,
          checkInTime: res.checkInTime,
          checkOutDate: res.checkOutDate,
          checkOutTime: res.checkOutTime,
          chargedAmount: res.chargedAmount,
          paymentStatus: 'paid',
          paymentDate: paymentDateStr,
          status: res.status,
          guests: res.guests,
          notes: res.notes,
          companionNames: res.companionNames,
        );
        await DatabaseHelper.instance.update(res);
        await refreshReservations();
        // Continua o fluxo (agora paymentStatus == 'paid' e paymentDate existe)
        requiresPaidForCheckout = false;
      }
    }

    /// Fluxo de tratamento de horários faltantes
    if (needsCheckInTime || needsCheckOutTime) {
      final missing = needsCheckInTime ? 'Horário de check-in' : 'Horário de check-out';
      if (!mounted) return;

      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$missing obrigatório'),
          content: Text('A reserva não possui o $missing. Deseja usar o horário atual, escolher um horário, editar a reserva ou cancelar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'edit'), child: const Text('Editar')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'choose'), child: const Text('Escolher horário')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'now'), child: const Text('Usar agora')),
          ],
        ),
      );

      if (choice == null || choice == 'cancel') return;
      if (!mounted) return;

      if (choice == 'edit') {
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => ReservationFormScreen(reservation: res)));
        await refreshReservations();
        return;
      }

      String? newCheckInTime = res.checkInTime;
      String? newCheckOutTime = res.checkOutTime;

      if (choice == 'now') {
        final now = DateTime.now();
        final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        if (needsCheckInTime) newCheckInTime = timeStr;
        if (needsCheckOutTime) newCheckOutTime = timeStr;
      } else if (choice == 'choose') {
        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (picked == null) return; // usuário cancelou
        final pickedStr = formatTimeOfDay(picked);
        if (needsCheckInTime) newCheckInTime = pickedStr;
        if (needsCheckOutTime) newCheckOutTime = pickedStr;
      }

      if (!mounted) return;
      // Se por algum motivo ainda estiver faltando, aborta
      if ((needsCheckInTime && (newCheckInTime.trim().isEmpty)) || (needsCheckOutTime && (newCheckOutTime.trim().isEmpty))) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Operação abortada: horário obrigatório.'), backgroundColor: Colors.red));
        return;
      }

      // Atualiza a reserva local com os novos horários antes de aplicar o novo status
      res = Reservation(
        id: res.id,
        reservationType: res.reservationType,
        guestName: res.guestName,
        guestCPF: res.guestCPF,
        guestCity: res.guestCity,
        guestPhone: res.guestPhone,
        roomNumber: res.roomNumber,
        checkInDate: res.checkInDate,
        checkInTime: newCheckInTime,
        checkOutDate: res.checkOutDate,
        checkOutTime: newCheckOutTime,
        chargedAmount: res.chargedAmount,
        paymentStatus: res.paymentStatus,
        paymentDate: res.paymentDate,
        status: res.status,
        guests: res.guests,
        notes: res.notes,
        companionNames: res.companionNames,
      );

      await DatabaseHelper.instance.update(res);
      await refreshReservations();
    }

    // Se passou por todas as validações, cria o objeto atualizado com o novo status
    final updatedRes = Reservation(
      id: res.id,
      reservationType: res.reservationType,
      guestName: res.guestName,
      guestCPF: res.guestCPF,
      guestCity: res.guestCity,
      guestPhone: res.guestPhone,
      roomNumber: res.roomNumber,
      checkInDate: res.checkInDate,
      checkInTime: res.checkInTime,
      checkOutDate: res.checkOutDate,
      checkOutTime: res.checkOutTime,
      chargedAmount: res.chargedAmount,
      paymentStatus: res.paymentStatus,
      paymentDate: res.paymentDate,
      status: newStatus,
      guests: res.guests,
      notes: res.notes,
      companionNames: res.companionNames,
    );

    await DatabaseHelper.instance.update(updatedRes);
    await refreshReservations();

    if (!mounted) return;

    String message = newStatus == 'checked-in' ? 'Check-in realizado!' : 'Check-out realizado!';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 2)));
  }

  /// Função para deletar reserva:
  Future<void> _deleteReservation(String id) async {
    await DatabaseHelper.instance.delete(id);
    refreshReservations();
  }

  ///Mostra lista de todas as reservas,com opções de filtro (status/texto):
  List<Reservation> getFilteredReservations(String filterStatus) {
    List<Reservation> list;
    /// Filtro por Status
    if (filterStatus == 'all') {
      list = reservations;
    } else {
      list = reservations.where((res) => res.status == filterStatus).toList();
    }

    /// Filtro por Texto:
    if (_searchText.isNotEmpty) {
      String searchLower = _searchText.toLowerCase();
      list = list.where((res) {
        bool matchesCommon =
            res.guestName.toLowerCase().contains(searchLower) ||
                res.guestCPF.contains(searchLower) ||
                res.roomNumber.toLowerCase().contains(searchLower) ||
                res.guestCity.toLowerCase().contains(searchLower) ||
                res.reservationType.toLowerCase().contains(searchLower) ||
                res.guestPhone.contains(searchLower) ||
                (res.notes ?? '').toLowerCase().contains(searchLower) ||
                (res.companionNames ?? '').toLowerCase().contains(searchLower);

        // descanso = rest
        bool matchesDescanso = searchLower.contains("descanso") &&
            res.reservationType.toLowerCase() == "rest";

        // pernoite = overnight
        bool matchesPernoite = searchLower.contains("pernoite") &&
            res.reservationType.toLowerCase() == "overnight";

        // diária / diaria = daily
        bool matchesDiaria =
            (searchLower.contains("diária") || searchLower.contains("diaria")) &&
                res.reservationType.toLowerCase() == "daily";

        // pago = paid
        bool matchesPago = searchLower.contains("pago") &&
            res.paymentStatus.toLowerCase() == "paid";

        // pendente = pending
        bool matchesNaoPago =
            (searchLower.contains("pendente")) &&
            res.paymentStatus.toLowerCase() == "pending";


        return matchesCommon || matchesDescanso || matchesPernoite || matchesDiaria || matchesPago || matchesNaoPago;
      }).toList();
    }
    return list;
  }

  @override
  /// Cabeçalho e filtros
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pousada Acalanto',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ReservationFormScreen()));
                refreshReservations();
              },
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('Nova Reserva', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF030213),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
        /// Barra de pesquisa e abas (tabs)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Barra de pesquisa
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar por nome, quarto, telefone,...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                  ),
                ),
              ),
              // Abas (tabs)
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF030213),
                  indicatorSize: TabBarIndicatorSize.label,
                  isScrollable: false,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                  tabs: const [
                    Tab(text: 'Todas'),
                    Tab(text: 'Agendada'),
                    Tab(text: 'Check-in'),
                    Tab(text: 'Check-out'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('all'),
          _buildList('scheduled'),
          _buildList('checked-in'),
          _buildList('checked-out')
        ],
      ),
    );
  }

  /// Botão para ver faturamento:
  Widget _buildRevenueButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: _showMonthlyRevenue,
        label: const Text(
          'Ver Faturamento por Período',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  /// Design da lista de reservas:
  Widget _buildList(String filter) {
    final filteredList = getFilteredReservations(filter);

    if (isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // Soma 1 ao tamanho para incluir o botão no topo
      itemCount: filteredList.length + 1,
      itemBuilder: (context, index) {
        // Se for o primeiro item (0), desenha o botão
        if (index == 0) {
          return Column(
            children: [
              _buildRevenueButton(),
              // Se a lista estiver vazia, mostra o aviso de vazio logo abaixo do botão
              if (filteredList.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 200),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Nenhuma reserva encontrada', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
            ],
          );
        }

        // Se a lista estiver vazia, não desenha cards
        if (filteredList.isEmpty) return const SizedBox.shrink();

        // Se não for o botão, desenha a reserva
        final res = filteredList[index - 1];
        return _buildDesignCard(res);
      },
    );
  }

  /// Design do card principal que exibe os detalhes da reserva:
  Widget _buildDesignCard(Reservation res) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(res.guestName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(res.guestPhone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(res.guestCity, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [_buildStatusBadge(res.status), const SizedBox(height: 4), _buildPaymentBadge(res.paymentStatus)],
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  res.reservationType == 'daily'
                      ? 'Diária (24h)'
                      : res.reservationType == 'overnight'
                      ? 'Pernoite (20h-08h)'
                      : res.reservationType == 'rest'
                      ? 'Descanso (07h-17h)'
                      : res.reservationType,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.bed_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Quarto ${res.roomNumber}', style: TextStyle(color: Colors.grey[700])),
                const SizedBox(width: 16),
                const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${res.guests} hóspede(s)', style: TextStyle(color: Colors.grey[700])),
              ],
            ),

            if (res.companionNames != null && res.companionNames!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Acompanhante(s): ${res.companionNames}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('Check-in: ${res.checkInDate} às ${res.checkInTime}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Check-out: ${res.checkOutDate} às ${res.checkOutTime}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.credit_card_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),

                Expanded(
                  child: Text('Valor: R\$ ${res.chargedAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                ),

                if (res.paymentStatus == 'paid' && res.paymentDate != null && res.paymentDate!.isNotEmpty)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text('Pago em: ${res.paymentDate}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ),
                    ),
                  ),
              ],
            ),

            if (res.notes != null && res.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(res.notes!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ],
            const SizedBox(height: 16),

            /// Botões de Ação (Check-in, Check-out, Editar, Excluir)
            Row(
              children: [
                if (res.status == 'scheduled')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateReservationStatus(res, 'checked-in'),
                      icon: const Icon(Icons.login, size: 16, color: Colors.white),
                      label: const Text('Check-in', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF030213),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
                else if (res.status == 'checked-in')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateReservationStatus(res, 'checked-out'),
                      icon: const Icon(Icons.logout, size: 16, color: Colors.white),
                      label: const Text('Check-out', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF030213),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => ReservationFormScreen(reservation: res)));
                    refreshReservations();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _confirmDelete(context, res.id, res.guestName),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmar delete de reserva:
  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir a reserva de "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              _deleteReservation(id);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Design dos status da reserva:
  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'scheduled':
        color = Colors.amber;
        label = 'Agendado';
        break;
      case 'checked-in':
        color = Colors.green;
        label = 'Hospedado';
        break;
      case 'checked-out':
        color = Colors.grey;
        label = 'Finalizado';
        break;
      default:
        color = Colors.black;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Design dos status do pagamento:
  Widget _buildPaymentBadge(String status) {
    Color color = status == 'paid' ? Colors.green : Colors.red;
    String label = status == 'paid' ? 'Pago' : 'Pagamento Pendente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
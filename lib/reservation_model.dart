/// Classe que representa a entidade principal do sistema: A Reserva.
/// Esta classe serve como um espelho dos dados trafegados entre a interface (UI) e o banco de dados SQLite.
class Reservation {
  /// Identificador único da reserva.
  final String id;

  /// Tipo da reserva: 'daily', 'overnight', 'rest'
  final String reservationType;

  /// Hóspede principal
  final String guestName;
  final String guestCPF;
  final String guestCity;
  final String guestPhone;

  /// Numéro do quarto
  final String roomNumber;

  /// Datas e horário
  final String checkInDate;
  final String checkInTime;
  final String checkOutDate;
  final String checkOutTime;

  /// Valor cobrado e status do pagamento ('pending', 'paid')
  final double chargedAmount;
  final String paymentStatus;

  /// Status da reserva : 'scheduled', 'checked-in', 'checked-out'
  final String status;

  /// Data do pagamento
  final String? paymentDate;

  /// Numero de hósepede e nome dos acompanhantes (OPCIONAL)
  /// Regra de negócio: Preenchido apenas se [guests] > 1.
  final int guests;
  final String? companionNames;

  /// Observações
  final String? notes;

  Reservation({
    required this.id,
    required this.reservationType,
    required this.guestName,
    required this.guestCPF,
    required this.guestCity,
    required this.guestPhone,
    required this.roomNumber,
    required this.checkInDate,
    required this.checkInTime,
    required this.checkOutDate,
    required this.checkOutTime,
    required this.chargedAmount,
    required this.paymentStatus,
    this.paymentDate,
    required this.status,
    required this.guests,
    this.notes,
    this.companionNames,
  });

  /// Converte o objeto Dart para um Map.
  /// Necessário para operações de INSERT e UPDATE no pacote `sqflite`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reservationType': reservationType,
      'guestName': guestName,
      'guestCPF': guestCPF,
      'guestCity': guestCity,
      'guestPhone': guestPhone,
      'roomNumber': roomNumber,
      'checkInDate': checkInDate,
      'checkInTime': checkInTime,
      'checkOutDate': checkOutDate,
      'checkOutTime': checkOutTime,
      'chargedAmount': chargedAmount,
      'paymentStatus': paymentStatus,
      'paymentDate': paymentDate,
      'status': status,
      'guests': guests,
      'notes': notes,
      'companionNames': companionNames,
    };
  }

  /// Construtor Factory (Deserialização).
  /// Converte o Map retornado pelo banco de dados de volta para um objeto Dart.
  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      reservationType: map['reservationType'],
      guestName: map['guestName'],
      guestCPF: map['guestCPF'],
      guestCity: map['guestCity'],
      guestPhone: map['guestPhone'],
      roomNumber: map['roomNumber'],
      checkInDate: map['checkInDate'],
      checkInTime: map['checkInTime'],
      checkOutDate: map['checkOutDate'],
      checkOutTime: map['checkOutTime'],
      chargedAmount: map['chargedAmount'],
      paymentStatus: map['paymentStatus'],
      paymentDate: map['paymentDate'],
      status: map['status'],
      guests: map['guests'],
      notes: map['notes'],
      companionNames: map['companionNames'],
    );
  }
}
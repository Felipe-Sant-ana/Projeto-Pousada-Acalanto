import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'reservation_model.dart';

/// Database helper para o app da Pousada.
/// Responsabilidades:
/// - Gerenciar a criação / abertura do banco SQLite;
/// - Fornecer métodos CRUD para a tabela `reservations`.

class DatabaseHelper {
  /// Instância singleton do helper.
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  /// Construtor privado para impedir que outras classes criem instâncias novas
  DatabaseHelper._init();

/// Getter assíncrono para obter o banco. Se não existir, inicializa.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pousadaAcalanto.db');// Nome do banco
    return _database!;
  }

  // Cria a tabela na primeira execução do app:

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

/// Configura o caminho físico e abre o banco de dados:
  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE reservations (
      id TEXT PRIMARY KEY,
      reservationType TEXT,
      guestName TEXT,
      guestCPF TEXT,
      guestCity TEXT,
      guestPhone TEXT,
      roomNumber TEXT,
      checkInDate TEXT,
      checkInTime TEXT,
      checkOutDate TEXT,
      checkOutTime TEXT,
      chargedAmount REAL,
      paymentStatus TEXT,
      paymentDate TEXT,
      status TEXT,
      guests INTEGER,
      notes TEXT, 
      companionNames TEXT
    )
    ''');
  }

  /// Operações CRUD (Create, Read, Update, Delete)

  /// CREATE
  Future<void> create(Reservation reservation) async {
    final db = await instance.database;
    await db.insert('reservations', reservation.toMap());
  }

  /// READ (TODOS)
  Future<List<Reservation>> readAllReservations() async {
    final db = await instance.database;
    // Ordena por checkInDate DESC (mais recentes primeiro) para melhor UX na listagem
    final result = await db.query('reservations', orderBy: 'checkInDate DESC');
    return result.map((json) => Reservation.fromMap(json)).toList();
  }

  /// UPDATE
  Future<int> update(Reservation reservation) async {
    final db = await instance.database;
    return db.update('reservations', reservation.toMap(), where: 'id = ?', whereArgs: [reservation.id]);
  }

  /// DELETE
  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete('reservations', where: 'id = ?', whereArgs: [id]);
  }
}

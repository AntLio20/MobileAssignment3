import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FoodDatabase {
  static final FoodDatabase instance = FoodDatabase._init();

  static Database? _database;

  FoodDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food_tracking.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE priceTargets (
        date TEXT PRIMARY KEY,
        targetPrice REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE selectedFoods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

  // Insert 20 food items into the foods table
  await db.insert('foods', {'name': 'Burger', 'price': 5.99});
  await db.insert('foods', {'name': 'Pizza', 'price': 7.99});
  await db.insert('foods', {'name': 'Salad', 'price': 4.49});
  await db.insert('foods', {'name': 'Pasta', 'price': 6.99});
  await db.insert('foods', {'name': 'Steak', 'price': 12.99});
  await db.insert('foods', {'name': 'Sandwich', 'price': 3.99});
  await db.insert('foods', {'name': 'Soup', 'price': 2.99});
  await db.insert('foods', {'name': 'Fries', 'price': 2.49});
  await db.insert('foods', {'name': 'Tacos', 'price': 3.49});
  await db.insert('foods', {'name': 'Nachos', 'price': 5.49});
  await db.insert('foods', {'name': 'Grilled Chicken', 'price': 9.99});
  await db.insert('foods', {'name': 'Fish and Chips', 'price': 8.49});
  await db.insert('foods', {'name': 'Ice Cream', 'price': 1.99});
  await db.insert('foods', {'name': 'Brownie', 'price': 2.49});
  await db.insert('foods', {'name': 'Hot Dog', 'price': 3.99});
  await db.insert('foods', {'name': 'Sushi Roll', 'price': 9.49});
  await db.insert('foods', {'name': 'Fried Rice', 'price': 7.49});
  await db.insert('foods', {'name': 'Cheesecake', 'price': 4.99});
  await db.insert('foods', {'name': 'Waffles', 'price': 5.49});
  await db.insert('foods', {'name': 'Pancakes', 'price': 4.99});
}

  // Fetch the price target for a specific date
  Future<double?> fetchPriceTargetForDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'priceTargets',
      columns: ['targetPrice'],
      where: 'date = ?',
      whereArgs: [date],
    );
    if (result.isNotEmpty) {
      return result.first['targetPrice'] as double;
    }
    return null;
  }

  // Insert or update the price target for a specific date
  Future<void> insertOrUpdatePriceTarget(String date, double targetPrice) async {
    final db = await instance.database;
    await db.insert(
      'priceTargets',
      {'date': date, 'targetPrice': targetPrice},
      conflictAlgorithm: ConflictAlgorithm.replace, // Ensures the target price is only for the selected date
    );
  }

  // Fetch selected foods for a specific date
  Future<List<Map<String, dynamic>>> fetchSelectedFoodsForDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'selectedFoods',
      columns: ['name', 'price'],
      where: 'date = ?',
      whereArgs: [date],
    );
    return result;
  }

  // Insert or update selected foods for a specific date
  Future<void> insertOrUpdateSelectedFoods(String date, List<Map<String, dynamic>> foods) async {
    final db = await instance.database;

    // Remove existing foods for the specified date
    await db.delete(
      'selectedFoods',
      where: 'date = ?',
      whereArgs: [date],
    );

    // Insert the new foods for the specified date
    for (var food in foods) {
      await db.insert('selectedFoods', {
        'date': date,
        'name': food['name'],
        'price': food['price'],
      });
    }
  }

  Future<void> deleteMealPlanForDate(String date) async {
    final db = await instance.database;

    // Delete the price target for the specified date
    await db.delete(
      'priceTargets',
      where: 'date = ?',
      whereArgs: [date],
    );

    // Delete the selected foods for the specified date
    await db.delete(
      'selectedFoods',
      where: 'date = ?',
      whereArgs: [date],
    );

    print('Meal plan deleted for date: $date');
  }

  // Fetch all dates that have meal plans saved
Future<List<String>> fetchAllMealPlanDates() async {
  final db = await instance.database;
  final result = await db.query('priceTargets', columns: ['date']);
  return result.map((row) => row['date'] as String).toList();
}

  // Fetch all food items from the database
  Future<List<Map<String, dynamic>>> fetchFoods() async {
    final db = await instance.database;

    // Check if the foods table exists and has entries
    final result = await db.query('foods'); // 'foods' should match your table name

    return result;
  }
}
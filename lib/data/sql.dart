import 'package:sqflite/sqflite.dart';

import 'package:expense_tracker/models/Category.dart';
import 'package:expense_tracker/models/Expense.dart';

import 'package:path/path.dart';

class SQLFactory {
  SQLFactory._();
  static final SQLFactory db = SQLFactory._();
  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;

    _database = await initDatabase();
    return _database;
  }

  initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'ExpenseTracker33'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          name TEXT NOT NULL);
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS expenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          category INTEGER NOT NULL,
          date TEXT NOT NULL,
          price REAL NOT NULL,
          description TEXT,
          FOREIGN KEY(category) REFERENCES categories(id));
        ''');
      },
      version: 1,
    );
  }

  addCategory(String name) async {
    final db = await database;

    int response = await db.rawInsert(
      'INSERT INTO categories (name) VALUES (?)',
      [name],
    );

    return response;
  }

  addExpense(Expense expense) async {
    final db = await database;

    int response = await db.rawInsert(
      'INSERT INTO expenses (category, date, description, price) VALUES (?, ?, ?, ?)',
      [
        expense.category.id,
        expense.date.toString(),
        expense.description,
        expense.price
      ],
    );

    return response;
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.rawQuery(
      'DELETE FROM categories WHERE id = ?',
      [id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.rawQuery(
      'DELETE FROM expenses WHERE id = ?',
      [id],
    );
  }

  Future<void> deleteAllCategories() async {
    final db = await database;
    await db.rawQuery('DELETE FROM expenses');
    await db.rawQuery('DELETE FROM categories');
  }

  Future<void> deleteAllExpenses() async {
    final db = await database;
    await db.rawQuery('DELETE FROM expenses');
  }

  Future<void> dropTables() async {
    final db = await database;
    await db.execute('DROP TABLE expenses');
    await db.execute('DROP TABLE categories');
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final response = await db.query('categories');

    final List<Category> categories = <Category>[];
    for (var row in response) {
      categories.add(Category.fromJSON(row));
    }

    return categories;
  }

  Future<int> getExpenseCount() async {
    final db = await database;
    final response =
        await db.rawQuery('SELECT COUNT(*) AS count FROM expenses');
    return response[0]['count'];
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final response = await db.rawQuery(
        'SELECT expenses.id, category AS category_id, name, date, description, price from categories, expenses group by category_id');

    final List<Expense> expenses = <Expense>[];
    for (var row in response) {
      expenses.add(Expense.fromJSON(row));
    }

    return expenses;
  }

  Future<List<MapEntry<int, num>>> getYearlyTotals() async {
    final db = await database;
    final response = await db.rawQuery('SELECT * FROM expenses');

    Map<int, num> years = Map();
    for (var row in response) {
      Expense expense = Expense.fromJSON(row);

      years[expense.date.year] = years[expense.date.year] ?? 0 + expense.price;
    }

    return years.entries.toList();
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE expenses
      SET category = ?,
      date = ?,
      description = ?,
      price = ?
      WHERE id = ?''',
      [
        expense.category.id,
        expense.date.toString(),
        expense.description,
        expense.price,
        expense.id,
      ],
    );
  }

  Future<List<Expense>> getExpensesByCategory(int id) async {
    final List<Expense> expenses = <Expense>[];
    final db = await database;

    final response = await db.rawQuery(
      'SELECT expenses.id, category AS category_id, name, date, description, price FROM categories, expenses WHERE categories.id = ? GROUP BY category_id',
      [id],
    );

    for (var row in response) {
      expenses.add(Expense.fromJSON(row));
    }

    return expenses;
  }
}

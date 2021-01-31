import 'package:sqflite/sqflite.dart';

import 'package:expense_tracker/models/Category.dart';
import 'package:expense_tracker/models/Expense.dart';

import 'package:path/path.dart';

/// SQL wrapper to interface internal expense database
class SQLFactory {
  SQLFactory._();
  static final SQLFactory db = SQLFactory._();
  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;

    _database = await initDatabase();
    return _database;
  }

  /// Initializes database file and creates relevant tables
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

  /// ### Parameters
  /// * [name] category name
  ///
  /// ### Output
  /// Returns ID of inserted category row.
  ///
  /// ### Description
  /// Inserts category row into database with name column value as [name].
  ///
  /// ### Usage Example
  /// ```dart
  /// int id = await SQLFactory.db.addCategory('Gas');
  /// ```
  Future<int> addCategory(String name) async {
    final db = await database;

    int response = await db.rawInsert(
      'INSERT INTO categories (name) VALUES (?)',
      [name],
    );

    return response;
  }

  /// ### Parameters
  /// * [expense] expense to be inserted into database
  ///
  /// ### Output
  /// Returns ID of inserted Expense row.
  ///
  /// ### Description
  /// Inserts expense row into database with name column
  /// values as member variables of [expense].
  ///
  /// ### Usage Example
  /// ```dart
  /// int id = await SQLFactory.db.addExpense(_expense);
  /// ```
  Future<int> addExpense(Expense expense) async {
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

  /// ### Parameters
  /// * [id] ID of category to delete from database
  ///
  /// ### Description
  /// deletes category row from database where ID column value = [id].
  ///
  /// ### Usage Example
  /// ```dart
  /// SQLFactory.db.deleteCategory(id);
  /// ```
  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.rawQuery(
      'DELETE FROM categories WHERE id = ?',
      [id],
    );
  }

  /// ### Parameters
  /// * [id] ID of expense to delete from database
  ///
  /// ### Description
  /// deletes expense row from database where ID column value = [id].
  ///
  /// ### Usage Example
  /// ```dart
  /// SQLFactory.db.deleteExpense(id);
  /// ```
  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.rawQuery(
      'DELETE FROM expenses WHERE id = ?',
      [id],
    );
  }

  /// ### Description
  /// Deletes all expenses and categories from database.
  ///
  /// ### Usage Example
  /// ```dart
  /// await SQLFactory.db.deleteAllCategories();
  /// ```
  Future<void> deleteAllCategories() async {
    final db = await database;
    await db.rawQuery('DELETE FROM expenses');
    await db.rawQuery('DELETE FROM categories');
  }

  /// ### Description
  /// Deletes all expenses from database.
  ///
  /// ### Usage Example
  /// ```dart
  /// await SQLFactory.db.deleteAllCategories();
  /// ```
  Future<void> deleteAllExpenses() async {
    final db = await database;
    await db.rawQuery('DELETE FROM expenses');
  }

  /// ### Output
  /// Returns list of categories
  ///
  /// ### Description
  /// Retrieves all rows from categories table
  /// and converts to list of categories.
  ///
  /// ### Usage Example
  /// ```dart
  /// List<Category> categories = await SQLFactory.db.getCategories();
  /// ```
  Future<List<Category>> getCategories() async {
    final db = await database;
    final response = await db.query('categories');

    final List<Category> categories = <Category>[];
    for (var row in response) {
      categories.add(Category.fromJSON(row));
    }

    return categories;
  }

  /// ### Output
  /// Returns total number of expenese in database
  ///
  /// ### Description
  /// Retrieves total row count of expenses table.
  ///
  /// ### Usage Example
  /// ```dart
  /// int count = await getExpenseCount();
  /// ```
  Future<int> getExpenseCount() async {
    final db = await database;
    final response =
        await db.rawQuery('SELECT COUNT(*) AS count FROM expenses');
    return response[0]['count'];
  }

  /// ### Description
  /// Retrieves all rows from expenses table.
  ///
  /// ### Usage Example
  /// ```dart
  /// int count = await getExpenseCount();
  /// ```
  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final response = await db.rawQuery(
        'SELECT expenses.id, category AS category_id, name, date, price, description from categories, expenses group by expenses.id');

    final List<Expense> expenses = <Expense>[];
    for (var row in response) {
      expenses.add(Expense.fromJSON(row));
    }

    return expenses;
  }

  /// ### Output
  /// Returns a list of Map<int, num> that match years with respective total
  ///
  /// ### Description
  /// Retrieves list of year-total key value pair
  /// for every year that had an expense.
  ///
  /// ### Usage Example
  /// ```dart
  /// List<MapEntry<int, num>> years = await SQLFactory.db.getYearlyTotals();
  /// ```
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

  /// ### Parameters
  /// * [expense] New expense to be updated in database
  ///
  /// ### Description
  /// Updates row in expenses where ID column value = [expense.id].
  ///
  /// ### Usage Example
  /// ```dart
  /// await updateExpense(expense);
  /// ```
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

  /// ### Parameters
  /// * [id] Category ID to match expenses.category column value against
  ///
  /// ### Output
  /// Returns list of expenses that match category of [id]
  ///
  /// ### Description
  /// Retrieves list of expenses from expenses table that have a category ID of [id].
  ///
  /// ### Usage Example
  /// ```dart
  /// List<Expense> expenses = await SQLFactory.db.getExpensesByCategory(id);
  /// ```
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

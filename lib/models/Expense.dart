import 'dart:io';

import 'package:expense_tracker/models/Category.dart';

/// Expense data model
class Expense {
  int id;
  Category category;
  DateTime date;
  String description;
  num price;

  Expense() {
    this.id = 0;
    this.category = Category.builder(id: null, name: '');
    this.date = DateTime.now();
    this.description = '';
    this.price = 0;
  }

  String toJSON() {
    return 'id: $id, category: {${category.toString()}}, date: ${date.toString()}, description: "$description", price: $price';
  }

  String toCSV() {
    return '${this.category.name},${this.date.toString()},${this.price},"$description"';
  }

  factory Expense.fromJSON(Map<String, dynamic> json) {
    return Expense.builder(
      id: json['id'],
      category: Category.builder(
        id: json['category_id'],
        name: json['name'],
      ),
      date: DateTime.parse(json['date']),
      description: json['description'],
      price: json['price'],
    );
  }

  factory Expense.fromCSV(String line) {
    final List<String> values = line.split(',');
    String category = values[0];
    DateTime date = DateTime.parse(values[1]);
    num price = num.parse(values[2]);
    String description = '';

    // Get description value
    for (int i = 0; i < values.length; i++) {
      if (i >= 0 && i <= 2) {
        continue;
      }

      description += values[i];
    }

    // Trim CSV escape quotes off value
    description.replaceRange(0, 1, '');
    description.replaceRange(description.length - 1, description.length, '');

    return Expense.builder(
      id: -1,
      category: Category.builder(id: -1, name: category),
      date: date,
      description: description,
      price: price,
    );
  }

  Expense.builder(
      {this.id, this.category, this.date, this.description, this.price});

  static bool exportExpenses(String directory, List<Expense> expenses) {
    bool result = true;

    final String fileName = 'ExpenseTracker_${DateTime.now().toString()}';
    File file = File('$directory/$fileName.csv');

    String contents = 'Category,Date,Price,Description';
    for (var expense in expenses) {
      contents += '\n${expense.toCSV()}';
    }

    try {
      file.writeAsStringSync(contents);
    } on FileSystemException {
      result = false;
    }

    return result;
  }

  static List<Expense> importExpenses(String location) {
    List<Expense> expenses = [];

    File file = File(location);

    try {
      List<String> lines = file.readAsLinesSync();

      // Remove legend
      lines.removeAt(0);

      for (int i = 0; i < lines.length; i++) {
        Expense temp = Expense.fromCSV(lines[i]);

        // Assign fake ID for model listview
        temp.id = -i;

        expenses.add(temp);
      }
    } catch (e) {
      throw e;
    }

    return expenses;
  }
}

import 'package:expense_tracker/models/Category.dart';

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

  String toString() {
    return 'id: $id, category: {${category.toString()}}, date: ${date.toString()}, description: "$description", price: $price';
  }

  factory Expense.fromJSON(Map<String, dynamic> json) => Expense.builder(
        id: json['id'],
        category: Category.builder(
          id: json['category_id'],
          name: json['name'],
        ),
        date: DateTime.parse(json['date']),
        description: json['description'],
        price: json['price'],
      );

  Expense.builder(
      {this.id, this.category, this.date, this.description, this.price});
}

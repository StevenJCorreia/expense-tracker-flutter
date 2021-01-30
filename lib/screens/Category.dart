import 'package:expense_tracker/data/sql.dart';
import 'package:expense_tracker/models/Category.dart';
import 'package:expense_tracker/models/Expense.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget {
  CategoryScreen({Key key, this.category}) : super(key: key);

  final Category category;

  @override
  _CategoryScreenState createState() => _CategoryScreenState(category);
}

class _CategoryScreenState extends State<CategoryScreen> {
  _CategoryScreenState(this._category);

  List<Expense> _relatedExpenses = [];
  Category _category;

  bool isLoading = true;

  num _min = 0;
  num _max = 0;
  num _sum = 0;
  num _avg = 0;

  @override
  void initState() {
    super.initState();

    SQLFactory.db.getExpensesByCategory(_category.id).then((expenses) {
      setState(() {
        setState(() {
          _relatedExpenses = expenses;

          for (Expense expense in _relatedExpenses) {
            if (expense.price < _min) {
              _min = expense.price;
            }

            if (expense.price > _max) {
              _max = expense.price;
            }

            _sum += expense.price;
          }

          _avg = _sum / _relatedExpenses.length;

          isLoading = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO - Style screen better
    return Scaffold(
      appBar: AppBar(
        title: Text(_category.name),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Count:'),
                  Text('Minimum:'),
                  Text('Maximum:'),
                  Text('Total:'),
                  Text('Average:'),
                ],
              ),
              isLoading
                  ? CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(_relatedExpenses.length.toString()),
                        Text(_min.toStringAsFixed(2)),
                        Text(_max.toStringAsFixed(2)),
                        Text(_sum.toStringAsFixed(2)),
                        Text(_avg.toStringAsFixed(2)),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

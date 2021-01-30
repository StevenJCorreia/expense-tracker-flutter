import 'package:flutter/material.dart';

import './screens/Expense.dart';
import './screens/Expenses.dart';
import './screens/Categories.dart';
import './screens/Category.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.red,
        dividerTheme: DividerThemeData(color: Colors.black),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: 'Expenses',
      routes: {
        'Expenses': (context) => ExpensesScreen(),
        'Expense': (context) => ExpenseScreen(),
        'Category': (context) => CategoryScreen(),
        'Categories': (context) => CategoriesScreen(),
      },
    );
  }
}

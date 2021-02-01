import 'package:flutter/material.dart';

import './screens/Expense.dart';
import './screens/Expenses.dart';
import './screens/Categories.dart';
import './screens/Category.dart';

void main() => runApp(App());

/**
 * Planned Features:
 * Color picker for Category dialog to allow user to pick custom
 * colors for categories. (will show up as circle on card)
 * 
 * Swap Dismissible for the longPress implementation
 * on Expenses screen to match Categories screen.
 * 
 * Pre-select first category in dropdown on Expense screen.
 * 
 * Add filter feature on Expenses screen.
 * 
 * Add images for each expense (DB column and permissions handling needed)
 * 
 * Re-style dropdown widget on Expense screen.
 * 
 * Style Category screen better.
 */
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

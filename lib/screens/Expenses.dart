import 'package:expense_tracker/models/Category.dart';
import 'package:flutter/material.dart';

import 'package:expense_tracker/models/Expense.dart';
import 'package:expense_tracker/screens/Expense.dart';
import 'package:expense_tracker/data/sql.dart';
import 'package:expense_tracker/utility/utils.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

// TODO - Swap Dismissible for the longPress implementation
// TODO - Fix Navigator stack issues
class ExpensesScreen extends StatefulWidget {
  ExpensesScreen({Key key}) : super(key: key);

  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int _sortBy = 0;
  List<Expense> _expenses = <Expense>[];
  List<Expense> _filteredexpenses = <Expense>[];
  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('My Expenses');

  _ExpensesScreenState() {
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
          _filteredexpenses = _expenses;
        });
      } else {
        setState(() {
          _searchText = _filter.text;
        });
      }
    });
  }

  void _goToExpense({id}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseScreen(
          expense: id == null ? Expense() : _filteredexpenses[id],
        ),
      ),
    );
  }

  Future<void> _export() async {
    // Get user-desired directory
    final String directory = await FilePicker.platform.getDirectoryPath();
    if (directory == null) {
      return;
    }

    // Export file to directory if valid
    final bool result = Expense.exportExpenses(directory, _expenses);

    if (!result) {
      Utils.alertError(
        context,
        'File Error',
        'File could not be written to at chosen directory.',
      );
    } else {
      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
        content: Text('Exported ${_expenses.length} expense(s).'),
      ));
    }
  }

  Future<void> _import() async {
    // Get file location
    final FilePickerResult result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result == null) {
      return;
    }

    List<Expense> importedExpenses = [];
    try {
      importedExpenses = Expense.importExpenses(result.files[0].path);
    } catch (e) {
      Utils.alertError(context, 'File Error',
          'Could not retrieve expenses from selected file.');
      return;
    }

    if (importedExpenses.length == 0) {
      Utils.alertError(context, 'No Expenses',
          'No Expenses were retrieved from selected file.');
    } else {
      // Display list of imported expenses
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) {
          List<Expense> _importedExpenses = importedExpenses;
          print('${_expenses.length}, ${_filteredexpenses.length}');

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text('Imported Expeneses'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Cancel'),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FlatButton(
                  child: const Text('Import'),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textColor: _importedExpenses.length > 0
                      ? Theme.of(context).accentColor
                      : Colors.grey,
                  onPressed: _importedExpenses.length > 0
                      ? () async {
                          // Check for any new categories
                          List<Category> categories =
                              await SQLFactory.db.getCategories();
                          for (Expense expense in _importedExpenses) {
                            final int index = categories.indexWhere(
                                (Category category) =>
                                    expense.category.name == category.name);
                            if (index == -1) {
                              final int newIndex = await SQLFactory.db
                                  .addCategory(expense.category.name);
                              categories.add(
                                Category.builder(
                                  id: newIndex,
                                  name: expense.category.name,
                                ),
                              );
                            }
                          }

                          // Add all accepted expenses to database
                          await Future.wait(_importedExpenses.map(
                              (Expense expense) =>
                                  SQLFactory.db.addExpense(expense)));

                          // Grab new expenses from DB
                          List<Expense> expenseList =
                              await SQLFactory.db.getExpenses();
                          // Sort according to saved sort preference
                          switch (_sortBy) {
                            case 1:
                              expenseList.sort((a, b) =>
                                  a.category.name.compareTo(b.category.name));
                              break;
                            case 2:
                              expenseList.sort((a, b) =>
                                  b.category.name.compareTo(a.category.name));
                              break;
                            case 3:
                              expenseList
                                  .sort((a, b) => a.date.compareTo(b.date));
                              break;
                            case 4:
                              expenseList
                                  .sort((a, b) => b.date.compareTo(a.date));
                              break;
                            case 5:
                              expenseList
                                  .sort((a, b) => a.price.compareTo(b.price));
                              break;
                            case 6:
                              expenseList
                                  .sort((a, b) => b.price.compareTo(a.price));
                              break;
                          }

                          this.setState(() {
                            _expenses = expenseList;
                          });
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
              ],
              content: Container(
                width: double.infinity,
                child: SingleChildScrollView(
                  child: Container(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Divider(),
                        _importedExpenses.length > 0
                            ? ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.4,
                                ),
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _importedExpenses.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return Dismissible(
                                        key: Key(_importedExpenses[index]
                                            .id
                                            .toString()),
                                        background: Container(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: Icon(
                                            Icons.delete,
                                            color: Colors.black,
                                          ),
                                        ),
                                        secondaryBackground: Container(
                                          alignment:
                                              AlignmentDirectional.centerEnd,
                                          child: Icon(
                                            Icons.delete,
                                            color: Colors.black,
                                          ),
                                        ),
                                        child: GestureDetector(
                                          child: Card(
                                            elevation: 10,
                                            shadowColor: Colors.grey,
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                children: <Widget>[
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 4.0),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Text(
                                                          Utils.formatDate(
                                                              'MMM ddo yyyy',
                                                              _importedExpenses[
                                                                      index]
                                                                  .date),
                                                          style: new TextStyle(
                                                              fontSize: 25.0),
                                                        ),
                                                        Spacer(),
                                                        Text(
                                                          '\$${_importedExpenses[index].price.toStringAsFixed(2)}',
                                                          style: new TextStyle(
                                                              fontSize: 25.0),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 1),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Text(_importedExpenses[
                                                                index]
                                                            .category
                                                            .name),
                                                        Spacer(),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 1),
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      child: Container(
                                                        child: Text(
                                                          _importedExpenses[
                                                                  index]
                                                              .description,
                                                          maxLines: 2,
                                                          textAlign:
                                                              TextAlign.left,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        onDismissed: (direction) {
                                          setState(() {
                                            _importedExpenses.removeAt(index);
                                          });
                                        },
                                      );
                                    }),
                              )
                            : FlatButton(
                                onPressed: () {
                                  setState(() {
                                    _importedExpenses = Expense.importExpenses(
                                        result.files[0].path);
                                  });
                                },
                                child: Text(
                                  'No more expenses! Reset?',
                                  style: TextStyle(
                                    color: Theme.of(context).accentColor,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  void _menuItemSelected(String item) async {
    switch (item) {
      case 'Categories':
        Navigator.pushNamed(context, 'Categories');
        break;
      case 'Sort':
        if (_filteredexpenses.length == 0) {
          Utils.alertError(
              context, 'No Expenses', 'There are no expenses to sort.');
          return;
        }
        _showSortDialog();
        break;
      case 'Filter':
        if (_filteredexpenses.length == 0) {
          Utils.alertError(
              context, 'No Expenses', 'There are no expenses to filter.');
          return;
        }

        // TODO - Implement
        Utils.alertError(
            context, 'Feature WIP', 'Feature is currently a work-in-progress.');
        break;
      case 'Import':
        _import();
        break;
      case 'Export':
        if (_filteredexpenses.length == 0) {
          Utils.alertError(
              context, 'No Expenses', 'There are no expenses to export.');
          return;
        }

        _export();
        break;
      case 'Delete All':
        if (_filteredexpenses.length == 0) {
          Utils.alertError(
              context, 'No Expenses', 'There are no expenses to delete.');
          return;
        }

        Utils.alertError(context, 'Delete All Expenses',
            'Are you sure you want to delete all ${_expenses.length} expenses?');
        break;
      case 'Get Yearly Total':
        if (_filteredexpenses.length == 0) {
          Utils.alertError(
              context, 'No Expenses', 'There are no expenses to aggregate.');
          return;
        }

        _showTotalDialog();
        break;
    }
  }

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          controller: _filter,
          decoration: new InputDecoration(
              prefixIcon: new Icon(Icons.search), hintText: 'Search...'),
        );
      } else {
        this._searchIcon = new Icon(Icons.search);
        this._appBarTitle = new Text('My Expenses');
        _filteredexpenses = _expenses;
        _filter.clear();
      }
    });
  }

  void _setSortPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('Expense_sortBy', _sortBy);
  }

  void _showSortDialog() {
    bool categoryAscending = false;
    bool categoryDescending = false;
    bool dateAscending = false;
    bool dateDescending = false;
    bool priceAscending = false;
    bool priceDescending = false;

    switch (_sortBy) {
      case 1:
        categoryAscending = true;
        break;
      case 2:
        categoryDescending = true;
        break;
      case 3:
        dateAscending = true;
        break;
      case 4:
        dateDescending = true;
        break;
      case 5:
        priceAscending = true;
        break;
      case 6:
        priceDescending = true;
        break;
    }

    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sort'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        content: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text('Category - Ascending'),
                  onChanged: (value) {
                    _expenses.sort(
                        (a, b) => a.category.name.compareTo(b.category.name));
                    _filteredexpenses.sort(
                        (a, b) => a.category.name.compareTo(b.category.name));

                    setState(() {
                      _sortBy = 1;
                    });

                    _setSortPreference();

                    Navigator.of(ctx).pop();
                  },
                  value: categoryAscending,
                ),
                CheckboxListTile(
                  title: Text('Category - Descending'),
                  onChanged: (value) {
                    _expenses.sort(
                        (a, b) => b.category.name.compareTo(a.category.name));
                    _filteredexpenses.sort(
                        (a, b) => b.category.name.compareTo(a.category.name));

                    setState(() {
                      _sortBy = 2;
                    });

                    _setSortPreference();

                    Navigator.of(ctx).pop();
                  },
                  value: categoryDescending,
                ),
                CheckboxListTile(
                  title: Text('Date - Ascending'),
                  onChanged: (value) {
                    _expenses.sort((a, b) => a.date.compareTo(b.date));
                    _filteredexpenses.sort((a, b) => a.date.compareTo(b.date));

                    setState(() {
                      _sortBy = 3;
                    });

                    _setSortPreference();

                    Navigator.of(ctx).pop();
                  },
                  value: dateAscending,
                ),
                CheckboxListTile(
                  title: Text('Date - Descending'),
                  onChanged: (value) {
                    _expenses.sort((a, b) => b.date.compareTo(a.date));
                    _filteredexpenses.sort((a, b) => b.date.compareTo(a.date));

                    setState(() {
                      _sortBy = 4;
                    });

                    _setSortPreference();

                    Navigator.of(ctx).pop();
                  },
                  value: dateDescending,
                ),
                CheckboxListTile(
                  title: Text('Price - Ascending'),
                  onChanged: (value) {
                    _expenses.sort((a, b) => a.price.compareTo(b.price));
                    _filteredexpenses
                        .sort((a, b) => a.price.compareTo(b.price));

                    setState(() {
                      _sortBy = 5;
                    });

                    _setSortPreference();

                    Navigator.of(ctx).pop();
                  },
                  value: priceAscending,
                ),
                CheckboxListTile(
                  title: Text('Price - Descending'),
                  onChanged: (value) {
                    _expenses.sort((a, b) => b.price.compareTo(a.price));
                    _filteredexpenses
                        .sort((a, b) => b.price.compareTo(a.price));

                    setState(() {
                      _sortBy = 6;
                    });

                    _setSortPreference();

                    Navigator.of(ctx).pop();
                  },
                  value: priceDescending,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTotalDialog() async {
    final List<MapEntry<int, num>> years =
        await SQLFactory.db.getYearlyTotals();

    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (ctx) {
        MapEntry<int, num> selectedPair = years.first;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Expense Totals'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            content: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: selectedPair.key,
                      icon: Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      style: TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (int id) {
                        setState(() {
                          selectedPair =
                              years.firstWhere((pair) => pair.key == id);
                        });
                      },
                      items: years.map((MapEntry<int, num> year) {
                        return DropdownMenuItem<int>(
                          value: year.key,
                          child: Text(year.key.toString()),
                        );
                      }).toList(),
                    ),
                    Text('\$${selectedPair.value.toString()}'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // Grab expenses from DB
    SQLFactory.db.getExpenses().then((expenseList) async {
      // Retrieve sort order preference
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int sortPref = prefs.getInt('Expense_sortBy') ?? 0;

      // Sort according to saved sort preference
      switch (sortPref) {
        case 1:
          expenseList
              .sort((a, b) => a.category.name.compareTo(b.category.name));
          break;
        case 2:
          expenseList
              .sort((a, b) => b.category.name.compareTo(a.category.name));
          break;
        case 3:
          expenseList.sort((a, b) => a.date.compareTo(b.date));
          break;
        case 4:
          expenseList.sort((a, b) => b.date.compareTo(a.date));
          break;
        case 5:
          expenseList.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 6:
          expenseList.sort((a, b) => b.price.compareTo(a.price));
          break;
      }

      setState(() {
        _expenses = expenseList;
        _sortBy = sortPref;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_searchText.isNotEmpty) {
      List<Expense> tempList = <Expense>[];
      for (int i = 0; i < _filteredexpenses.length; i++) {
        if (_filteredexpenses[i]
            .description
            .toLowerCase()
            .contains(_searchText.toLowerCase())) {
          tempList.add(_filteredexpenses[i]);
        }
      }

      _filteredexpenses = tempList;
    } else {
      _filteredexpenses = _expenses;
    }

    return Scaffold(
      appBar: AppBar(
        title: _appBarTitle,
        leading: IconButton(
          icon: _searchIcon,
          onPressed: _searchPressed,
        ),
        actions: [
          PopupMenuButton(
            onSelected: (i) => _menuItemSelected(i),
            icon: Icon(
              Icons.more_vert,
              size: 50,
              color: Colors.white,
            ),
            padding: EdgeInsets.all(0),
            itemBuilder: (context) {
              return List.from(
                [
                  PopupMenuItem(
                    child: Text('Categories'),
                    value: 'Categories',
                  ),
                  PopupMenuDivider(
                    height: 10,
                  ),
                  PopupMenuItem(
                    child: Text('Sort'),
                    value: 'Sort',
                  ),
                  PopupMenuItem(
                    child: Text('Filter'),
                    value: 'Filter',
                  ),
                  PopupMenuDivider(
                    height: 10,
                  ),
                  PopupMenuItem(
                    child: Text('Import'),
                    value: 'Import',
                  ),
                  PopupMenuItem(
                    child: Text('Export'),
                    value: 'Export',
                  ),
                  PopupMenuDivider(
                    height: 10,
                  ),
                  PopupMenuItem(
                    child: Text('Delete All'),
                    value: 'Delete All',
                  ),
                  PopupMenuItem(
                    child: Text('Get Yearly Total'),
                    value: 'Get Yearly Total',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ListView.builder(
          itemBuilder: (context, index) {
            return Dismissible(
              key: Key(_filteredexpenses[index].id.toString()),
              background: Container(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  Icons.delete,
                  color: Colors.black,
                ),
              ),
              secondaryBackground: Container(
                alignment: AlignmentDirectional.centerEnd,
                child: Icon(
                  Icons.delete,
                  color: Colors.black,
                ),
              ),
              child: GestureDetector(
                onTap: () => _goToExpense(id: index),
                child: Card(
                  color: Colors
                      .grey, // TODO - Should we even do anything about Card background color?
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: <Widget>[
                              Text(
                                Utils.formatDate('MMM ddo yyyy',
                                    _filteredexpenses[index].date),
                                style: new TextStyle(fontSize: 25.0),
                              ),
                              Spacer(),
                              Text(
                                '\$${_filteredexpenses[index].price.toStringAsFixed(2)}',
                                style: new TextStyle(fontSize: 25.0),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Row(
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 5, 0),
                                height: 15,
                                width: 15,
                                decoration: BoxDecoration(
                                  color: Colors
                                      .black, //Color(filteredexpenses[index].category.color), // Save as hex (0xFF000000 for Colors.black)
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(_filteredexpenses[index].category.name),
                              Spacer(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: SizedBox(
                            width: double.infinity,
                            child: Container(
                              child: Text(
                                _filteredexpenses[index].description,
                                maxLines: 2,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              onDismissed: (direction) async {
                final Expense deletedExpense = _expenses[index];

                await SQLFactory.db.deleteExpense(deletedExpense.id).then((e) {
                  setState(() {
                    _filteredexpenses.removeAt(index);
                  });
                });

                // Alert user with Snackbar and option to undo Expense deletion
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expense deleted.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        deletedExpense.id =
                            await SQLFactory.db.addExpense(deletedExpense);

                        setState(() {
                          _expenses.insert(
                              index, deletedExpense); // filteredexpenses
                        });
                      },
                    ),
                  ),
                );
              },
            );
          },
          itemCount: _filteredexpenses.length,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToExpense,
        tooltip: 'Add Expense',
        child: Icon(Icons.add),
      ),
    );
  }
}

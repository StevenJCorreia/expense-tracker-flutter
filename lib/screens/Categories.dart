import 'package:flutter/material.dart';

import 'package:expense_tracker/data/sql.dart';
import 'package:expense_tracker/models/Category.dart';
import 'package:expense_tracker/screens/Category.dart';
import 'package:expense_tracker/utility/utils.dart';

import 'package:shared_preferences/shared_preferences.dart';

class CategoriesScreen extends StatefulWidget {
  CategoriesScreen({Key key}) : super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _sortBy = 0;
  List<Category> _categories = <Category>[];
  final TextEditingController _categoryController = new TextEditingController();

  List<int> _categoryIndecesToDelete = [];
  bool _isDeleting = false;
  bool _allSelected = false;

  void _addCategory() async {
    // Check for empty category value
    if (_categoryController.text.isEmpty) {
      Utils.alertError(context, 'No Category', 'Please enter a category.');
      return;
    }

    // Check for duplicate in local list
    if (_categories
        .where((category) =>
            category.name.toUpperCase() ==
            _categoryController.text.toUpperCase())
        .toList()
        .isNotEmpty) {
      Utils.alertError(
        context,
        'Duplicate Category',
        '${_categoryController.text} is already a category.',
      );
      return;
    }

    // Add category to list
    int id = await SQLFactory.db.addCategory(_categoryController.text);

    setState(() {
      _categories.add(Category.builder(id: id, name: _categoryController.text));

      _categoryController.text = '';
    });

    Navigator.of(context).pop();
  }

  void _menuItemSelected(String item) {
    if (_categories.length < 1) {
      Utils.alertError(
        context,
        'No Categories',
        'There are no Categories to $item.',
      );
      return;
    }

    switch (item) {
      case 'Sort':
        _showSortDialog();
        break;
    }
  }

  void _setSortPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('Category_sortBy', _sortBy);
  }

  void _floatingButtonTapped() {
    if (_isDeleting) {
      if (_categoryIndecesToDelete.length == 0) {
        // No categories selected
        Utils.alertError(
            context, 'No Categories', 'Please select at least one category.');
        return;
      }

      if (_allSelected) {
        _showDeleteAllConfirmationDialog();
        return;
      }

      // 0 < categoryIndecesToDelete.length < categories.length
      Utils.alertError(
        context,
        'Delete Categories',
        'Are you sure you want to delete ${_categoryIndecesToDelete.length} selected categories?\nDoing such will delete all expenses with the related Categories.\nThis action cannot be un-done!',
        [
          FlatButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          FlatButton(
            onPressed: () async {
              await Future.wait(
                _categoryIndecesToDelete.map(
                  (categoryID) => SQLFactory.db.deleteCategory(categoryID),
                ),
              );

              setState(() {
                for (int categoryID in _categoryIndecesToDelete) {
                  _categories
                      .removeWhere((category) => categoryID == category.id);
                }

                _categories = _categories;
                _categoryIndecesToDelete.clear();

                _isDeleting = false;
                _allSelected = false;
              });

              Navigator.pop(context);
            },
            child: Text('Yes'),
          ),
        ],
      );
    } else {
      showDialog(
        barrierDismissible: true,
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Add Category'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'What is this expense for?',
                      labelText: 'Category',
                    ),
                  ),
                  FlatButton(
                    onPressed: _addCategory,
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  void _showDeleteAllConfirmationDialog() async {
    Utils.alertError(
      context,
      'Delete All Categories',
      'Are you sure you want to delete all ${_categories.length} categories?\nDoing such will delete all expenses with the related Categories.\nThis action cannot be un-done!',
      [
        FlatButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("No"),
        ),
        FlatButton(
          onPressed: () async {
            await SQLFactory.db.deleteAllCategories();

            setState(() {
              _categories = <Category>[];
              _categoryIndecesToDelete.clear();

              _isDeleting = false;
              _allSelected = false;
            });

            Navigator.pop(context);
          },
          child: Text("Yes"),
        ),
      ],
    );
  }

  void _showSortDialog() {
    bool nameAscending = false;
    bool nameDescending = false;

    switch (_sortBy) {
      case 1:
        nameAscending = true;
        break;
      case 2:
        nameDescending = true;
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
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text('Category - Ascending'),
                  onChanged: (value) {
                    _categories.sort((a, b) => a.name.compareTo(b.name));

                    setState(() {
                      _sortBy = 1;
                    });

                    _setSortPreference();

                    Navigator.of(ctx).pop();
                  },
                  value: nameAscending,
                ),
                CheckboxListTile(
                  title: Text('Category - Descending'),
                  onChanged: (value) {
                    _categories.sort((a, b) => b.name.compareTo(a.name));

                    setState(() {
                      _sortBy = 2;
                    });

                    _setSortPreference();

                    Navigator.of(ctx).pop();
                  },
                  value: nameDescending,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Grab expenses from DB
    SQLFactory.db.getCategories().then((categoryList) async {
      // Retrieve sort order preference
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int sortPref = prefs.getInt('Category_sortBy') ?? 0;

      // Sort according to saved sort preference
      switch (sortPref) {
        case 1:
          _categories.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 2:
          _categories.sort((a, b) => b.name.compareTo(a.name));
          break;
      }

      setState(() {
        _categories = categoryList;
        _sortBy = sortPref;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isDeleting
            ? Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _allSelected = !_allSelected;

                      if (_allSelected) {
                        for (var category in _categories) {
                          _categoryIndecesToDelete.add(category.id);
                        }
                      } else {
                        _categoryIndecesToDelete.clear();
                      }
                    });
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: new BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.black, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: _allSelected ? Colors.black : Colors.transparent,
                    ),
                  ),
                ),
              )
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text('Categories'),
        centerTitle: true,
        actions: [
          _isDeleting
              ? IconButton(
                  icon: Icon(
                    Icons.cancel,
                    color: Colors.black,
                    size: 35,
                  ),
                  onPressed: () {
                    setState(() {
                      _isDeleting = false;
                      _allSelected = false;

                      _categoryIndecesToDelete.clear();
                    });
                  },
                )
              : PopupMenuButton(
                  itemBuilder: (context) {
                    return List.from(
                      [
                        PopupMenuItem(
                          child: Text('Sort'),
                          value: 'Sort',
                        ),
                      ],
                    );
                  },
                  onSelected: (i) => _menuItemSelected(i),
                  icon: Icon(
                    Icons.more_vert,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
        ],
      ),
      body: Center(
        child: ListView.builder(
          itemBuilder: (context, index) {
            return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                onTap: () {
                  if (_isDeleting) {
                    setState(() {
                      if (_categoryIndecesToDelete
                              .indexOf(_categories[index].id) ==
                          -1) {
                        _categoryIndecesToDelete.add(_categories[index].id);
                      } else {
                        _categoryIndecesToDelete.remove(_categories[index].id);
                      }

                      _allSelected =
                          _categories.length == _categoryIndecesToDelete.length;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryScreen(
                          category: _categories[index],
                        ),
                      ),
                    );
                  }
                },
                onLongPress: () {
                  if (_isDeleting == true) {
                    return;
                  }

                  setState(() {
                    _isDeleting = true;

                    _categoryIndecesToDelete.add(_categories[index].id);

                    _allSelected =
                        _categories.length == _categoryIndecesToDelete.length;
                  });
                },
                leading: Text(
                  _categories[index].name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                trailing: _isDeleting
                    ? Icon(
                        Icons.remove_circle_outline,
                        color: _categoryIndecesToDelete
                                    .indexOf(_categories[index].id) ==
                                -1
                            ? Colors.black
                            : Colors.red,
                      )
                    : null,
              ),
            );
          },
          itemCount: _categories.length,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _floatingButtonTapped,
        tooltip: _isDeleting ? 'Delete Selected Categories' : 'Add Expense',
        child: Icon(_isDeleting
            ? (_categoryIndecesToDelete.length == 0
                ? Icons.delete_forever
                : Icons.delete)
            : Icons.add),
      ),
    );
  }
}

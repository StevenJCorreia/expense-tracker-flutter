// import 'dart:typed_data';
import 'package:expense_tracker/data/sql.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:expense_tracker/models/Category.dart';
import 'package:expense_tracker/models/Expense.dart';
import 'package:expense_tracker/utility/utils.dart';

import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';

class ExpenseScreen extends StatefulWidget {
  ExpenseScreen({Key key, this.expense}) : super(key: key);

  final Expense expense;

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState(expense);
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  _ExpenseScreenState(this._expense);

  // From props / widget constructor
  Expense _expense;

  // State members
  List<Category> _categories = <Category>[];

  // TextField controllers
  final TextEditingController _priceController = new TextEditingController();
  final TextEditingController _descriptionController =
      new TextEditingController();
  final TextEditingController _categoryController = new TextEditingController();

  Future<void> _addCategory() async {
    // Check for empty category value
    if (_categoryController.text.isEmpty) {
      Utils.alertError(context, 'No Category', 'Please enter a category.');
      return;
    }

    // Check for duplicate in local list
    for (Category category in _categories) {
      if (_categoryController.text == category.name) {
        Utils.alertError(context, 'Duplicate Category',
            '${_categoryController.text} is already a category.');
        return;
      }
    }

    // Add category to list
    int id = await SQLFactory.db.addCategory(_categoryController.text);

    setState(() {
      _expense.category =
          Category.builder(id: id, name: _categoryController.text);

      _categories.add(_expense.category);

      _categoryController.text = '';
    });

    Navigator.of(context).pop();
  }

  // Future<Uint8List> _getImage(ImageSource source) async {
  //   try {
  //     final PickedFile file = await ImagePicker().getImage(source: source);

  //     if (file != null) return await file.readAsBytes();
  //   } catch (e) {
  //     throw e;
  //   }

  //   return null;
  // }

  void _showCategoryDialog() {
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

  // void _showPictureDialog() async {
  //   showDialog(
  //     barrierDismissible: true,
  //     context: context,
  //     // TODO - Figure out how to widen the checkbox text...
  //     builder: (ctx) => AlertDialog(
  //       title: Text('Image'),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.all(Radius.circular(20)),
  //       ),
  //       content: SingleChildScrollView(
  //       child: Container(
  //           width: double.infinity,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               FlatButton(
  //                 child: Text('Select from Gallery'),
  //                 onPressed: () async {
  //                   try {
  //                     Uint8List image = await _getImage(ImageSource.gallery);

  //                     if (image != null) {
  //                       expense.image = image;

  //                       setState(() { });

  //                       Navigator.of(context).pop();
  //                     }
  //                   } catch (e) {
  //                     // TODO - Handle denied permissions better...
  //                     openAppSettings();
  //                     Navigator.of(context).pop();
  //                   }
  //                 },
  //               ),
  //               FlatButton(
  //                 child: Text('Take Picture'),
  //                 onPressed: () async {
  //                   try {
  //                     Uint8List image = await _getImage(ImageSource.camera);

  //                     if (image != null) {
  //                       expense.image = image;

  //                       setState(() { });

  //                       Navigator.of(context).pop();
  //                     }
  //                   } on PlatformException catch (e) {
  //                     // TODO - Handle denied permissions better...
  //                     openAppSettings();
  //                     Navigator.of(context).pop();
  //                   }
  //                 },
  //               )
  //             ]
  //           )
  //         ),
  //       )
  //     )
  //   );
  // }

  void _submitExpense() async {
    if (_expense.category.id == null) {
      Utils.alertError(context, 'No Category', 'Please select a category.');
      return;
    }

    // Check for invalid price
    if (num.tryParse(_priceController.text) == null ||
        num.parse(_priceController.text) < 0.0) {
      Utils.alertError(
          context, 'Invalid Price', 'Please enter a positive number.');
      return;
    } else {
      // Update main Expense state member before submitting
      _expense.price = num.parse(_priceController.text);
    }

    if (_descriptionController.text.isEmpty) {
      Utils.alertError(
        context,
        'No Description',
        'Are you sure you want to submit without a description?',
        [
          FlatButton(
            onPressed: () async {
              Navigator.of(context).pop();
            },
            child: Text('No'),
          ),
          FlatButton(
            onPressed: () async {
              _expense.id == 0
                  ? await SQLFactory.db.addExpense(_expense)
                  : await SQLFactory.db.updateExpense(_expense);
              Navigator.popAndPushNamed(context, 'Expenses');
            },
            child: Text('Yes'),
          ),
        ],
      );
    } else {
      _expense.id == 0
          ? await SQLFactory.db.addExpense(_expense)
          : await SQLFactory.db.updateExpense(_expense);
      Navigator.popAndPushNamed(context, 'Expenses');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Pre-populate fields if editing an expense
    if (_expense.category.id != null) {
      _descriptionController.text = _expense.description;
      _priceController.text = _expense.price.toStringAsFixed(2);
    }

    // Grab categories from DB
    SQLFactory.db.getCategories().then((categoryList) {
      categoryList.sort((Category a, Category b) => a.name.compareTo(b.name));
      setState(() {
        _categories = categoryList;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_expense.id == 0 ? 'Add' : 'Edit'} Expense'),
        ),
        body: Center(
          child: Container(
            child: Column(
              children: [
                Container(
                  child: Row(
                    children: [
                      DropdownButton<int>(
                        value: _expense
                            .category.id, // TODO - Pre-select first category
                        hint: Text(
                          '${_categories.length == 0 ? 'Add' : 'Select'} a Category',
                        ),
                        icon: Icon(Icons.arrow_downward),
                        iconSize: 24,
                        elevation: 16,
                        isExpanded: false, // TODO - Needs to be true
                        style: TextStyle(color: Colors.black),
                        underline: Container(
                          height: 2,
                          color: Colors.redAccent,
                        ),
                        onChanged: (int id) {
                          setState(() {
                            _expense.category = _categories
                                .where((category) => category.id == id)
                                .first;
                          });
                        },
                        items: _categories
                            .map<DropdownMenuItem<int>>((Category category) {
                          return DropdownMenuItem<int>(
                            value: category.id,
                            child: Text(
                              category.name,
                              style: category.id == 0
                                  ? TextStyle(color: Colors.grey)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _showCategoryDialog,
                        tooltip: 'Add New Category',
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    DatePicker.showDatePicker(
                      context,
                      showTitleActions: true,
                      onConfirm: (DateTime date) {
                        setState(() {
                          _expense.date = date;
                        });
                      },
                      currentTime: DateTime.now(),
                      locale: LocaleType.en,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 5,
                          ),
                          child: Text(
                            Utils.formatDate('EEEEE, MMMM do', _expense.date),
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    controller: _priceController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'What was the damage?',
                      labelText: 'Price',
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextField(
                    onChanged: (String description) {
                      _expense.description = description;
                    },
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Venmo for pizza party.',
                      labelText: 'Description',
                    ),
                  ),
                ),
                // TODO - Implement this better
                IconButton(
                  icon: Icon(Icons.camera_alt_rounded),
                  tooltip: 'Attach Image',
                  onPressed: () => {}, // _showPictureDialog
                ),
                Container(
                  child: RaisedButton(
                    textColor: Colors.white,
                    color: Colors.red,
                    child: Text('Submit'),
                    onPressed: () => _submitExpense(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class that contains static misc. helper methods
class Utils {
  /// ### Parameters
  /// * [context] showDialog context
  /// * [title] Dialog title
  /// * [content] Dialog content
  /// * [buttons] Dialog action buttons (defaults to "Okay" dismissal button)
  ///
  /// ### Description
  /// Wrapper for current implementation of
  /// ```dart
  /// showDialog();
  /// ```
  ///
  /// ### Usage Example
  /// ```dart
  /// Utils.alertError(context, 'Error', 'Some information.');
  /// ```
  static void alertError(BuildContext context, String title, String content,
      [List<Widget> buttons]) {
    if (buttons == null) {
      buttons = [
        FlatButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Okay"),
        ),
      ];
    }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        content: Text(content),
        actions: buttons,
      ),
    );
  }

  /// ### Parameters
  /// * [pattern] Format pattern
  /// * [date] Date to be formatted
  ///
  /// ### Output
  /// Returns given [date] formatted with [pattern].
  ///
  /// ### Description
  /// Wrapper for current implementation of
  /// ```dart
  /// DateTime([Pattern]).format([DateTime])
  /// ```
  /// that adds custom 'o' token which maps to [date]'s ordinal.
  ///
  /// ### Background/Context
  /// This was necessary for project since Google apparently does not
  /// support ordinal skeletons in the current [DateFormat] implementation.
  ///
  /// ### Usage Example
  /// ```dart
  /// Utils.formatDate('MMM ddo yyyy', new DateTime(2021, 1, 22)); // 'Jan 22th 2021'
  /// ```
  static String formatDate(String pattern, DateTime date) {
    String ordinal;

    switch (date.day) {
      case 1:
        ordinal = 'st';
        break;
      case 2:
        ordinal = 'nd';
        break;
      case 3:
        ordinal = 'rd';
        break;
      default:
        ordinal = 'th';
        break;
    }

    pattern = pattern.replaceAll('o', '\'$ordinal\'');

    return DateFormat(pattern).format(date);
  }
}

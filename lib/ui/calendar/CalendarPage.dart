import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flutter/material.dart';

class CalendarPage extends EasonBasePage {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  String get title => 'CalendarPage';
  @override
  bool get showBack => false;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends BasePageState<CalendarPage> {
  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: Text(
        'CalendarPage Content',
        style: TextStyle(fontSize: 24, color: Colors.blue),
      ),
    );
  }
}

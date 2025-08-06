import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flutter/material.dart';

class HomePage extends EasonBasePage {
  const HomePage({Key? key}) : super(key: key);

  @override
  String get title => 'HomePage';

  @override
  bool get showBack => false;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BasePageState<HomePage> {
  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: Text(
        'HomePage Content',
        style: TextStyle(fontSize: 24, color: Colors.blue),
      ),
    );
  }
}

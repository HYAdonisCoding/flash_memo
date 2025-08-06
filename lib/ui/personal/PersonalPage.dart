import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flutter/material.dart';

class PersonalPage extends EasonBasePage {
  const PersonalPage({Key? key}) : super(key: key);

  @override
  String get title => 'PersonalPage';
  @override
  bool get showBack => false;
  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends BasePageState<PersonalPage> {
  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: Text(
        'PersonalPage Content',
        style: TextStyle(fontSize: 24, color: Colors.blue),
      ),
    );
  }
}

import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flutter/material.dart';

class SearchPage extends EasonBasePage {
  const SearchPage({super.key});

  @override
  String get title => 'SearchPage';

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends BasePageState<SearchPage> {
  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: Text(
        'SearchPage Content',
        style: TextStyle(fontSize: 24, color: Colors.blue),
      ),
    );
  }
}

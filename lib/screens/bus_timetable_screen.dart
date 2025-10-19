import 'package:flutter/material.dart';
import 'kmplock_lines_screen.dart';
import 'municipal_lines_screen.dart';

class BusTimetableScreen extends StatefulWidget {
  const BusTimetableScreen({super.key});
  @override
  State<BusTimetableScreen> createState() => _BusTimetableScreenState();
}

class _BusTimetableScreenState extends State<BusTimetableScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _qCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autobusy'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'KM Płock'), Tab(text: 'Gminne / Inne')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _qCtrl,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Szukaj numeru autobusu lub operatora…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _qCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _qCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                KmplockLinesScreen(query: _query),
                MunicipalLinesScreen(query: _query),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

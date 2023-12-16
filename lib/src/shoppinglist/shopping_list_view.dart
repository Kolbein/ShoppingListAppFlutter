import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'shopping_item.dart';

class ShoppingListView extends StatefulWidget {
  static const routeName = '/shoppinglist';

  const ShoppingListView({super.key});

  @override
  _ShoppingListViewState createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView> {
  final FirebaseDatabase database = FirebaseDatabase.instance;

  DatabaseReference ref = FirebaseDatabase.instance.ref("shoppingitems");

  List<ShoppingItem> items = [];

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.onValue.listen((event) {
      var snapshot = event.snapshot;
      items.clear();
      var values =
          Map<String, int>.from(snapshot.value as Map<Object?, Object?>);
      values.forEach((key, value) {
        items.add(ShoppingItem(key, count: value));
      });
      items.sort((a, b) =>
          a.name.compareTo(b.name));
      setState(() {});
    });
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Legg til vare'),
          content: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Varenavn',
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                String itemName = _controller.text;
                DataSnapshot snapshot = await ref.child(itemName).get();
                if (snapshot.value != null && snapshot.value is int) {
                  ref.child(itemName).set((snapshot.value as int) + 1);
                } else {
                  ref.child(itemName).set(1);
                }
                _controller.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Legg til'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Sample Items'),
      // ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Text(
                            'Tidligere varer 📜',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Builder(
                              builder: (context) {
                                int itemCount = items.length;
                                return ListView.builder(
                                  itemCount: itemCount,
                                  itemBuilder: (context, index) {
                                    ShoppingItem item = items[index];
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      elevation: 2,
                                      child: ListTile(
                                        title: Text(item.name),
                                        onTap: () {
                                          ref
                                              .child(item.name)
                                              .set(item.count + 1);
                                        },
                                        onLongPress: () {
                                          ref.child(item.name).remove();
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Text(
                            'Handleliste 🛒',
                            style: TextStyle(
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Builder(
                              builder: (context) {
                                int itemCount = items
                                    .where((item) => item.count > 0)
                                    .length;
                                List<ShoppingItem> sortedItems = items
                                    .where((item) => item.count > 0)
                                    .toList()
                                  ..sort((a, b) => a.name.compareTo(b.name));

                                return ListView.builder(
                                  itemCount: itemCount,
                                  itemBuilder: (context, index) {
                                    ShoppingItem item = sortedItems[index];
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      elevation: 2,
                                      child: ListTile(
                                        title: Text(
                                            '${item.count}x ${item.name}'),
                                        onTap: () {
                                          ref
                                              .child(item.name)
                                              .set(item.count - 1);
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

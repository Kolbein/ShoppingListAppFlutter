import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:handleliste/src/shoppinglist/shopping_list_view.dart';
import 'dart:math';

class ShoppingListCreationView extends StatefulWidget {
  const ShoppingListCreationView({super.key});

  @override
  _ShoppingListCreationViewState createState() =>
      _ShoppingListCreationViewState();
}

class _ShoppingListCreationViewState extends State<ShoppingListCreationView> {
  final _formKey = GlobalKey<FormState>();
  final _listIdController = TextEditingController();
  String? listId;

  @override
  void initState() {
    super.initState();
    loadListId();
  }

  void loadListId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      listId = prefs.getString('shoppingListId');
    });
  }

  String generateRandomId([int length = 6]) {
    const allowedChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(length, (index) {
      return allowedChars[random.nextInt(allowedChars.length)];
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(bottom: 50.0),
              child: Text(
                'Handleliste 🥑',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Center(
                    child: SizedBox(
                      width: 220,
                      child: TextFormField(
                        controller: _listIdController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20.0),
                          labelText: 'ID til handleliste',
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? false) {
                            return 'Vennligst legg inn ID til handleliste';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: 220,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              if (currentUserId != null) {
                                // Join the existing list
                                DatabaseReference listRef = FirebaseDatabase
                                    .instance
                                    .ref('shoppinglists')
                                    .child(_listIdController.text);
                                // Check if the list exists
                                DataSnapshot snapshot =
                                    (await listRef.once()).snapshot;
                                if (snapshot.value != null) {
                                  // The list exists, join the list
                                  // Add the current user as a member of the list
                                  listRef
                                      .child('members')
                                      .child(currentUserId)
                                      .set(true);

                                  // Store the list ID in shared preferences
                                  final SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString(
                                      'shoppingListId', _listIdController.text);

                                  // Navigate to the ShoppingListView
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ShoppingListView(
                                            listId: _listIdController.text)),
                                  );
                                } else {
                                  // The list does not exist, show a message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('The list does not exist'),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'You must be logged in to join a list')),
                                );
                              }
                            }
                          },
                          child: const Text('Join liste'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () async {
                    if (currentUserId != null) {
                      // Create a new list
                      DatabaseReference listsRef =
                          FirebaseDatabase.instance.ref('shoppinglists');

                      String newListId = generateRandomId();
                      // Attempt to create a new list
                      try {
                        await listsRef.child(newListId).set({
                          'owner': currentUserId,
                          'members': {
                            currentUserId: true,
                          },
                          'shoppingitems': {},
                        });

                        // Store the list ID in shared preferences
                        final SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setString('shoppingListId', newListId);

                        // Navigate to the ShoppingListView
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ShoppingListView(listId: newListId)),
                        );
                      } catch (e) {
                        // If the write fails, show an error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'The list ID already exists. Please try a different ID.')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('You must be logged in to create a list')),
                      );
                    }
                  },
                  child: const Text('Lag ny liste'),
                ),
              ),
            ),
            if (listId != null)
              Center(
                child: SizedBox(
                  width: 220,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ShoppingListView(listId: listId!)),
                        );
                      },
                      child: const Text('Tilbake til listen'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

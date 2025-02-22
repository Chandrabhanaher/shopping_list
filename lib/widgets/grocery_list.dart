import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';

// import 'package:shopping_list/data/dummy_items.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/screens/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  //final List<GroceryItem> _groceryItems = [];
  // var _isLoading = true;
  late Future<List<GroceryItem>> _loadeItems;
  //String? _error;
  @override
  void initState() {
    super.initState();
    _loadeItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https('otp-verification-642e8-default-rtdb.firebaseio.com',
        'shopping-list.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      // setState(() {
      //   _error = 'Failed to fetch data, Please try agian later';
      // });
      throw Exception('Failed to fetch data, Please try agian later.');
    }
    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadeItem = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadeItem.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }

    return loadeItem;
  }
// Get Fierbase data
  // void _loadItems() async {
  //   final url = Uri.https('otp-verification-642e8-default-rtdb.firebaseio.com',
  //       'shopping-list.json');

  //   try {
  //     final response = await http.get(url);

  //     if (response.statusCode >= 400) {
  //       setState(() {
  //         _error = 'Failed to fetch data, Please try agian later';
  //       });
  //     }
  //     if (response.body == 'null') {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       return;
  //     }

  //     final Map<String, dynamic> listData = json.decode(response.body);
  //     final List<GroceryItem> loadeItem = [];
  //     for (final item in listData.entries) {
  //       final category = categories.entries
  //           .firstWhere(
  //               (catItem) => catItem.value.title == item.value['category'])
  //           .value;
  //       loadeItem.add(GroceryItem(
  //           id: item.key,
  //           name: item.value['name'],
  //           quantity: item.value['quantity'],
  //           category: category));
  //     }
  //     // assigned the list
  //     setState(() {
  //       _groceryItems = loadeItem;
  //       _isLoading = false;
  //     });
  //   } catch (error) {
  //     setState(() {
  //       _error = 'Somethingis is wrong!, Please try agian later';
  //     });
  //   }
  // }

  void _addNewItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (ctx) => const NewItemScreen()),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _loadeItems = _loadItems().then((items) {
        items.add(newItem);
        return _loadeItems = _loadItems();
      });
      // _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    // final index = _groceryItems.indexOf(item);

    setState(() {
      _loadeItems = _loadItems().then((items) {
        items.remove(item);
        return _loadeItems = _loadItems();
      });
      //_groceryItems.remove(item);
    });
    final url = Uri.https('otp-verification-642e8-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    try {
      final response = await http.delete(url);

      if (response.statusCode >= 400) {
        setState(() {
          //_groceryItems.insert(index, item);
          _loadeItems = _loadItems().then((items) {
            for (final i in items) {
              if (i == item) {
                final index = items.indexOf(item);
                items.insert(index, item);
                return _loadeItems;
              }
            }
            return _loadeItems = _loadItems();
          });
        });
      }
    } catch (error) {}
  }

  @override
  Widget build(BuildContext context) {
    // Widget contect = Center(
    //   child: Text('No item added yet..!'),
    // );

    // if (_isLoading) {
    //   contect = Center(child: CircularProgressIndicator());
    // }

    // if (_groceryItems.isNotEmpty) {
    //   contect = ListView.builder(
    //     itemCount: _groceryItems.length,
    //     itemBuilder: (ctx, index) => Dismissible(
    //       onDismissed: (direction) {
    //         _removeItem(_groceryItems[index]);
    //       },
    //       key: ValueKey(_groceryItems[index].id),
    //       child: ListTile(
    //         title: Text(_groceryItems[index].name),
    //         leading: Container(
    //           width: 24,
    //           height: 24,
    //           color: _groceryItems[index].category.color,
    //         ),
    //         trailing: Text(
    //           _groceryItems[index].quantity.toString(),
    //         ),
    //       ),
    //     ),
    //   );
    // }

    // if (_error != null) {
    //   contect = Center(child: Text(_error!));
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addNewItem,
            icon: Icon(Icons.add),
          ),
        ],
      ),
      // body: contect,
      body: FutureBuilder(
        future: _loadeItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (snapshot.data!.isEmpty) {
            return Center(child: Text('No item added yet..!'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) => Dismissible(
              onDismissed: (direction) {
                _removeItem(snapshot.data![index]);
              },
              key: ValueKey(snapshot.data![index].id),
              child: ListTile(
                title: Text(snapshot.data![index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: snapshot.data![index].category.color,
                ),
                trailing: Text(
                  snapshot.data![index].quantity.toString(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

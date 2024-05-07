import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _image; // File to hold the selected image

  // Function to handle image selection
  Future<void> _getImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      setState(() {
        _image = File(file.path!);
      });
    } else {
      // User canceled the file picker
    }
  }

  String? _selectedCategory;
  List<dynamic> _categories = [];
  List<dynamic> _recipe = [];
  List<dynamic> _filteredRecipe = [];

  TextEditingController _recipeName = TextEditingController();
  TextEditingController _description = TextEditingController();
  TextEditingController _instruction = TextEditingController();
  TextEditingController _ingredients = TextEditingController();

  TextEditingController _editRecipeName = TextEditingController();
  TextEditingController _editDescription = TextEditingController();
  TextEditingController _editInstruction = TextEditingController();
  TextEditingController _editIngredients = TextEditingController();


  final server = "http://localhost/RMS_API/api/recipes/";

  Future<void> addRecipe(String name, String description, String instruction,
      String ingredients, String category_id, File? image) async {
    final url = server + "recipe.php";

    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add text fields
    request.fields['recipe_name'] = name;
    request.fields['description'] = description;
    request.fields['instructions'] = instruction;
    request.fields['ingredients'] = ingredients;
    request.fields['category_id'] = category_id;

    // Add image file if provided
    if (image != null) {
      var file = await http.MultipartFile.fromPath('image', image.path);
      request.files.add(file);
    }

    // Send the request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print(response.body);
    loadRecipeList();
  }

  Future<void> editRecipe(String id, String name, String description,
      String instruction, String ingredients, String category_id) async {
    final url = server + "recipe.php";
    Map<String, dynamic> data = {
      "recipe_id": id,
      "recipe_name": name,
      "description": description,
      "instructions": instruction,
      "ingredients": ingredients,
      "category_id": category_id
    };
    final response = await http.put(
        Uri.parse(url),
        body: jsonEncode(data)
    );
    print(response.body);
    loadRecipeList();
  }

  Future<void> loadRecipeList() async {
    final url = server + "recipe.php";
    final response = await http.get(Uri.parse(url));
    try {
      setState(() {
        _recipe = jsonDecode(response.body);
        _filteredRecipe = _recipe;
      });
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  void searchRecipe(String query) {
    setState(() {
      if (query.isNotEmpty) {
        // Filter recipes based on the query
        _filteredRecipe = _recipe.where((recipe) =>
        recipe['recipe_name'].toString().toLowerCase().contains(
            query.toLowerCase()) ||
            recipe['category']['category_name'].toString()
                .toLowerCase()
                .contains(query.toLowerCase())).toList();
        ;
      } else {
        // If query is empty, show all recipes
        _filteredRecipe = _recipe;
      }
    });
  }

  Future<void> loadCategoryList() async {
    final url = server + "category.php";
    final response = await http.get(Uri.parse(url));
    try {
      setState(() {
        _categories = jsonDecode(response.body);
      });
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteRecipe(String index) async {
    final url = server + "recipe.php?recipe_id=$index";

    final response = await http.delete(
      Uri.parse(url),
    );
    print(response.body);
    loadRecipeList();
  }

  Future<void> Favorite(String id, String favorite) async {
    if (favorite == "0") {
      favorite = "1";
    } else {
      favorite = "0";
    }

    final url = server + "favorite.php";
    Map<String, dynamic> data = {
      "recipe_id": id,
      "favorite": favorite
    };
    final response = await http.put(
        Uri.parse(url),
        body: jsonEncode(data)
    );
    print(response.body);
    loadRecipeList();
  }

  @override
  void initState() {
    loadRecipeList();
    loadCategoryList();
    super.initState();
  }

  void showInstruction(String name, String instruction, String ingredients) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$name'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Instruction: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(instruction),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "Ingredients: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(ingredients),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Exit',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void showAddRecipe() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Add Recipe"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Your existing text fields
                    TextField(
                      controller: _recipeName,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _description,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Description',
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _ingredients,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Ingredients',
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _instruction,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Instructions',
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Category',
                      ),
                      value: _selectedCategory,
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['category_id'].toString(),
                          child: Text(category['cat_name']),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    // Button for image upload
                    ElevatedButton(
                      onPressed: () async {
                        await _getImage();
                        setState(() {}); // Refresh the UI to display the selected image
                      },
                      child: Text('Select Image'),
                    ),
                    SizedBox(height: 8),
                    // Display selected image
                    if (_image != null)
                      Container(
                        height: 200, // Set the desired height
                        width: 200, // Set the desired width
                        child: Image.file(
                          _image!,
                          fit: BoxFit
                              .cover, // Ensure the image fills the container without distortion
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _image = null;
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    addRecipe(
                      _recipeName.text, _description.text, _instruction.text,
                      _ingredients.text, _selectedCategory!, _image,);
                    _recipeName.text = "";
                    _description.text = "";
                    _instruction.text = "";
                    _ingredients.text = "";
                    _image = null;
                    _selectedCategory = null;
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showEditRecipe(String id, String name, String description,
      String instruction, String ingredients, String selectedCategory) {
    _editRecipeName.text = name;
    _editDescription.text = description;
    _editIngredients.text = ingredients;
    _editInstruction.text = instruction;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Recipe"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _editRecipeName,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                  ),
                ),
                SizedBox(height: 8), // Add some vertical spacing
                TextField(
                  controller: _editDescription,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Description',
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _editIngredients,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Ingredients',
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _editInstruction,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Instructions',
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Category',
                  ),
                  value: selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['category_id'].toString(),
                      child: Text(category['cat_name']),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                editRecipe(id, _editRecipeName.text, _editDescription.text,
                    _editInstruction.text, _editIngredients.text,
                    selectedCategory);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Save',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  void confirmDialog(String index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delete Task"),
            content: const Text("Are you sure you want to delete this task?"),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[200],
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  deleteRecipe(index);
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                ),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    int crossAxisCount = 1;
    if (screenWidth > 600) {
      crossAxisCount = 3;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Recipe Management System",
          style: TextStyle(
            fontFamily: 'YourFontFamily',
            // Replace 'YourFontFamily' with your desired font family
            fontWeight: FontWeight.bold,
            // You can adjust the font weight as needed
            fontSize: 20, // You can adjust the font size as needed
            // You can add more text style properties as needed
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://img.freepik.com/free-photo/top-view-different-snacks-fruits-crackers_140725-57543.jpg?size=626&ext=jpg&ga=GA1.1.1395880969.1709510400&semt=ais.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center, // Center the image
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                // Adjust the opacity as needed
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  searchRecipe(value);
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: MediaQuery
                        .of(context)
                        .size
                        .width /
                        (MediaQuery
                            .of(context)
                            .size
                            .height / 2),
                  ),
                  itemCount: _filteredRecipe.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.all(0),
                      child: ListTile(
                        title: Text(
                          "${index +
                              1}. ${_filteredRecipe[index]['recipe_name']}",
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 50, // Adjust height as needed
                              child: Text(
                                _filteredRecipe[index]['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Category: ${_filteredRecipe[index]['category']['category_name']}",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                String id = _filteredRecipe[index]['recipe_id'];
                                String favorite = _filteredRecipe[index]['favorite'];
                                Favorite(id, favorite);
                              },
                              icon: _filteredRecipe[index]['favorite'] == "1" ?
                              Icon(Icons.star, color: Colors.blue) :
                              Icon(Icons.star_border_outlined,
                                  color: Colors.grey),
                            ),
                            IconButton(
                              onPressed: () {
                                String category = _filteredRecipe[index]['category']['category_id'];
                                String id = _filteredRecipe[index]['recipe_id'];
                                String name = _filteredRecipe[index]['recipe_name'];
                                String desc = _filteredRecipe[index]['description'];
                                String instruction = _filteredRecipe[index]['instructions'];
                                String ingridients = _filteredRecipe[index]['ingredients'];
                                showEditRecipe(
                                    id, name, desc, instruction, ingridients,
                                    category);
                              },
                              icon: Icon(
                                  Icons.edit_outlined, color: Colors.green),
                            ),
                            IconButton(
                              onPressed: () {
                                String id = _filteredRecipe[index]['recipe_id'];
                                confirmDialog(id);
                              },
                              icon: Icon(
                                  Icons.delete_outline, color: Colors.red),
                            ),
                            IconButton(
                              onPressed: () {
                                String name = _filteredRecipe[index]['recipe_name'];
                                String instruction = _filteredRecipe[index]['instructions'];
                                String ingredients = _filteredRecipe[index]['ingredients'];
                                showInstruction(name, instruction, ingredients);
                              },
                              icon: Icon(Icons.menu_book_outlined,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddRecipe();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.white,
      ),
    );
  }
}

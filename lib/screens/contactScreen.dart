import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../helpers/helper.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  List<Map<String, dynamic>> _contactList = [];

  // ignore: unused_field
  bool _isLoading = true;

  void _refreshContacts() async {
    final data = await SQLHelper.getContacts();

    setState(() {
      _contactList = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshContacts();
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  Uint8List _photoUrl = Uint8List(0);

  Future<void> _addContact() async {
    await SQLHelper.createContact(
      _nameController.text,
      _phoneNumberController.text,
      _emailController.text,
      _addressController.text,
      base64Encode(_photoUrl),
    );
    _refreshContacts();
  }

  Future<void> _updateContact(int id) async {
    await SQLHelper.updateContact(
        id,
        _nameController.text,
        _phoneNumberController.text,
        _emailController.text,
        _addressController.text,
        base64Encode(_photoUrl));
    _refreshContacts();
  }

  Future<void> _deleteContact(int id) async {
    await SQLHelper.deleteContact(id);
    // showSnackBar('Contact deleted successfully');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _refreshContacts();
  }

  AlertDialog _deleteDialog(BuildContext context, int index) {
    return AlertDialog(
      title: const Text('Confirm Deletion'),
      content: const Text('Are you sure you want to delete this contact?'),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _deleteContact(_contactList[index]['id']);
            Navigator.of(context).pop();
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }

  CircleAvatar _formAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundImage: _photoUrl.isNotEmpty
          ? MemoryImage(_photoUrl)
          : const AssetImage('assets/contact.png') as ImageProvider,
    );
  }

  CircleAvatar _listAvatar(int index) {
    return CircleAvatar(
      backgroundImage: _contactList[index]['photoUrl'].isNotEmpty
          ? MemoryImage(base64Decode(_contactList[index]['photoUrl']))
          : const AssetImage('assets/contact.png') as ImageProvider,
    );
  }

  void _showForm(int? id) async {
    if (id != null) {
      final existingContactList =
          _contactList.firstWhere((element) => element['id'] == id);
      _nameController.text = existingContactList['name'];
      _phoneNumberController.text = existingContactList['phoneNumber'];
      _emailController.text = existingContactList['email'];
      _addressController.text = existingContactList['address'];
      _photoUrl = base64Decode(existingContactList['photoUrl']);
    } else {
      _nameController.text = '';
      _phoneNumberController.text = '';
      _emailController.text = '';
      _addressController.text = '';
      _photoUrl = Uint8List(0);
    }

    // validate data before submitting
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 120,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  child: _formAvatar(),
                  onTap: () async {
                    final pickedFile = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        _photoUrl = File(pickedFile.path).readAsBytesSync();
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name can\'t be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(hintText: 'Phone Number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone Number can\'t be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'Email'),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Invalid email address';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(hintText: 'Address'),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return null;
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (id == null) {
                        await _addContact();
                      }
                      if (id != null) {
                        await _updateContact(id);
                      }
                      // create the text fields
                      _nameController.text = '';
                      _phoneNumberController.text = '';
                      _emailController.text = '';
                      _addressController.text = '';
                      // close
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(id == null ? 'Create New' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        // addbutton
        actions: [
          IconButton(
            onPressed: () => _showForm(null),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _contactList.length,
        itemBuilder: (context, index) => Card(
          color: Colors.green[50],
          margin: const EdgeInsets.all(5),
          child: ListTile(
            onTap: () {
              try {
                // TODO: Details screen
              } catch (e) {
                print('Error showing snackbar: $e');
              }
            },
            leading: SizedBox(
              width: 50,
              height: 50,
              child: _listAvatar(index),
            ),
            title: Text(_contactList[index]['name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_contactList[index]['phoneNumber']),
                Text(_contactList[index]['email']),
              ],
            ),
            trailing: SizedBox(
              width: 100,
              child: Row(children: [
                IconButton(
                  onPressed: () => _showForm(_contactList[index]['id']),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return _deleteDialog(context, index);
                    },
                  ),
                  icon: const Icon(Icons.delete),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

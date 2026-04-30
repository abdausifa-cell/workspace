import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ListUserDataPage());
  }
}

class UserModel {
  int? id;
  String nama = "";
  int umur = 0;

  UserModel({this.id, required this.nama, required this.umur});
}

class ListUserDataPage extends StatefulWidget {
  const ListUserDataPage({super.key});

  @override
  State<ListUserDataPage> createState() => _ListUserDataPageState();
}

class _ListUserDataPageState extends State<ListUserDataPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _umurCtrl = TextEditingController();

  List<UserModel> userList = [
    UserModel(id: 1, nama: "Satu", umur: 10),
    UserModel(id: 2, nama: "Dua", umur: 20),
    UserModel(id: 3, nama: "Tiga", umur: 30),
    UserModel(id: 4, nama: "Empat", umur: 40),
  ];

  void _form(int? id) {
    if (id != null) {
      var user = userList.firstWhere((data) => data.id == id);
      _nameCtrl.text = user.nama;
      _umurCtrl.text = user.umur.toString();
    } else {
      _nameCtrl.clear();
      _umurCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 
          20, 
          20, 
          MediaQuery.of(context).viewInsets.bottom + 50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: "Nama"),
            ),
            TextField(
              controller: _umurCtrl,
              decoration: const InputDecoration(hintText: "Umur"),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () => 
                _save(id, _nameCtrl.text, int.parse(_umurCtrl.text)),
              child: Text(id == null ? "Tambah" : "Perbaharui"),
            ),
          ],
        ),
      ),
    );
  }

  void _save(int? id, String nama, int umur) {
    if (id != null) {
      var user = userList.firstWhere((data) => data.id == id);
      setState(() {
        user.nama = nama;
        user.umur = umur;
      });
    } else {
      var nextId = userList.isEmpty ? 1 : userList.last.id! + 1;
      var newUser = UserModel(id: nextId, nama: nama, umur: umur);
      setState(() {
        userList.add(newUser);
      });
    }
    Navigator.pop(context);
  }

  void _delete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Apakah anda yakin ingin menghapus data ini?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              setState(() => userList.removeWhere((data) => data.id == id));
              Navigator.pop(context);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User List")),
      body: ListView.builder(
        itemCount: userList.length,
        itemBuilder: (cxt, i) => ListTile(
          title: Text(userList[i].nama),
          subtitle: Text("umur: ${userList[i].umur} tahun"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _form(userList[i].id),
                child: const Icon(Icons.edit),
              ),
              TextButton(
                onPressed: () => _delete(userList[i].id!),
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
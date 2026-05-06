import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  // Memastikan inisialisasi binding Flutter dilakukan sebelum akses database
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const ListUserDataPage(),
    );
  }
}

// --- DATABASE HELPER ---
class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = p.join(await getDatabasesPath(), "user_db.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // Nama kolom 'nama' dan 'umur' harus konsisten
        return db.execute(
          "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT, umur INTEGER)",
        );
      },
    );
  }

  static Future<int> insertData(UserModel userModel) async {
    final db = await database;
    return await db.insert(
      "users",
      userModel.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<UserModel>> getData() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query("users");
    return result.map((userMap) => UserModel.fromJson(userMap)).toList();
  }

  static Future<int> updateData(UserModel userModel) async {
    final db = await database;
    Map<String, dynamic> dataToUpdate = {
      "nama": userModel.nama,
      "umur": userModel.umur,
    };
    return await db.update(
      "users",
      dataToUpdate,
      where: "id = ?",
      whereArgs: [userModel.id],
    );
  }

  static Future<int> deleteData(int id) async {
    final db = await database;
    return await db.delete("users", where: "id = ?", whereArgs: [id]);
  }
}

// --- MODEL ---
class UserModel {
  int? id;
  String nama;
  int umur;

  UserModel({this.id, required this.nama, required this.umur});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"] as int?,
      nama: json["nama"] ?? "",
      umur: json["umur"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {"nama": nama, "umur": umur};
    // PENTING: ID hanya disertakan jika tidak null (untuk update)
    if (id != null) data["id"] = id;
    return data;
  }
}

// --- UI PAGE ---
class ListUserDataPage extends StatefulWidget {
  const ListUserDataPage({super.key});

  @override
  State<ListUserDataPage> createState() => _ListUserDataPageState();
}

class _ListUserDataPageState extends State<ListUserDataPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _umurCtrl = TextEditingController();
  List<UserModel> userList = [];

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  void _reloadData() async {
    final data = await DatabaseHelper.getData();
    setState(() {
      userList = data;
    });
  }

  void _form(int? id) {
    if (id != null) {
      final user = userList.firstWhere((element) => element.id == id);
      _nameCtrl.text = user.nama;
      _umurCtrl.text = user.umur.toString();
    } else {
      _nameCtrl.clear();
      _umurCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SingleChildScrollView( // Agar tidak terhalang keyboard
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                id == null ? "Tambah Data" : "Edit Data",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Nama"),
              ),
              TextField(
                controller: _umurCtrl,
                decoration: const InputDecoration(labelText: "Umur"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameCtrl.text.isNotEmpty && _umurCtrl.text.isNotEmpty) {
                      int? umurInt = int.tryParse(_umurCtrl.text);
                      if (umurInt != null) {
                        _save(id, _nameCtrl.text, umurInt);
                      }
                    }
                  },
                  child: Text(id == null ? "Simpan" : "Update"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save(int? id, String nama, int umur) async {
    final user = UserModel(id: id, nama: nama, umur: umur);
    if (id == null) {
      await DatabaseHelper.insertData(user);
    } else {
      await DatabaseHelper.updateData(user);
    }
    
    _nameCtrl.clear();
    _umurCtrl.clear();
    
    if (mounted) Navigator.pop(context); 
    _reloadData(); // Memperbarui daftar setelah simpan
  }

  void _delete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Apakah anda yakin menghapus data ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.deleteData(id);
              _reloadData();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajemen User SQFlite"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: userList.isEmpty
          ? const Center(child: Text("Data masih kosong"))
          : ListView.builder(
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final user = userList[index];
                return ListTile(
                  title: Text(user.nama),
                  subtitle: Text("${user.umur} Tahun"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _form(user.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(user.id!),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
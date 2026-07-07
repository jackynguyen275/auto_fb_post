import 'package:flutter/material.dart';
import '../services/facebook_service.dart';
import '../services/firebase_service.dart';
import '../models/fanpage_model.dart';
import '../models/project_model.dart';
import 'home_screen.dart';

class ProjectCreateScreen extends StatefulWidget {
  const ProjectCreateScreen({super.key});

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final FacebookService _fbService = FacebookService();
  final FirebaseService _fbDb = FirebaseService();

  List<FanpageModel> _fanpages = [];
  FanpageModel? _selectedPage;
  bool _loadingPages = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadFanpages();
  }

  Future<void> _loadFanpages() async {
    final data = await _fbService.getFanpages();
    setState(() {
      _fanpages = data.map((e) => FanpageModel.fromMap(e)).toList();
      _loadingPages = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedPage == null) return;
    setState(() => _isSubmitting = true);

    final project = ProjectModel(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      pageId: _selectedPage!.id,
      pageName: _selectedPage!.name,
      pageToken: _selectedPage!.accessToken,
      userId: _fbDb.currentUserId!,
      createdAt: DateTime.now(),
    );

    final result = await _fbDb.createProject(project);
    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tạo dự án thành công!")),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo dự án mới")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Tên dự án"),
                validator: (value) => value!.isEmpty ? "Vui lòng nhập tên dự án" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Mô tả dự án, lĩnh vực, địa điểm tại TPHCM"),
                validator: (value) => value!.isEmpty ? "Vui lòng nhập mô tả" : null,
              ),
              const SizedBox(height: 16),
              const Text("Chọn Fanpage sẽ đăng bài:"),
              const SizedBox(height: 8),
              _loadingPages
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<FanpageModel>(
                      value: _selectedPage,
                      items: _fanpages
                          .map((page) => DropdownMenuItem(
                                value: page,
                                child: Text(page.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedPage = value),
                      validator: (value) => value == null ? "Vui lòng chọn Fanpage" : null,
                    ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Tạo dự án"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
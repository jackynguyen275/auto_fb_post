import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project_model.dart';
import '../services/firebase_service.dart';

class ScheduleScreen extends StatefulWidget {
  final ProjectModel project;
  const ScheduleScreen({super.key, required this.project});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseService _fbService = FirebaseService();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveSchedule() async {
    if (_selectedDate == null || _selectedTime == null) return;
    setState(() => _isSaving = true);

    final scheduleTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    await _fbService.addSchedule(widget.project.id!, scheduleTime);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã lưu lịch đăng bài thành công!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cài lịch đăng bài")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chọn thời gian đăng bài:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_selectedDate == null
                  ? "Chọn ngày"
                  : "Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            ListTile(
              title: Text(_selectedTime == null
                  ? "Chọn giờ"
                  : "Giờ: ${_selectedTime!.format(context)}"),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isSaving || _selectedDate == null || _selectedTime == null)
                    ? null
                    : _saveSchedule,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Lưu lịch"),
              ),
            ),
            const SizedBox(height: 32),
            const Text("Lịch đã tạo:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder(
                stream: _fbService.getProjectSchedules(widget.project.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Chưa có lịch nào"));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final time = DateTime.parse(doc['scheduledAt']);
                      final isPosted = doc['isPosted'] ?? false;
                      return Card(
                        child: ListTile(
                          title: Text(DateFormat('HH:mm - dd/MM/yyyy').format(time)),
                          trailing: Icon(
                            isPosted ? Icons.check_circle : Icons.schedule,
                            color: isPosted ? Colors.green : Colors.orange,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
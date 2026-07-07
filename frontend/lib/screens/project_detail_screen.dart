import 'package:flutter/material.dart';
import '../models/project_model.dart';
import 'ai_chat_screen.dart';
import 'schedule_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final ProjectModel project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(project.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Fanpage: ${project.pageName}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text("Mô tả:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(project.description),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text("Trợ lý AI riêng cho dự án"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AiChatScreen(project: project)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                label: const Text("Cài lịch đăng bài tự động"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ScheduleScreen(project: project)),
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
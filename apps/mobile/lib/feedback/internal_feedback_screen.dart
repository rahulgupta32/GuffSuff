import 'dart:io';
import 'package:flutter/material.dart';
import '../core/branding/app_theme.dart';
import '../core/config/app_config.dart';

class InternalFeedbackScreen extends StatefulWidget {
  const InternalFeedbackScreen({super.key});

  @override
  State<InternalFeedbackScreen> createState() => _InternalFeedbackScreenState();
}

class _InternalFeedbackScreenState extends State<InternalFeedbackScreen> {
  String selectedCategory = 'UI/UX Polish';
  final TextEditingController descriptionController = TextEditingController();
  bool isSubmitted = false;

  final List<String> categories = [
    'UI/UX Polish',
    'Feature Request',
    'Performance Issue',
    'Localization (Nepali)',
    'Other',
  ];

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (descriptionController.text.trim().isEmpty) return;
    setState(() => isSubmitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Internal Feedback')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child:
              isSubmitted
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Thank you for your feedback!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Feedback attached to internal release triage.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items:
                            categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => selectedCategory = v);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextField(
                          controller: descriptionController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            hintText:
                                'Describe your feedback or observation for GuffSuff internal demo...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attached Metadata',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'App Version: ${AppConfig.appVersion} (${AppConfig.commitSha})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Device OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          child: const Text('Submit Feedback'),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

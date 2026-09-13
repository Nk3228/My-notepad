import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workspace.dart';

class OnboardingPage extends StatefulWidget {
  final Future<void> Function(List<String>) onComplete;

  const OnboardingPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final Set<String> selected = {};

  final List<Map<String, dynamic>> categories = [
    {'name': 'Student', 'icon': Icons.school_outlined},
    {'name': 'Office / Worker', 'icon': Icons.work_outline},
    {'name': 'Freelancer', 'icon': Icons.laptop_mac_outlined},
    {'name': 'Business Owner', 'icon': Icons.storefront_outlined},
    {'name': 'Content Creator', 'icon': Icons.video_camera_back_outlined},
    {'name': 'Teacher', 'icon': Icons.cast_for_education_outlined},
    {'name': 'Exam Preparation', 'icon': Icons.menu_book_outlined},
    {'name': 'Personal', 'icon': Icons.person_outline},
    {'name': 'Writer', 'icon': Icons.edit_note_outlined},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  void toggle(String name) {
    setState(() {
      if (selected.contains(name)) {
        selected.remove(name);
      } else {
        selected.add(name);
      }
    });
  }

  Future<void> finish() async {
    if (selected.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final existingFolders = prefs.getStringList('folders') ?? [
      'General',
      'Study',
      'Work',
      'Personal',
    ];

    final recommended = <String>{};

    if (selected.contains('Student')) {
      recommended.addAll([
        'Subjects',
        'Assignments',
        'Exam Preparation',
        'Important Notes',
      ]);
    }

    if (selected.contains('Office / Worker')) {
      recommended.addAll([
        'Meetings',
        'Tasks',
        'Projects',
        'Important',
      ]);
    }

    if (selected.contains('Freelancer')) {
      recommended.addAll([
        'Clients',
        'Projects',
        'Ideas',
        'Payments',
      ]);
    }

    if (selected.contains('Business Owner')) {
      recommended.addAll([
        'Customers',
        'Orders',
        'Expenses',
        'Business Ideas',
      ]);
    }

    if (selected.contains('Content Creator')) {
      recommended.addAll([
        'Video Ideas',
        'Scripts',
        'Captions',
        'Research',
      ]);
    }

    if (selected.contains('Teacher')) {
      recommended.addAll([
        'Classes',
        'Lesson Plans',
        'Students',
        'Teaching Notes',
      ]);
    }

    if (selected.contains('Exam Preparation')) {
      recommended.addAll([
        'Study Plan',
        'Topics',
        'Questions',
        'Revision',
      ]);
    }

    if (selected.contains('Personal')) {
      recommended.addAll([
        'Daily Notes',
        'Ideas',
        'Shopping',
        'Personal Goals',
      ]);
    }

    if (selected.contains('Writer')) {
      recommended.addAll([
        'Story Ideas',
        'Drafts',
        'Characters',
        'Research',
      ]);
    }

    final folders = [...existingFolders];
    for (final folder in recommended) {
      if (!folders.contains(folder)) {
        folders.add(folder);
      }
    }

    await prefs.setStringList('userCategories', selected.toList());
    await prefs.setStringList('folders', folders);
    await prefs.setBool('onboardingCompleted', true);

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkspaceReadyPage(
          categories: selected.toList(),
          folders: recommended.toList(),
          onComplete: widget.onComplete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.note_alt_rounded,
                size: 48,
              ),
              const SizedBox(height: 18),
              const Text(
                'Welcome to My Notepad',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Aap My Notepad ka use kisliye karenge?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Aap ek se zyada options select kar sakte hain.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    final name = item['name'] as String;
                    final icon = item['icon'] as IconData;
                    final isSelected = selected.contains(name);

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => toggle(name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 28),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: finish,
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

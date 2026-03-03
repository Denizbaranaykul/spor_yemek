import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _noteController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _notificationService = NotificationService();
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;

    DateTime? reminderDateTime;
    if (_selectedTime != null) {
      final now = DateTime.now();
      reminderDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      // If the selected time has already passed today, schedule for tomorrow
      if (reminderDateTime.isBefore(now)) {
        reminderDateTime = reminderDateTime.add(const Duration(days: 1));
      }
    }

    try {
      final note = NoteModel(
        text: _noteController.text.trim(),
        reminderTime: reminderDateTime?.toUtc(),
        timestamp: DateTime.now().toUtc(),
      );

      await _firestoreService.addNote(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        _noteController.clear();
        setState(() {
          _selectedTime = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notlar ve Hatırlatıcılar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.deepPurple.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yeni Not Ekle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'Notunuzu buraya yazın...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectTime(context),
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _selectedTime != null
                                  ? 'Saat: ${_selectedTime!.format(context)}'
                                  : 'Hatırlatıcı Saati Seç',
                            ),
                          ),
                        ),
                        if (_selectedTime != null)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _selectedTime = null;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<NoteModel>>(
              stream: _firestoreService.getNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                final notes = snapshot.data ?? [];

                if (notes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Henüz kaydedilmiş not yok.'),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kaydedilen Notlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...notes.map((note) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.note, color: Colors.deepPurpleAccent),
                            title: Text(note.text),
                            subtitle: note.reminderTime != null
                                ? Text(
                                    'Hatırlatıcı: ${note.reminderTime!.day}/${note.reminderTime!.month} ${note.reminderTime!.hour.toString().padLeft(2, '0')}:${note.reminderTime!.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.amber),
                                  )
                                : null,
                            trailing: Text(
                              '${note.timestamp.day}/${note.timestamp.month}/${note.timestamp.year}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

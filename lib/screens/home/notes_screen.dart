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
  final Set<int> _selectedDays = {}; // 1 (Mon) to 7 (Sun)
  final List<String> _daysOfWeek = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

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
        repeatDays: _selectedDays.isNotEmpty ? _selectedDays.toList() : null,
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
          _selectedDays.clear();
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
                    if (_selectedTime != null) ...[
                      const SizedBox(height: 16),
                      const Text('Tekrarlanacak Günler (İsteğe Bağlı):'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: List.generate(7, (index) {
                          final dayInt = index + 1;
                          final isSelected = _selectedDays.contains(dayInt);
                          return FilterChip(
                            label: Text(_daysOfWeek[index]),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDays.add(dayInt);
                                } else {
                                  _selectedDays.remove(dayInt);
                                }
                              });
                            },
                            selectedColor: Colors.deepPurpleAccent.withOpacity(0.5),
                            checkmarkColor: Colors.white,
                          );
                        }),
                      ),
                    ],
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
                    ...notes.map((note) => Dismissible(
                          key: Key(note.id ?? note.timestamp.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            if (note.id != null) {
                              _firestoreService.deleteNote(note.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Not silindi')),
                              );
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.note, color: Colors.deepPurpleAccent),
                              title: Text(
                                note.text,
                                style: TextStyle(
                                  decoration: note.isSent ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (note.reminderTime != null)
                                    Text(
                                      'Hatırlatıcı: ${note.reminderTime!.toLocal().day}/${note.reminderTime!.toLocal().month} ${note.reminderTime!.toLocal().hour.toString().padLeft(2, '0')}:${note.reminderTime!.toLocal().minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                          color: note.isSent ? Colors.grey : Colors.amber),
                                    ),
                                  if (note.repeatDays != null && note.repeatDays!.isNotEmpty)
                                    Text(
                                      'Tekrar: ${note.repeatDays!.map((d) => _daysOfWeek[d - 1]).join(', ')}',
                                      style: TextStyle(
                                          color: note.isSent ? Colors.grey : Colors.cyanAccent, fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${note.timestamp.toLocal().day}/${note.timestamp.toLocal().month}/${note.timestamp.toLocal().year}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  if (!note.isSent && note.reminderTime != null)
                                    Builder(
                                      builder: (context) {
                                        final now = DateTime.now();
                                        final reminderLocal = note.reminderTime!.toLocal();
                                        final isToday = reminderLocal.year == now.year &&
                                            reminderLocal.month == now.month &&
                                            reminderLocal.day == now.day;
                                        final isPast = reminderLocal.isBefore(now);
                                        final isClickable = isToday || isPast;

                                        return IconButton(
                                          icon: Icon(
                                            Icons.check_circle_outline,
                                            color: isClickable ? Colors.green : Colors.grey.withOpacity(0.5),
                                          ),
                                          onPressed: () {
                                            if (!isClickable) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Bu hatırlatıcı henüz bugünün görevi değil!'),
                                                ),
                                              );
                                              return;
                                            }
                                            if (note.id != null) {
                                              _firestoreService.markNoteAsSent(note);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Hatırlatıcı tamamlandı olarak işaretlendi'),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                                ],
                              ),
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

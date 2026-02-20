// lib/widgets/note_input.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class NoteInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(DateTime?)? onSendWithDateTime;

  const NoteInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onSendWithDateTime,
  });

  @override
  State<NoteInput> createState() => _NoteInputState();
}

class _NoteInputState extends State<NoteInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _showDateTimePicker(BuildContext context) async {
    final now = DateTime.now();
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (selectedDate == null) return;
    
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    
    if (selectedTime == null) return;
    
    final finalDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    
    if (widget.onSendWithDateTime != null) {
      widget.onSendWithDateTime!(finalDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 10, // Максимум 10 строк, после этого появится прокрутка
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.hintText,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onLongPress: widget.onSendWithDateTime != null
                ? () => _showDateTimePicker(context)
                : null,
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                widget.onSend();
                _focusNode.requestFocus();
              },
            ),
          ),
        ],
      ),
    );
  }
}

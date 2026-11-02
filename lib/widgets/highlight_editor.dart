import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/highlight_colors.dart';

/// Opens the panel to choose a color and write a note.
/// quick = true: only the colors; tapping a color saves at once.
/// isEdit = true: an existing highlight (a delete button is shown).
void showHighlightEditor(
  BuildContext context, {
  required String text,
  required int initialColor,
  String initialNote = '',
  required bool quick,
  required bool isEdit,
  required void Function(int color, String note) onSave,
  VoidCallback? onDelete,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _EditorSheet(
      text: text,
      initialColor: initialColor,
      initialNote: initialNote,
      quick: quick,
      isEdit: isEdit,
      onSave: onSave,
      onDelete: onDelete,
    ),
  );
}

class _EditorSheet extends StatefulWidget {
  final String text;
  final int initialColor;
  final String initialNote;
  final bool quick;
  final bool isEdit;
  final void Function(int color, String note) onSave;
  final VoidCallback? onDelete;

  const _EditorSheet({
    required this.text,
    required this.initialColor,
    required this.initialNote,
    required this.quick,
    required this.isEdit,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  late int _color = widget.initialColor;
  late final TextEditingController _note =
      TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(_color, _note.text.trim());
    Navigator.pop(context);
  }

  void _pick(int index) {
    setState(() => _color = index);
    // Quick highlight: one tap on a color is enough.
    if (widget.quick && !widget.isEdit) _save();
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);
    final preview = widget.text.length > 140
        ? '${widget.text.substring(0, 140)}…'
        : widget.text;

    return Padding(
      // Keep the panel above the keyboard.
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The text that is marked.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: highlightColor(_color, ui),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                preview,
                style: TextStyle(color: ui.text, height: 1.8, fontSize: 14),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.quick ? 'یک رنگ انتخاب کنید' : 'رنگ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < highlightNames.length; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 14),
                    child: GestureDetector(
                      onTap: () => _pick(i),
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: highlightColor(i, ui),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: i == _color
                                    ? ui.accent
                                    : ui.divider,
                                width: i == _color ? 3 : 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            highlightNames[i],
                            style: TextStyle(color: ui.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (!widget.quick) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _note,
                autofocus: !widget.isEdit,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'یادداشت شما (اختیاری)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.isEdit && widget.onDelete != null)
                    TextButton.icon(
                      onPressed: () {
                        widget.onDelete!();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('حذف'),
                    ),
                  const Spacer(),
                  FilledButton(onPressed: _save, child: const Text('ذخیره')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

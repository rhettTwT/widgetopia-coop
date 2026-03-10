import 'package:flutter/material.dart';
import '../models/note_model.dart';

class ChecklistItemTile extends StatelessWidget{
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(), 
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onDelete(),
      background: Container(color: Colors.red),
      child: ListTile(
        leading: Checkbox(
          value: item.done,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          item.text,
          style: TextStyle(
            decoration: 
                item.done ? TextDecoration.lineThrough : TextDecoration.none,
            color: item.done ? Colors.grey : null,
          ), 
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class QueryInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;

  const QueryInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.enabled = true,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  State<QueryInputField> createState() => _QueryInputFieldState();
}

class _QueryInputFieldState extends State<QueryInputField> {
  @override
  void initState() {
    super.initState();
    // Listen to controller changes to update suffix icon visibility
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      maxLines: 3,
      minLines: 1,
      textInputAction: TextInputAction.search,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Ask anything about your project...',
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        prefixIcon: Icon(
          Icons.psychology_outlined,
          color: colorScheme.primary,
        ),
        suffixIcon: widget.controller.text.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged?.call('');
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: widget.enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      onPressed: widget.enabled
                          ? () => widget.onSubmitted?.call(widget.controller.text)
                          : null,
                    ),
                  ),
                ],
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
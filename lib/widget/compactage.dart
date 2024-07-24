import 'package:flutter/material.dart';

class CompactAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final String loadingText;
  final List<Widget> actions;

  const CompactAppBar({
    super.key,
    required this.isLoading,
    required this.loadingText,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: AppBar(
        toolbarHeight: 40, // Hauteur réduite
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isLoading
              ? Text(
            loadingText,
            key: const ValueKey<bool>(true),
            style: const TextStyle(fontSize: 14, color: Colors.black),
          )
              : const SizedBox.shrink(key: ValueKey<bool>(false)),
        ),
        actions: isLoading
            ? []
            : [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions.map((widget) {
                if (widget is IconButton) {
                  return IconButton(
                    icon: widget.icon,
                    onPressed: widget.onPressed,
                    tooltip: widget.tooltip,
                    iconSize: 18, // Taille d'icône réduite
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  );
                }
                return widget;
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(40);
}

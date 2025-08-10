import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final Color? backgroundColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onPressed != null && !widget.isLoading
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered && !widget.isLoading
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isSecondary
                  ? Colors.transparent
                  : (widget.backgroundColor ?? kPrimaryColor),
              foregroundColor: widget.isSecondary
                  ? kPrimaryColor
                  : Colors.white,
              elevation: widget.isSecondary ? 0 : (_isHovered ? 4 : 2),
              side: widget.isSecondary
                  ? BorderSide(
                      color: kPrimaryColor,
                      width: _isHovered ? 2 : 1.5,
                    )
                  : null,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20),
                        const SizedBox(width: 12),
                      ],
                      Text(widget.text),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

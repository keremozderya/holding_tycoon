// lib/widgets/tycoon_buttons.dart
import 'package:flutter/material.dart' hide AnimatedContainer, Container, Icon, Text;
import 'adaptive_widgets.dart';
import 'package:flutter/services.dart';

class HeavyTycoonButton extends StatefulWidget {
  final VoidCallback? onTap; final Widget child; final Color color; final Color shadowColor; final double height; final double? width; final EdgeInsetsGeometry? padding; final VoidCallback? onPressed; 
  const HeavyTycoonButton({super.key, this.onTap, this.onPressed, required this.child, required this.color, required this.shadowColor, this.height = 50, this.width, this.padding});
  @override State<HeavyTycoonButton> createState() => _HeavyTycoonButtonState();
}

class _HeavyTycoonButtonState extends State<HeavyTycoonButton> {
  bool _isPressed = false;
  @override Widget build(BuildContext context) {
    final VoidCallback? action = widget.onTap ?? widget.onPressed;
    final bool isDisabled = action == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: isDisabled ? null : (_) { setState(() => _isPressed = true); },
      onTapUp: isDisabled ? null : (_) { setState(() => _isPressed = false); },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: isDisabled ? null : () { HapticFeedback.lightImpact(); action(); },
      child: SizedBox(
        width: widget.width, height: widget.height,
        child: Stack(
          children: [
            Positioned(bottom: 0, left: 0, right: 0, top: 8, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade400 : widget.shadowColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3.0)))),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              bottom: _isPressed || isDisabled ? 0 : 8, left: 0, right: 0, top: _isPressed || isDisabled ? 8 : 0,
              child: Container(padding: widget.padding, decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade300 : widget.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3.0)), child: Center(child: widget.child)),
            ),
          ],
        ),
      ),
    );
  }
}

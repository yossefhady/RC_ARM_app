import 'package:flutter/material.dart';

class AnimatedNumber extends StatefulWidget {
  final int value;
  final TextStyle style;
  final bool padded;
  final int padLength;
  final Duration duration;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.padded = false,
    this.padLength = 3,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<int> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = IntTween(
      begin: widget.value,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = IntTween(
        begin: _anim.value,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final str = widget.padded
            ? _anim.value.toString().padLeft(widget.padLength, '0')
            : _anim.value.toString();
        return Text(str, style: widget.style);
      },
    );
  }
}

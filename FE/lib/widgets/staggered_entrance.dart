import 'package:flutter/material.dart';
import '../config/theme/app_motion.dart';

/// Fades + slides [child] in once, after [trigger] first becomes true.
/// [index] staggers the start delay across a sequence of siblings sharing
/// the same trigger source. Latches after the first play so later rebuilds
/// (e.g. an unrelated BLoC state change) never replay it. Collapses to an
/// instant no-op under reduced motion.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final int index;

  const StaggeredEntrance({
    super.key,
    required this.child,
    required this.trigger,
    this.index = 0,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> {
  bool _played = false;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybePlay();
  }

  @override
  void didUpdateWidget(covariant StaggeredEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay();
  }

  void _maybePlay() {
    if (_played || !widget.trigger) return;
    _played = true;

    if (MediaQuery.of(context).disableAnimations) {
      setState(() => _visible = true);
      return;
    }
    Future.delayed(AppMotion.stagger * widget.index, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppMotion.base,
      curve: AppMotion.entrance,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.05),
        duration: AppMotion.base,
        curve: AppMotion.entrance,
        child: widget.child,
      ),
    );
  }
}

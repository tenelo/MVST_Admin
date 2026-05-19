import 'package:flutter/material.dart';

class ClavierNumerique extends StatelessWidget {
  final void Function(String) onChiffre;
  final VoidCallback onSupprimer;
  final dynamic colors;
  final double sw;
  final bool desactive;
  final double scale;

  const ClavierNumerique({
    super.key,
    required this.onChiffre,
    required this.onSupprimer,
    required this.colors,
    required this.sw,
    this.desactive = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final touches = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    final btnSize = (sw * 0.18).clamp(55.0, 80.0);
    final spacing = (sw * 0.05).clamp(7.0, 18.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
      child: Column(
        children: touches.map((ligne) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: spacing * 0.35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ligne.map((touche) {
                if (touche.isEmpty) {
                  return SizedBox(width: btnSize, height: btnSize * 0.85);
                }
                return ClavierAnime(
                  touche: touche,
                  onChiffre: onChiffre,
                  onSupprimer: onSupprimer,
                  colors: c,
                  size: btnSize,
                  desactive: desactive,
                  scale: scale,
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ClavierAnime extends StatelessWidget {
  final String touche;
  final void Function(String) onChiffre;
  final VoidCallback onSupprimer;
  final dynamic colors;
  final double size;
  final bool desactive;
  final double scale;

  const ClavierAnime({
    super.key,
    required this.touche,
    required this.onChiffre,
    required this.onSupprimer,
    required this.colors,
    required this.size,
    this.desactive = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    (size * 0.34).clamp(20.0, 28.0);

    return _AnimatedTouche(
      touche: touche,
      onChiffre: onChiffre,
      onSupprimer: onSupprimer,
      colors: c,
      size: size,
      desactive: desactive,
      scale: scale,
    );
  }
}

class _AnimatedTouche extends StatefulWidget {
  const _AnimatedTouche({
    required this.touche,
    required this.onChiffre,
    required this.onSupprimer,
    required this.colors,
    required this.size,
    this.desactive = false,
    this.scale = 1.0,
  });
  final String touche;
  final void Function(String) onChiffre;
  final VoidCallback onSupprimer;
  final dynamic colors;
  final double size;
  final bool desactive;
  final double scale;

  @override
  State<_AnimatedTouche> createState() => _AnimatedToucheState();
}

class _AnimatedToucheState extends State<_AnimatedTouche>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _highlighted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.86).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeIn,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.desactive) return;
    setState(() => _highlighted = true);
    _ctrl.forward().then((_) {
      _ctrl.reverse();
      Future.delayed(const Duration(milliseconds: 130), () {
        if (mounted) setState(() => _highlighted = false);
      });
    });
    if (widget.touche == '⌫') {
      widget.onSupprimer();
    } else {
      widget.onChiffre(widget.touche);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final fontSize = (widget.size * 0.34).clamp(20.0, 28.0);
    return GestureDetector(
      onTap: widget.desactive ? null : _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.size,
          height: widget.size * 0.85,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _highlighted
                ? c.authAccent.withValues(alpha: 0.20)
                : widget.desactive
                ? c.authCardBackground.withValues(alpha: 0.3)
                : c.authCardBackground,
            borderRadius: BorderRadius.circular(12 * widget.scale),
            boxShadow: _highlighted
                ? [
                    BoxShadow(
                      color: c.authAccent.withValues(alpha: 0.22),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: widget.touche == '⌫'
              ? Icon(
                  Icons.backspace_outlined,
                  color: widget.desactive
                      ? c.authTextPrimary.withValues(alpha: 0.2)
                      : _highlighted
                      ? c.authAccent
                      : c.authTextPrimary,
                  size: fontSize * 0.9,
                )
              : Text(
                  widget.touche,
                  style: TextStyle(
                    color: widget.desactive
                        ? c.authTextPrimary.withValues(alpha: 0.2)
                        : _highlighted
                        ? c.authAccent
                        : c.authTextPrimary,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

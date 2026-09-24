import 'package:flutter/material.dart';

enum SiapNotificationType {
  information,
  success,
  warning,
  error,
}

Future<void> showSiapTopNotification({
  required BuildContext context,
  required String title,
  required String message,
  SiapNotificationType type = SiapNotificationType.information,
  String? primaryButtonLabel,
  bool barrierDismissible = true,
  Duration duration = const Duration(seconds: 3),
}) {
  final _SiapNotificationVisual visual =
      _SiapNotificationVisual.fromType(type);
  final bool hasAction = primaryButtonLabel != null;

  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: hasAction ? barrierDismissible : true,
    barrierLabel: title,
    barrierColor: const Color(0x1A000000),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (
      BuildContext dialogContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      final Size screenSize = MediaQuery.sizeOf(dialogContext);
      final double horizontalMargin = screenSize.width < 420 ? 16 : 24;

      return SafeArea(
        minimum: EdgeInsets.fromLTRB(
          horizontalMargin,
          14,
          horizontalMargin,
          16,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: _SiapTopNotificationCard(
                title: title,
                message: message,
                visual: visual,
                primaryButtonLabel: primaryButtonLabel,
                duration: duration,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.14),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _SiapTopNotificationCard extends StatefulWidget {
  final String title;
  final String message;
  final _SiapNotificationVisual visual;
  final String? primaryButtonLabel;
  final Duration duration;

  const _SiapTopNotificationCard({
    required this.title,
    required this.message,
    required this.visual,
    required this.primaryButtonLabel,
    required this.duration,
  });

  @override
  State<_SiapTopNotificationCard> createState() =>
      _SiapTopNotificationCardState();
}

class _SiapTopNotificationCardState
    extends State<_SiapTopNotificationCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _progressController;

  bool get _hasAction => widget.primaryButtonLabel != null;

  @override
  void initState() {
    super.initState();

    if (!_hasAction) {
      _progressController = AnimationController(
        vsync: this,
        duration: widget.duration,
        value: 1,
      )
        ..addStatusListener(_handleProgressStatus)
        ..reverse();
    }
  }

  void _handleProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _progressController
      ?..removeStatusListener(_handleProgressStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.visual.accent.withOpacity(0.42),
          width: 1.1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              17,
              18,
              _hasAction ? 16 : 15,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.visual.softBackground,
                      ),
                      child: Icon(
                        widget.visual.icon,
                        color: widget.visual.accent,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Color(0xFF1D1D1D),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Color(0xFF5E5A52),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_hasAction) ...<Widget>[
                  const SizedBox(height: 17),
                  SizedBox(
                    width: double.infinity,
                    height: 43,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.visual.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      child: Text(widget.primaryButtonLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!_hasAction && _progressController != null)
            AnimatedBuilder(
              animation: _progressController!,
              builder: (
                BuildContext context,
                Widget? child,
              ) {
                return LinearProgressIndicator(
                  value: _progressController!.value,
                  minHeight: 3,
                  backgroundColor:
                      widget.visual.softBackground.withOpacity(0.72),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.visual.accent,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SiapNotificationVisual {
  final Color accent;
  final Color softBackground;
  final IconData icon;

  const _SiapNotificationVisual({
    required this.accent,
    required this.softBackground,
    required this.icon,
  });

  factory _SiapNotificationVisual.fromType(
    SiapNotificationType type,
  ) {
    switch (type) {
      case SiapNotificationType.success:
        return const _SiapNotificationVisual(
          accent: Color(0xFF2F7D32),
          softBackground: Color(0xFFE6F4DF),
          icon: Icons.task_alt_rounded,
        );
      case SiapNotificationType.warning:
        return const _SiapNotificationVisual(
          accent: Color(0xFFB3261E),
          softBackground: Color(0xFFFFE7E5),
          icon: Icons.warning_amber_rounded,
        );
      case SiapNotificationType.error:
        return const _SiapNotificationVisual(
          accent: Color(0xFFB3261E),
          softBackground: Color(0xFFFFE7E5),
          icon: Icons.error_outline_rounded,
        );
      case SiapNotificationType.information:
        return const _SiapNotificationVisual(
          accent: Color(0xFF9D6A18),
          softBackground: Color(0xFFFFEFD1),
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

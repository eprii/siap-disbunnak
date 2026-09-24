import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/feedback/siap_top_notification.dart';
import '../../widgets/navigation/bottom_navigation_bar.dart';
import '../pegawai/detail_pegawai_page.dart';

class NotificationPage extends StatefulWidget {
  final bool isAdmin;

  const NotificationPage({
    super.key,
    required this.isAdmin,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const String _backgroundAsset =
      'assets/images/background/background_image.png';
  static const Color _accent = Color(0xFF9D6A18);
  static const Color _selectedTab = Color(0xFFDCEBC6);
  static const Color _card = Color(0xFFFFFCF6);
  static const Color _text = Color(0xFF171717);
  static const Color _muted = Color(0xFF77736B);

  final ScrollController _scrollController = ScrollController();

  late final Stream<List<SiapNotificationModel>> _notificationsStream;
  late final Stream<int> _unreadCountStream;

  _NotificationFilter _selectedFilter = _NotificationFilter.all;
  bool _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    _notificationsStream =
        NotificationService.instance.watchCurrentNotifications();
    _unreadCountStream =
        NotificationService.instance.watchUnreadCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<SiapNotificationModel> _applyFilter(
    List<SiapNotificationModel> source,
  ) {
    switch (_selectedFilter) {
      case _NotificationFilter.all:
        return source;
      case _NotificationFilter.information:
        return source
            .where(
              (SiapNotificationModel item) =>
                  item.category ==
                  SiapNotificationCategory.information,
            )
            .toList();
      case _NotificationFilter.warning:
        return source
            .where(
              (SiapNotificationModel item) =>
                  item.category == SiapNotificationCategory.warning,
            )
            .toList();
      case _NotificationFilter.system:
        return source
            .where(
              (SiapNotificationModel item) =>
                  item.category == SiapNotificationCategory.system,
            )
            .toList();
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) return;

    setState(() => _isMarkingAll = true);

    try {
      await NotificationService.instance.markAllAsRead();
    } catch (error) {
      if (!mounted) return;
      await showSiapTopNotification(
        context: context,
        type: SiapNotificationType.error,
        title: 'Gagal Memperbarui',
        message: _messageOf(error),
      );
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  Future<void> _openNotification(
    SiapNotificationModel notification,
  ) async {
    if (!notification.isRead) {
      try {
        await NotificationService.instance.markAsRead(
          notification.id,
        );
      } catch (_) {
        // Navigasi tetap diteruskan walau status baca belum tersimpan.
      }
    }

    if (!mounted) return;

    if (notification.sourceOwnerId.trim().isNotEmpty &&
        notification.sourceDocumentId.trim().isNotEmpty) {
      await Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => DetailPegawaiPage(
            employeeUid: notification.sourceOwnerId,
            initialSkKey:
                '${notification.sourceCollection}:${notification.sourceDocumentId}',
          ),
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<Offset> position = Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: position,
                child: child,
              ),
            );
          },
        ),
      );
      return;
    }

    if (!widget.isAdmin &&
        notification.eventType == 'profile_updated') {
      SiapNavigationController.selectTab(2);
      Navigator.of(context).pop();
      return;
    }

    await _showDetailDialog(notification);
  }

  Future<void> _showDetailDialog(
    SiapNotificationModel notification,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final _NotificationVisual visual =
            _visualFor(notification);

        return AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: visual.softColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  visual.icon,
                  color: visual.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (notification.message.trim().isNotEmpty)
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF57534C),
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                DateFormatter.formatDateTime(notification.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: _muted,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('TUTUP'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBar = MediaQuery.viewPaddingOf(context).top;
    final double navigationBottom =
        MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                _backgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: const Color(0x0AFFFFFF),
              ),
            ),
            Column(
              children: <Widget>[
                SizedBox(height: statusBar + 14),
                _buildHeader(),
                const SizedBox(height: 14),
                _buildFilters(),
                const SizedBox(height: 18),
                Expanded(
                  child: StreamBuilder<List<SiapNotificationModel>>(
                    stream: _notificationsStream,
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<SiapNotificationModel>> snapshot,
                    ) {
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: _accent,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _NotificationErrorState(
                          message: _messageOf(snapshot.error),
                        );
                      }

                      final List<SiapNotificationModel> allItems =
                          snapshot.data ??
                              const <SiapNotificationModel>[];
                      final List<SiapNotificationModel> visibleItems =
                          _applyFilter(allItems);

                      if (visibleItems.isEmpty) {
                        return _NotificationEmptyState(
                          filter: _selectedFilter,
                        );
                      }

                      return Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: false,
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const ClampingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            20,
                            2,
                            20,
                            100 + navigationBottom,
                          ),
                          itemCount: visibleItems.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (
                            BuildContext context,
                            int index,
                          ) {
                            final SiapNotificationModel notification =
                                visibleItems[index];
                            return _NotificationCard(
                              notification: notification,
                              onTap: () =>
                                  _openNotification(notification),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: navigationBottom + 16,
              child: StreamBuilder<int>(
                stream: _unreadCountStream,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<int> snapshot,
                ) {
                  final int unread = snapshot.data ?? 0;
                  final bool enabled = unread > 0 && !_isMarkingAll;

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x24000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: enabled ? _markAllAsRead : null,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xF7FFFCF3),
                          foregroundColor: const Color(0xFF2D6B2F),
                          disabledForegroundColor:
                              const Color(0xFF9B988F),
                          side: BorderSide(
                            color: enabled
                                ? const Color(0xFF6A9C6B)
                                : const Color(0xFFC7C3BA),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: _isMarkingAll
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2D6B2F),
                                ),
                              )
                            : Text(
                                unread > 0
                                    ? 'Tandai Semua Dibaca'
                                    : 'Semua Notifikasi Sudah Dibaca',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Kembali',
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _text,
              size: 23,
            ),
          ),
          const SizedBox(width: 2),
          const Text(
            'Notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _NotificationFilter.values.map(
          (_NotificationFilter filter) {
            final bool selected = filter == _selectedFilter;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: selected ? _selectedTab : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      if (selected) return;
                      setState(() => _selectedFilter = filter);
                    },
                    child: SizedBox(
                      height: 34,
                      child: Center(
                        child: Text(
                          filter.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? const Color(0xFF396433)
                                : _text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  static String _messageOf(Object? error) {
    if (error is NotificationServiceException) return error.message;
    final String message = error?.toString().trim() ?? '';
    return message.isEmpty
        ? 'Terjadi kesalahan saat memuat notifikasi.'
        : message;
  }
}

class _NotificationCard extends StatelessWidget {
  final SiapNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final _NotificationVisual visual = _visualFor(notification);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Material(
          color: _NotificationPageState._card,
          elevation: 0,
          borderRadius: BorderRadius.circular(13),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.fromLTRB(13, 11, 10, 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0xFFE7DFC9),
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: visual.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      visual.icon,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          notification.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.18,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: _NotificationPageState._text,
                          ),
                        ),
                        if (notification.message.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              color: Color(0xFF5F5B54),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          DateFormatter.formatDateTime(
                            notification.createdAt,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: _NotificationPageState._muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF191919),
                    size: 25,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!notification.isRead)
          const Positioned(
            left: -2,
            top: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFE93232),
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 9, height: 9),
            ),
          ),
      ],
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  final _NotificationFilter filter;

  const _NotificationEmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 0, 36, 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                color: Color(0xFFF4E8C9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _NotificationPageState._accent,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filter == _NotificationFilter.all
                  ? 'Belum ada notifikasi'
                  : 'Belum ada notifikasi ${filter.label.toLowerCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _NotificationPageState._text,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Informasi terbaru akan tampil di halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _NotificationPageState._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationErrorState extends StatelessWidget {
  final String message;

  const _NotificationErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFB3261E),
            ),
            const SizedBox(height: 14),
            const Text(
              'Notifikasi tidak dapat dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: _NotificationPageState._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NotificationFilter {
  all('Semua'),
  information('Informasi'),
  warning('Peringatan'),
  system('Sistem');

  final String label;

  const _NotificationFilter(this.label);
}

class _NotificationVisual {
  final IconData icon;
  final Color color;
  final Color softColor;

  const _NotificationVisual({
    required this.icon,
    required this.color,
    required this.softColor,
  });
}

_NotificationVisual _visualFor(
  SiapNotificationModel notification,
) {
  switch (notification.eventType) {
    case 'sk_approved':
    case 'sk_submitted':
      return const _NotificationVisual(
        icon: Icons.check_rounded,
        color: Color(0xFF33963C),
        softColor: Color(0xFFE1F3DD),
      );
    case 'profile_updated':
      return const _NotificationVisual(
        icon: Icons.school_rounded,
        color: Color(0xFF65BB71),
        softColor: Color(0xFFE4F4E1),
      );
    case 'sk_rejected':
      return const _NotificationVisual(
        icon: Icons.edit_note_rounded,
        color: Color(0xFFE56C63),
        softColor: Color(0xFFFBE5E2),
      );
    case 'comment_added':
    case 'reply_added':
      return const _NotificationVisual(
        icon: Icons.forum_rounded,
        color: Color(0xFFB7790A),
        softColor: Color(0xFFF7EAC9),
      );
    case 'system_maintenance':
    case 'system_announcement':
    case 'app_update':
      return const _NotificationVisual(
        icon: Icons.build_rounded,
        color: Color(0xFF8870E8),
        softColor: Color(0xFFE9E3FF),
      );
  }

  switch (notification.category) {
    case SiapNotificationCategory.information:
      return const _NotificationVisual(
        icon: Icons.description_rounded,
        color: Color(0xFF1F68B4),
        softColor: Color(0xFFDDEBFA),
      );
    case SiapNotificationCategory.warning:
      return const _NotificationVisual(
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFE79A0B),
        softColor: Color(0xFFFFEBC5),
      );
    case SiapNotificationCategory.system:
      return const _NotificationVisual(
        icon: Icons.build_rounded,
        color: Color(0xFF8870E8),
        softColor: Color(0xFFE9E3FF),
      );
  }
}

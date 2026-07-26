import 'package:flutter/material.dart';

import '../../services/profile_photo_service.dart';

class PegawaiAvatar extends StatefulWidget {
  final String storedPhoto;
  final double radius;
  final Color backgroundColor;
  final Color iconColor;

  const PegawaiAvatar({
    super.key,
    required this.storedPhoto,
    required this.radius,
    this.backgroundColor = const Color(0xFFE9D3A6),
    this.iconColor = const Color(0xFF8B570B),
  });

  @override
  State<PegawaiAvatar> createState() => _PegawaiAvatarState();
}

class _PegawaiAvatarState extends State<PegawaiAvatar> {
  static final Map<String, Future<String>> _urlCache =
      <String, Future<String>>{};

  late Future<String> _photoUrlFuture;

  @override
  void initState() {
    super.initState();
    _photoUrlFuture = _resolve(widget.storedPhoto);
  }

  @override
  void didUpdateWidget(covariant PegawaiAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storedPhoto != widget.storedPhoto) {
      _photoUrlFuture = _resolve(widget.storedPhoto);
    }
  }

  Future<String> _resolve(String storedPhoto) {
    final String cleanValue = storedPhoto.trim();
    if (cleanValue.isEmpty) return Future<String>.value('');
    if (cleanValue.startsWith('http')) {
      return Future<String>.value(cleanValue);
    }

    return _urlCache.putIfAbsent(
      cleanValue,
      () => ProfilePhotoService.instance.resolvePhotoUrl(cleanValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _photoUrlFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<String> snapshot,
      ) {
        final String url = snapshot.data?.trim() ?? '';

        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: widget.backgroundColor,
          foregroundImage: url.isEmpty ? null : NetworkImage(url),
          onForegroundImageError: url.isEmpty
              ? null
              : (_, _) {
                  _urlCache.remove(widget.storedPhoto.trim());
                },
          child: url.isEmpty
              ? Icon(
                  Icons.person_rounded,
                  size: widget.radius * 1.18,
                  color: widget.iconColor,
                )
              : null,
        );
      },
    );
  }
}

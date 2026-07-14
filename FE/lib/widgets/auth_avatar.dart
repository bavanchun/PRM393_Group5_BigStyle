import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../config/supabase/supabase_config.dart';

class AuthAvatar extends StatefulWidget {
  final String? url;
  final double radius;
  final Color? backgroundColor;
  final Widget? fallback;

  const AuthAvatar({
    super.key,
    required this.url,
    this.radius = 28,
    this.backgroundColor,
    this.fallback,
  });

  @override
  State<AuthAvatar> createState() => _AuthAvatarState();
}

class _AuthAvatarState extends State<AuthAvatar> {
  Uint8List? _bytes;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AuthAvatar old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _hasError = false;
      _bytes = null;
      _load();
    }
  }

  String? _extractPath(String url) {
    final storageUrl = '${SupabaseConfig.supabaseUrl}/storage/v1';
    final prefixes = [
      '$storageUrl/object/public/avatars/',
      '$storageUrl/object/authenticated/avatars/',
    ];
    for (final prefix in prefixes) {
      if (url.startsWith(prefix)) return url.substring(prefix.length);
    }
    return null;
  }

  Future<void> _load() async {
    final u = widget.url;
    if (u == null || u.isEmpty) {
      debugPrint('[AuthAvatar] url is null/empty');
      return;
    }

    try {
      final path = _extractPath(u);
      if (path == null) {
        debugPrint('[AuthAvatar] Unrecognized URL format, trying direct: $u');
        final http = Supabase.instance.client.storage.from('avatars');
        final bytes = await http.download(u);
        if (mounted) {
          setState(() {
            _bytes = Uint8List.fromList(bytes);
          });
        }
        return;
      }

      debugPrint('[AuthAvatar] Path=$path');
      final bytes = await Supabase.instance.client.storage
          .from('avatars')
          .download(path);
      debugPrint('[AuthAvatar] Downloaded ${bytes.length} bytes');
      if (mounted) {
        setState(() {
          _bytes = Uint8List.fromList(bytes);
        });
      }
    } catch (e) {
      debugPrint('[AuthAvatar] Error: $e');
      debugPrint('[AuthAvatar] Stack: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;

    if (_bytes != null) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.memory(_bytes!, fit: BoxFit.cover),
        ),
      );
    }

    if (_hasError || widget.url == null || widget.url!.isEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor:
            widget.backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
        child: widget.fallback,
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor:
          widget.backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

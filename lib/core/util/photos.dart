import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/kit.dart';

/// Camera or gallery (Android photo picker: no storage permission),
/// then crop, then shrink to ≤ 2048 px JPEG (QUESTIONS M17).
Future<File?> pickPhoto(BuildContext context, {ImageSource? source, CropAspectRatio? aspect}) async {
  source ??= await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(AppIcons.camera), title: Text(c.l.takePhoto), onTap: () => Navigator.pop(c, ImageSource.camera)),
          ListTile(leading: const Icon(AppIcons.images), title: Text(c.l.choosePhoto), onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final picked = await ImagePicker().pickImage(source: source, maxWidth: 4096, maxHeight: 4096, imageQuality: 95, requestFullMetadata: false);
  if (picked == null) return null;
  if (!context.mounted) return null;
  final colors = Theme.of(context).colorScheme;
  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    aspectRatio: aspect,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: context.l.cropPhoto,
        toolbarColor: colors.surface,
        toolbarWidgetColor: colors.onSurface,
        activeControlsWidgetColor: colors.primary,
        lockAspectRatio: aspect != null,
        initAspectRatio: aspect == null ? CropAspectRatioPreset.original : null,
      ),
      IOSUiSettings(title: context.l.cropPhoto, aspectRatioLockEnabled: aspect != null),
    ],
  );
  final path = cropped?.path ?? picked.path;
  final dir = await getTemporaryDirectory();
  final out = '${dir.path}/upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final result = await FlutterImageCompress.compressAndGetFile(
    path,
    out,
    minWidth: 2048,
    minHeight: 2048,
    quality: 85,
    format: CompressFormat.jpeg,
    keepExif: false,
  );
  return result == null ? File(path) : File(result.path);
}

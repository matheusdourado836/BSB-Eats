import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

Future<CroppedFile?> cropImage(BuildContext context, String? path) async {
  if(path == null) return null;
  CroppedFile? croppedFile = await ImageCropper().cropImage(
    sourcePath: path,
    aspectRatio: CropAspectRatio(ratioX: 3, ratioY: 2),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Corte sua foto',
        toolbarColor: Theme.of(context).primaryColor,
        toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
        cropStyle: CropStyle.circle,
        aspectRatioPresets: [
          CropAspectRatioPreset.ratio3x2,
        ]
      ),
      IOSUiSettings(
        title: 'Cropper',
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPresetCustom(), // IMPORTANT: iOS supports only one custom aspect ratio in preset list
        ],
        cropStyle: CropStyle.circle
      ),
    ],
  );

  return croppedFile;
}

Future<CroppedFile?> cropPostImage(BuildContext context, String? path) async {
  if(path == null) return null;
  CroppedFile? croppedFile = await ImageCropper().cropImage(
    sourcePath: path,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Corte sua foto',
        toolbarColor: Theme.of(context).primaryColor,
        toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
        aspectRatioPresets: [
          CropAspectRatioPreset.ratio3x2,
        ]
      ),
      IOSUiSettings(
        title: 'Corte sua foto',
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPresetCustom(), // IMPORTANT: iOS supports only one custom aspect ratio in preset list
        ],
      ),
    ],
  );

  return croppedFile;
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (50, 50);

  @override
  String get name => '2x3 (customized)';
}

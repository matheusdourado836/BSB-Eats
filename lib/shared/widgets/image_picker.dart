import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'image_cropper.dart';

Future<File?> _pickImage(BuildContext context, ImageSource source, {bool crop = true}) async {
  var storageStatus = await Permission.storage.status;
  var cameraStatus = await Permission.camera.status;
  if (source == ImageSource.camera && cameraStatus.isDenied) {
    Permission.camera.request();
  }
  if(source == ImageSource.gallery && storageStatus.isDenied) {
    Permission.storage.request();
  }
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
  if(pickedFile != null) {
    if(crop == false) return File(pickedFile.path);
    final croppedImage = await cropImage(context, pickedFile.path);
    if(croppedImage != null) {
      return File(croppedImage.path);
    }
  }

  return null;
}

Future<List<XFile?>> _pickMultipleImages(BuildContext context, {int limit = 10}) async {
  var storageStatus = await Permission.photos.status;
  if(storageStatus.isDenied) {
    Permission.storage.request();
  }
  final picker = ImagePicker();
  final pickedFiles = await picker.pickMultiImage(imageQuality: 80, limit: limit);

  return pickedFiles;
}

Future<dynamic> showOpcoesBottomSheet(BuildContext context) async {
  Future<void> pickFile(ImageSource source) async {
    final file = await _pickImage(context, source);
    if (file != null) {
      Navigator.pop(context, file);
      return;
    }
  }
  return await showModalBottomSheet<dynamic>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(' Adicionar foto de perfil', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(50)
                  ),
                  child: Icon(
                    Icons.image,
                    color: Theme.of(context).cardColor,
                  ),
                ),
                title: const Text('Galeria',),
                onTap: () => pickFile(ImageSource.gallery),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(50)
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Theme.of(context).cardColor,
                  ),
                ),
                title: const Text('Tirar foto',),
                onTap: () => pickFile(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(50)
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                title: const Text('Remover'),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<dynamic> showNewPostOpcoesBottomSheet(BuildContext context, {String label = 'Fazer um post', int limit = 10}) async {
  Future<void> pickFile(ImageSource source) async {
    if(source == ImageSource.gallery) {
      final files = await _pickMultipleImages(context, limit: limit);
      Navigator.pop(context, files.nonNulls.map((f) => f.path).toList());
      return;
    }
    final file = await _pickImage(context, source, crop: false);
    if (file != null) {
      Navigator.pop(context, [file.path]);
      return;
    }
  }
  return await showModalBottomSheet<dynamic>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(' $label', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(50)
                  ),
                  child: Icon(
                    Icons.image,
                    color: Theme.of(context).cardColor,
                  ),
                ),
                title: const Text('Galeria',),
                onTap: () => pickFile(ImageSource.gallery),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(50)
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Theme.of(context).cardColor,
                  ),
                ),
                title: const Text('Tirar foto',),
                onTap: () => pickFile(ImageSource.camera),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<dynamic> showPostOpcoesBottomSheet(BuildContext context) async {
  final files = await _pickMultipleImages(context);
  return files;
}

Future<dynamic> pickSingleFile(BuildContext context, {bool crop = true}) async {
  final file = await _pickImage(context, ImageSource.gallery, crop: crop);
  return file;
}
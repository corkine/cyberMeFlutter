import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../api/gallery.dart';

class GalleryManagerScreen extends ConsumerStatefulWidget {
  const GalleryManagerScreen({super.key});

  @override
  _GalleryManagerScreenState createState() => _GalleryManagerScreenState();
}

class _GalleryManagerScreenState extends ConsumerState<GalleryManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _blurOpacityController;
  late TextEditingController _borderRadiusController;
  late TextEditingController _imageRepeatController;

  @override
  void initState() {
    super.initState();
    _blurOpacityController = TextEditingController();
    _borderRadiusController = TextEditingController();
    _imageRepeatController = TextEditingController();
  }

  @override
  void dispose() {
    _blurOpacityController.dispose();
    _borderRadiusController.dispose();
    _imageRepeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galleryAsyncValue = ref.watch(gallerysProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Gallery Manager'), actions: [
          IconButton(
              onPressed: galleryAsyncValue.value == null
                  ? null
                  : () => _saveChanges(galleryAsyncValue.value!),
              icon: const Icon(Icons.save))
        ]),
        body: galleryAsyncValue.when(
            data: (galleryData) {
              _blurOpacityController.text = galleryData.blurOpacity.toString();
              _borderRadiusController.text =
                  galleryData.borderRadius.toString();
              _imageRepeatController.text =
                  galleryData.imageRepeatEachMinutes.toString();

              return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                      key: _formKey,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _blurOpacityController,
                              decoration: const InputDecoration(
                                  labelText: 'Blur Opacity'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a value';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _borderRadiusController,
                              decoration: const InputDecoration(
                                  labelText: 'Border Radius'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a value';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                                controller: _imageRepeatController,
                                decoration: const InputDecoration(
                                    labelText: 'Image Change Each',
                                    suffixText: "Minutes"),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a value';
                                  }
                                  return null;
                                }),
                            const SizedBox(height: 20),
                            Text('Images',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 10),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              ...galleryData.images.map((imageUrl) =>
                                  _buildImagePreview(imageUrl, galleryData)),
                              _buildAddImageButton(galleryData),
                            ])
                          ])));
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error'))));
  }

  Widget _buildAddImageButton(GalleryData galleryData) {
    return InkWell(
      onTap: () => _addImage(galleryData),
      child: Container(
          width: (MediaQuery.maybeSizeOf(context)!.width) / 3.5,
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.add, size: 40)),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true, // 这允许 bottom sheet 占据全屏
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
              height: MediaQuery.of(context).size.height - 0,
              decoration: const BoxDecoration(color: Colors.black),
              child: Stack(fit: StackFit.expand, children: [
                Image.network(imageUrl, fit: BoxFit.contain),
                Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 30),
                        onPressed: () => Navigator.of(context).pop()))
              ]));
        });
  }

  Widget _buildImagePreview(String imageUrl, GalleryData galleryData) {
    return Stack(children: [
      GestureDetector(
          onTap: () => _showFullScreenImage(context, imageUrl),
          child: Image.network(imageUrl,
              width: (MediaQuery.maybeSizeOf(context)!.width) / 3.5,
              height: 200,
              fit: BoxFit.cover)),
      Positioned(
          top: 0,
          right: 0,
          child: Transform.rotate(
              angle: 0.75,
              child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _removeImage(imageUrl, galleryData))))
    ]);
  }

  void _addImage(GalleryData galleryData) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      var uri = Uri.parse(
          "https://cyber.mazhangjing.com/api/files/upload?secret=i_am_cool");
      var req = http.MultipartRequest('POST', uri);
      req.fields['replace-url'] = '';
      req.fields['parent'] = '';
      req.files.add(await http.MultipartFile.fromPath('file', image.path));
      var response = await http.Response.fromStream(await req.send());
      var body = jsonDecode(response.body);
      debugPrint(body.toString());
      var newImageUrl = body["data"] as String;
      final updatedGalleryData = galleryData.copyWith(
        images: [...galleryData.images, newImageUrl],
      );
      ref.read(gallerysProvider.notifier).makeMemchange(updatedGalleryData);
    }
  }

  void _removeImage(String imageUrl, GalleryData galleryData) async {
    final updatedGalleryData = galleryData.copyWith(
      images: galleryData.images.where((url) => url != imageUrl).toList(),
    );
    ref.read(gallerysProvider.notifier).makeMemchange(updatedGalleryData);
  }

  void _saveChanges(GalleryData galleryData) async {
    if (_formKey.currentState!.validate()) {
      final updatedGalleryData = galleryData.copyWith(
        blurOpacity: double.parse(_blurOpacityController.text),
        borderRadius: double.parse(_borderRadiusController.text),
        imageRepeatEachMinutes: int.parse(_imageRepeatController.text),
      );
      await ref.read(gallerysProvider.notifier).rewrite(updatedGalleryData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
    }
  }
}

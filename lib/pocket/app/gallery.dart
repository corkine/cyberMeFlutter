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
  late TextEditingController _blurOpacityController2;
  late TextEditingController _borderRadiusController;
  late TextEditingController _imageRepeatController;

  double width = 93;
  Set<String> selectImages = {};
  List<String> allImages = [];
  GalleryData? galleryData;

  @override
  void initState() {
    super.initState();
    _blurOpacityController = TextEditingController();
    _blurOpacityController2 = TextEditingController();
    _borderRadiusController = TextEditingController();
    _imageRepeatController = TextEditingController();
    ref.read(gallerysProvider.future).then((galleryData) {
      _blurOpacityController.text = galleryData.blurOpacity.toString();
      _blurOpacityController2.text = galleryData.blurOpacityInBgMode.toString();
      _borderRadiusController.text = galleryData.borderRadius.toString();
      _imageRepeatController.text =
          galleryData.imageRepeatEachMinutes.toString();
      selectImages = {...galleryData.images.toSet()};
      allImages = [...galleryData.imagesAll];
    });
  }

  @override
  void dispose() {
    _blurOpacityController.dispose();
    _blurOpacityController2.dispose();
    _borderRadiusController.dispose();
    _imageRepeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    galleryData = ref.watch(gallerysProvider).value;
    return Scaffold(
        appBar: AppBar(
            title: const Text('Gallery Manager'),
            centerTitle: true,
            actions: [
              IconButton(
                  onPressed: galleryData == null ? null : _saveChanges,
                  icon: const Icon(Icons.save)),
              const SizedBox(width: 10)
            ]),
        body: galleryData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                              }),
                          TextFormField(
                              controller: _blurOpacityController2,
                              decoration: const InputDecoration(
                                  labelText: 'Blur Opacity (Bg Mode)'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a value';
                                }
                                return null;
                              }),
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
                              }),
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
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            ...allImages.map(
                                (imageUrl) => _buildImagePreview(imageUrl)),
                            InkWell(
                                onTap: _addImage,
                                child: Container(
                                    width: width,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.add, size: 40)))
                          ])
                        ]))));
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

  Widget _buildImagePreview(String imageUrl) {
    return Stack(children: [
      GestureDetector(
          onTap: () => _showFullScreenImage(context, imageUrl),
          child: Image.network(imageUrl,
              width: width, height: 200, fit: BoxFit.cover)),
      Positioned(
          top: 0,
          left: 0,
          child: Checkbox(
              value: selectImages.contains(imageUrl),
              onChanged: (v) {
                setState(() {
                  if (selectImages.contains(imageUrl)) {
                    selectImages.remove(imageUrl);
                  } else {
                    selectImages.add(imageUrl);
                  }
                });
              })),
      Positioned(
          bottom: -5,
          left: -5,
          child: IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: () {
                var index = allImages.indexOf(imageUrl);
                if (index > 0) {
                  allImages.removeAt(index);
                  allImages.insert(index - 1, imageUrl);
                  setState(() {});
                }
              })),
      Positioned(
          bottom: -5,
          right: -5,
          child: IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: () {
                var index = allImages.indexOf(imageUrl);
                if (index < allImages.length - 1) {
                  allImages.removeAt(index);
                  allImages.insert(index + 1, imageUrl);
                  setState(() {});
                }
              })),
      Positioned(
          top: -5,
          right: -5,
          child: Transform.rotate(
              angle: 0.75,
              child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _removeImage(imageUrl))))
    ]);
  }

  void _addImage() async {
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
      setState(() {
        selectImages.add(newImageUrl);
        allImages.add(newImageUrl);
      });
    }
  }

  void _removeImage(String imageUrl) async {
    setState(() {
      selectImages.remove(imageUrl);
      allImages.remove(imageUrl);
    });
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedGalleryData = galleryData!.copyWith(
          blurOpacity: double.parse(_blurOpacityController.text),
          blurOpacityInBgMode: double.parse(_blurOpacityController2.text),
          borderRadius: double.parse(_borderRadiusController.text),
          imageRepeatEachMinutes: int.parse(_imageRepeatController.text),
          images: allImages.where((i) => selectImages.contains(i)).toList(),
          imagesAll: allImages);
      await ref.read(gallerysProvider.notifier).rewrite(updatedGalleryData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
    }
  }
}

// lib/screens/report_incident_screen.dart
// The form a student fills in to report a problem. Laid out as three cards:
// category, details (title, description, location) and photos.
// Layout only: rules come from utils/validators.dart and saving is done by
// IncidentProvider -> IncidentService / StorageService.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/incident_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _picker = ImagePicker();

  IncidentCategory? _category;
  bool _categoryMissing = false; // shows an error under the category grid
  final List<XFile> _images = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Photos are compressed at pick time (see AppConstants.imageQuality).
  Future<void> _pickFromGallery() async {
    final remaining = AppConstants.maxImagesPerReport - _images.length;
    if (remaining <= 0) return;

    final picked = await _picker.pickMultiImage(
      imageQuality: AppConstants.imageQuality,
      maxWidth: 1280,
    );
    if (picked.isEmpty) return;
    setState(() => _images.addAll(picked.take(remaining)));
  }

  Future<void> _takePhoto() async {
    if (_images.length >= AppConstants.maxImagesPerReport) return;

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: AppConstants.imageQuality,
      maxWidth: 1280,
    );
    if (photo == null) return;
    setState(() => _images.add(photo));
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _categoryMissing = _category == null);
    if (!formValid || _category == null) return;

    final provider = context.read<IncidentProvider>();
    // Grabbed before the await, because this screen closes on success.
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.submitReport(
      title: _titleController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      category: _category!,
      images: _images,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you!')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Submit failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<IncidentProvider>().isSubmitting;
    final canAddMore = _images.length < AppConstants.maxImagesPerReport;

    return Scaffold(
      appBar: AppBar(title: const Text('Report an incident')),

      // Pinned submit button: always visible, however long the form is.
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8E2E4))),
        ),
        child: SafeArea(
          top: false,
          child: PrimaryButton(
            label: 'Submit report',
            icon: Icons.send,
            isLoading: isSubmitting,
            onPressed: _submit,
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Card 1: category ------------------------------------------------
            _SectionCard(
              title: 'What is the issue about?',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.9,
                    children: [
                      for (final category in IncidentCategory.values)
                        _CategoryTile(
                          category: category,
                          selected: _category == category,
                          onTap: () => setState(() {
                            _category = category;
                            _categoryMissing = false;
                          }),
                        ),
                    ],
                  ),
                  if (_categoryMissing)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Please choose a category',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Card 2: details -------------------------------------------------
            _SectionCard(
              title: 'Details',
              child: Column(
                children: [
                  AppTextField(
                    controller: _titleController,
                    label: 'Title',
                    icon: Icons.title,
                    maxLength: AppConstants.titleMaxLength,
                    validator: Validators.incidentTitle,
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 4,
                    maxLength: AppConstants.descriptionMaxLength,
                    validator: Validators.incidentDescription,
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _locationController,
                    label: 'Location (e.g. Block B, Room 204)',
                    icon: Icons.location_on_outlined,
                    validator: Validators.location,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Card 3: photos --------------------------------------------------
            _SectionCard(
              title: 'Photos (optional)',
              trailing:
                  '${_images.length}/${AppConstants.maxImagesPerReport}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              isSubmitting || !canAddMore ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              isSubmitting || !canAddMore ? null : _takePhoto,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final image in _images)
                          _PhotoThumbnail(
                            key: ValueKey(image.path),
                            file: image,
                            onRemove: () =>
                                setState(() => _images.remove(image)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A white rounded card with a bold title (and optional counter) on top.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (trailing != null)
                Text(trailing!, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// One selectable category: icon above its label.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : const Color(0xFFF7F3F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 26,
              color: selected ? AppColors.primary : Colors.grey.shade700,
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small preview of a picked photo with a remove button.
/// Reads the file as bytes so it works on Android, iOS and web.
class _PhotoThumbnail extends StatefulWidget {
  const _PhotoThumbnail({super.key, required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  State<_PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<_PhotoThumbnail> {
  // Stored once so the file is not re-read on every rebuild.
  late final Future<Uint8List> _bytes = widget.file.readAsBytes();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 90,
            height: 90,
            child: FutureBuilder<Uint8List>(
              future: _bytes,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: widget.onRemove,
            child: const CircleAvatar(
              radius: 11,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
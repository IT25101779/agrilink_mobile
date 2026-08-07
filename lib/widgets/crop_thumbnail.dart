import 'package:flutter/material.dart';
import '../services/crop_image_service.dart';
import '../theme/app_theme.dart';
import 'shimmer_loading.dart';

class CropThumbnail extends StatefulWidget {
  final String wikiImageTitle;
  final double size;

  const CropThumbnail({super.key, required this.wikiImageTitle, this.size = 48});

  @override
  State<CropThumbnail> createState() => _CropThumbnailState();
}

class _CropThumbnailState extends State<CropThumbnail> {
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CropThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wikiImageTitle != widget.wikiImageTitle) _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final url = await CropImageService.fetchImageUrl(widget.wikiImageTitle);
    if (mounted) {
      setState(() {
        _imageUrl = url;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.size * 0.28);

    if (_isLoading) {
      return ShimmerBox(height: widget.size, width: widget.size, borderRadius: radius);
    }

    if (_imageUrl == null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: AppColors.forestLight, borderRadius: radius),
        child: Icon(Icons.eco_rounded, color: AppColors.forest, size: widget.size * 0.5),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        _imageUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(color: AppColors.forestLight, borderRadius: radius),
          child: Icon(Icons.eco_rounded, color: AppColors.forest, size: widget.size * 0.5),
        ),
      ),
    );
  }
}

import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_search_text_field.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:unsplash_client/unsplash_client.dart';

const _accessKeyA = 'YyD-LbW5bVolHWZBq5fWRM_';
const _accessKeyB = '3ezkG2XchRFjhNTnK9TE';
const _secretKeyA = '5z4EnxaXjWjWMnuBhc0Ku0u';
const _secretKeyB = 'YW2bsYCZlO-REZaqmV6A';

enum UnsplashImageType {
  // the creator name is under the image
  halfScreen,
  // the creator name is on the image
  fullScreen,
}

typedef OnSelectUnsplashImage = void Function(String url);

class UnsplashImageWidget extends StatefulWidget {
  const UnsplashImageWidget({
    super.key,
    this.type = UnsplashImageType.halfScreen,
    required this.onSelectUnsplashImage,
  });

  final UnsplashImageType type;
  final OnSelectUnsplashImage onSelectUnsplashImage;

  @override
  State<UnsplashImageWidget> createState() => _UnsplashImageWidgetState();
}

class _UnsplashImageWidgetState extends State<UnsplashImageWidget> {
  final unsplash = UnsplashClient(
    settings: const ClientSettings(
      credentials: AppCredentials(
        accessKey: _accessKeyA + _accessKeyB,
        secretKey: _secretKeyA + _secretKeyB,
      ),
    ),
  );

  late Future<List<Photo>> randomPhotos;

  String query = '';

  @override
  void initState() {
    super.initState();
    randomPhotos = unsplash.photos
        .random(count: 18, orientation: PhotoOrientation.landscape)
        .goAndGet();
  }

  @override
  void dispose() {
    unsplash.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: FlowyMobileSearchTextField(
            onChanged: (keyword) => query = keyword,
            onSubmitted: (_) => _search(),
          ),
        ),
        const VSpace(12.0),
        Expanded(
          child: FutureBuilder(
            future: randomPhotos,
            builder: (context, value) {
              final data = value.data;
              if (!value.hasData ||
                  value.connectionState != ConnectionState.done ||
                  data == null ||
                  data.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              return _UnsplashImages(
                type: widget.type,
                photos: data,
                onSelectUnsplashImage: widget.onSelectUnsplashImage,
              );
            },
          ),
        ),
      ],
    );
  }

  void _search() {
    setState(() {
      randomPhotos = unsplash.photos
          .random(
            count: 18,
            orientation: PhotoOrientation.landscape,
            query: query,
          )
          .goAndGet();
    });
  }
}

class _UnsplashImages extends StatefulWidget {
  const _UnsplashImages({
    required this.type,
    required this.photos,
    required this.onSelectUnsplashImage,
  });

  final UnsplashImageType type;
  final List<Photo> photos;
  final OnSelectUnsplashImage onSelectUnsplashImage;

  @override
  State<_UnsplashImages> createState() => _UnsplashImagesState();
}

class _UnsplashImagesState extends State<_UnsplashImages> {
  int _selectedPhotoIndex = -1;

  @override
  Widget build(BuildContext context) {
    const mainAxisSpacing = 16.0;
    final crossAxisCount = switch (widget.type) {
      UnsplashImageType.halfScreen => 3,
      UnsplashImageType.fullScreen => 2,
    };
    final crossAxisSpacing = switch (widget.type) {
      UnsplashImageType.halfScreen => 10.0,
      UnsplashImageType.fullScreen => 16.0,
    };

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: 4 / 3,
      children: widget.photos.asMap().entries.map((entry) {
        final index = entry.key;
        final photo = entry.value;
        return _UnsplashImage(
          type: widget.type,
          photo: photo,
          isSelected: index == _selectedPhotoIndex,
          onTap: () {
            widget.onSelectUnsplashImage(photo.urls.full.toString());
            setState(() => _selectedPhotoIndex = index);
          },
        );
      }).toList(),
    );
  }
}

class _UnsplashImage extends StatelessWidget {
  const _UnsplashImage({
    required this.type,
    required this.photo,
    required this.onTap,
    required this.isSelected,
  });

  final UnsplashImageType type;
  final Photo photo;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final child = switch (type) {
      UnsplashImageType.halfScreen => _buildHalfScreenImage(context),
      UnsplashImageType.fullScreen => _buildFullScreenImage(context),
    };

    return GestureDetector(
      onTap: onTap,
      child: isSelected
          ? Container(
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1.50, color: Color(0xFF00BCF0)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              padding: const EdgeInsets.all(2.0),
              child: child,
            )
          : child,
    );
  }

  Widget _buildHalfScreenImage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Image.network(
            photo.urls.thumb.toString(),
            fit: BoxFit.cover,
          ),
        ),
        const HSpace(2.0),
        FlowyText('by ${photo.name}', fontSize: 10.0),
      ],
    );
  }

  Widget _buildFullScreenImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (_, constraints) => Image.network(
              photo.urls.thumb.toString(),
              fit: BoxFit.cover,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
          ),
          Positioned(
            bottom: 9,
            left: 10,
            child: FlowyText.medium(
              photo.name,
              fontSize: 13.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Photo {
  String get name {
    if (user.username.isNotEmpty) {
      return user.username;
    } else if (user.name.isNotEmpty) {
      return user.name;
    } else if (user.email?.isNotEmpty == true) {
      return user.email!;
    }

    return user.id;
  }
}

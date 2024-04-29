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

class _UnsplashImages extends StatelessWidget {
  const _UnsplashImages({
    required this.type,
    required this.photos,
    required this.onSelectUnsplashImage,
  });

  final UnsplashImageType type;
  final List<Photo> photos;
  final OnSelectUnsplashImage onSelectUnsplashImage;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = switch (type) {
      UnsplashImageType.halfScreen => 3,
      UnsplashImageType.fullScreen => 2,
    };
    final mainAxisSpacing = switch (type) {
      UnsplashImageType.halfScreen => 16.0,
      UnsplashImageType.fullScreen => 8.0,
    };
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: 10.0,
      childAspectRatio: 4 / 3,
      children: photos
          .map(
            (photo) => _UnsplashImage(
              type: type,
              photo: photo,
              onTap: () => onSelectUnsplashImage(
                photo.urls.regular.toString(),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _UnsplashImage extends StatelessWidget {
  const _UnsplashImage({
    required this.type,
    required this.photo,
    required this.onTap,
  });

  final UnsplashImageType type;
  final Photo photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = switch (type) {
      UnsplashImageType.halfScreen => _buildHalfScreenImage(context),
      UnsplashImageType.fullScreen => _buildFullScreenImage(context),
    };

    return GestureDetector(
      onTap: onTap,
      child: child,
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
        FlowyText(
          'by ${photo.name}',
          fontSize: 10.0,
        ),
      ],
    );
  }

  Widget _buildFullScreenImage(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Image.network(
              photo.urls.thumb.toString(),
              fit: BoxFit.cover,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );
          },
        ),
        Positioned(
          bottom: 6,
          left: 6,
          child: FlowyText.medium(
            photo.name,
            fontSize: 10.0,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

extension on Photo {
  String get name {
    if (user.username.isNotEmpty) {
      return user.username;
    }

    if (user.name.isNotEmpty) {
      return user.name;
    }

    if (user.email?.isNotEmpty == true) {
      return user.email!;
    }

    return user.id;
  }
}

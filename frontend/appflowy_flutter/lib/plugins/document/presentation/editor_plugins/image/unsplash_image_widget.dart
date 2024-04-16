import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_search_text_field.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:unsplash_client/unsplash_client.dart';

class UnsplashImageWidget extends StatefulWidget {
  const UnsplashImageWidget({
    super.key,
    required this.onSelectUnsplashImage,
  });

  final void Function(String url) onSelectUnsplashImage;

  @override
  State<UnsplashImageWidget> createState() => _UnsplashImageWidgetState();
}

class _UnsplashImageWidgetState extends State<UnsplashImageWidget> {
  final client = UnsplashClient(
    settings: const ClientSettings(
      credentials: AppCredentials(
        // TODO: there're the demo keys, we should replace them with the production keys when releasing and inject them with env file.
        accessKey: 'YyD-LbW5bVolHWZBq5fWRM_3ezkG2XchRFjhNTnK9TE',
        secretKey: '5z4EnxaXjWjWMnuBhc0Ku0uYW2bsYCZlO-REZaqmV6A',
      ),
    ),
  );

  late Future<List<Photo>> randomPhotos;

  String query = '';

  @override
  void initState() {
    super.initState();

    randomPhotos = client.photos
        .random(count: 18, orientation: PhotoOrientation.landscape)
        .goAndGet();
  }

  @override
  void dispose() {
    client.close();

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
              return GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 4 / 3,
                children: data
                    .map(
                      (photo) => _UnsplashImage(
                        photo: photo,
                        onTap: () => widget.onSelectUnsplashImage(
                          photo.urls.regular.toString(),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  void _search() {
    setState(() {
      randomPhotos = client.photos
          .random(
            count: 18,
            orientation: PhotoOrientation.landscape,
            query: query,
          )
          .goAndGet();
    });
  }
}

class _UnsplashImage extends StatelessWidget {
  const _UnsplashImage({
    required this.photo,
    required this.onTap,
  });

  final Photo photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
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

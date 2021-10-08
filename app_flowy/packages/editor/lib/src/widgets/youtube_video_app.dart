import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../flutter_quill.dart';

class YoutubeVideoApp extends StatefulWidget {
  const YoutubeVideoApp(
      {required this.videoUrl, required this.context, required this.readOnly});

  final String videoUrl;
  final BuildContext context;
  final bool readOnly;

  @override
  _YoutubeVideoAppState createState() => _YoutubeVideoAppState();
}

class _YoutubeVideoAppState extends State<YoutubeVideoApp> {
  var _youtubeController;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyles = DefaultStyles.getInstance(context);
    if (_youtubeController == null) {
      if (widget.readOnly) {
        return RichText(
          text: TextSpan(
              text: widget.videoUrl,
              style: defaultStyles.link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launch(widget.videoUrl)),
        );
      }

      return RichText(
          text: TextSpan(text: widget.videoUrl, style: defaultStyles.link));
    }

    return Container(
      height: 300,
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController,
          showVideoProgressIndicator: true,
        ),
        builder: (context, player) {
          return Column(
            children: [
              // some widgets
              player,
              //some other widgets
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _youtubeController.dispose();
  }
}

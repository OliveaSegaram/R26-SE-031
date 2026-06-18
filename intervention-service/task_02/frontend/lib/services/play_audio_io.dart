import 'package:audioplayers/audioplayers.dart';

final AudioPlayer _player = AudioPlayer();

Future<void> playAudioUrl(String url) async {
  await _player.stop();
  await _player.play(UrlSource(url));
  await _player.onPlayerComplete.first
      .timeout(const Duration(seconds: 30), onTimeout: () {});
}

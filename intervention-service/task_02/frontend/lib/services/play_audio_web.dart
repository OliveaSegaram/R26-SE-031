import 'dart:html' as html;

Future<void> playAudioUrl(String url) async {
  html.AudioElement(url)..play();
}

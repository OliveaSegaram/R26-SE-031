import 'dart:async';
import 'dart:html' as html;

Future<void> playAudioUrl(String url) async {
  final audio = html.AudioElement()
    ..src = url
    ..preload = 'auto';
  final done = Completer<void>();
  void finish() {
    if (!done.isCompleted) done.complete();
  }

  audio.onEnded.listen((_) => finish());
  audio.onError.listen((_) => finish());
  try {
    await audio.play();
  } catch (_) {
    finish();
    return;
  }
  await done.future.timeout(const Duration(seconds: 30), onTimeout: finish);
}

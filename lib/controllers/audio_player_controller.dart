import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioPlayerController extends GetxController {
  final OnAudioQuery audioQuery = OnAudioQuery();
  final AudioPlayer audioPlayer = AudioPlayer();

  RxInt playIndex = 0.obs;
  RxBool isPlaying = false.obs;

  var duration = ''.obs;
  var position = ''.obs;
  var max = 0.0.obs;
  var value = 0.0.obs;

  late final RxList<SongModel> songs = <SongModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _requestPermissions();
    _listenForSongCompletion();
  }

  updatePosition() {
    audioPlayer.durationStream.listen((d) {
      duration.value = d.toString().split(".")[0];
      max.value = d!.inSeconds.toDouble();
    });

    audioPlayer.positionStream.listen((p) {
      position.value = p.toString().split(".")[0];
      value.value = p.inSeconds.toDouble();
    });
  }

  changeDurationToseconds(seconds) {
    var duration = Duration(seconds: seconds);
    audioPlayer.seek(duration);
  }

  _requestPermissions() async {
    if (Platform.isAndroid) {
      if ((await Permission.audio.request().isGranted ||
              await Permission.storage.request().isGranted) &&
          await Permission.videos.request().isGranted) {
        Get.snackbar(
          "Permission Granted",
          "Welcome to your ad-free Media Player",
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        if (await Permission.audio.status.isDenied) {
          Get.snackbar("Permission Denied",
              "Storage permission is required to access media files.");
        }
        print(await Permission.audio.status);
      }
    }
  }

  String formatDuration(int? duration) {
    if (duration == null) return "00:00";
    Duration d = Duration(milliseconds: duration);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  playSong({String? uri, required int index}) async {
    playIndex.value = index;
    try {
      await audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri!)));
      audioPlayer.play();
      isPlaying(true);
      updatePosition();
    } on Exception catch (e) {
      if (kDebugMode) {
        print("PLAY_SONG_ERROR: ${e.toString()}");
      }
    }
  }

  _listenForSongCompletion() {
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNextSong();
      }
    });
  }

  _playNextSong() {
    if (playIndex.value < songs.length - 1) {
      // Increment the index and play the next song
      playIndex.value += 1;
      playSong(uri: songs[playIndex.value].uri, index: playIndex.value);
    } else {
      // Stop the player after the last song (5th song)
      audioPlayer.stop();
      isPlaying(false);
      Get.snackbar(
        "Playback Finished",
        "All songs in the playlist have been played.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

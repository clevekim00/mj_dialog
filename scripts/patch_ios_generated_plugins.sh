#!/bin/sh
set -eu

if [ -n "${SRCROOT:-}" ]; then
  REGISTRANT="$SRCROOT/Runner/GeneratedPluginRegistrant.m"
elif [ -f "$(pwd)/ios/Runner/GeneratedPluginRegistrant.m" ]; then
  REGISTRANT="$(pwd)/ios/Runner/GeneratedPluginRegistrant.m"
else
  REGISTRANT="$(pwd)/Runner/GeneratedPluginRegistrant.m"
fi

if [ ! -f "$REGISTRANT" ]; then
  exit 0
fi

perl -0pi -e 's/\n#if __has_include\(<flutter_gemma\/FlutterGemmaPlugin\.h>\).*?#endif\n//s' "$REGISTRANT"
perl -0pi -e 's/\n#if __has_include\(<background_downloader\/BackgroundDownloaderPlugin\.h>\).*?#endif\n//s' "$REGISTRANT"
perl -0pi -e 's/\n#if __has_include\(<flutter_tts\/FlutterTtsPlugin\.h>\).*?#endif\n//s' "$REGISTRANT"
perl -0pi -e 's/\n#if __has_include\(<large_file_handler\/LargeFileHandlerPlugin\.h>\).*?#endif\n//s' "$REGISTRANT"
perl -0pi -e 's/\n#if __has_include\(<record_ios\/RecordIosPlugin\.h>\).*?#endif\n//s' "$REGISTRANT"
perl -0pi -e 's/\n#if __has_include\(<shared_preferences_foundation\/SharedPreferencesPlugin\.h>\).*?#endif\n//s' "$REGISTRANT"
perl -0pi -e 's/\n#if __has_include\(<share_plus\/FPPSharePlusPlugin\.h>\).*?#endif\n//s' "$REGISTRANT"
perl -0pi -e 's/\n#if __has_include\(<speech_to_text\/SpeechToTextPlugin\.h>\).*?#endif\n//s' "$REGISTRANT"
perl -0pi -e 's/\n\s*\[FlutterGemmaPlugin registerWithRegistrar:\[registry registrarForPlugin:@"FlutterGemmaPlugin"\]\];//' "$REGISTRANT"
perl -0pi -e 's/\n\s*\[BackgroundDownloaderPlugin registerWithRegistrar:\[registry registrarForPlugin:@"BackgroundDownloaderPlugin"\]\];//' "$REGISTRANT"
perl -0pi -e 's/\n\s*\[FlutterTtsPlugin registerWithRegistrar:\[registry registrarForPlugin:@"FlutterTtsPlugin"\]\];//' "$REGISTRANT"
perl -0pi -e 's/\n\s*\[LargeFileHandlerPlugin registerWithRegistrar:\[registry registrarForPlugin:@"LargeFileHandlerPlugin"\]\];//' "$REGISTRANT"
perl -0pi -e 's/\n\s*\[RecordIosPlugin registerWithRegistrar:\[registry registrarForPlugin:@"RecordIosPlugin"\]\];//' "$REGISTRANT"
perl -0pi -e 's/\n\s*\[SharedPreferencesPlugin registerWithRegistrar:\[registry registrarForPlugin:@"SharedPreferencesPlugin"\]\];//' "$REGISTRANT"
perl -0pi -e 's/\n\s*\[FPPSharePlusPlugin registerWithRegistrar:\[registry registrarForPlugin:@"FPPSharePlusPlugin"\]\];//' "$REGISTRANT"
perl -0pi -e 's/\n\s*\[SpeechToTextPlugin registerWithRegistrar:\[registry registrarForPlugin:@"SpeechToTextPlugin"\]\];//' "$REGISTRANT"

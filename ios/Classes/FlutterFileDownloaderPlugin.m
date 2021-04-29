#import "FlutterFileDownloaderPlugin.h"
#if __has_include(<flutter_file_downloader/flutter_file_downloader-Swift.h>)
#import <flutter_file_downloader/flutter_file_downloader-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_file_downloader-Swift.h"
#endif

@implementation FlutterFileDownloaderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterFileDownloaderPlugin registerWithRegistrar:registrar];
}
@end

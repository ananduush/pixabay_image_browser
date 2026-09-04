import '../services/image_download_exception.dart';

/// Progress of the Details download button. One request at a time.
sealed class DownloadStatus {
  const DownloadStatus();
}

final class DownloadIdle extends DownloadStatus {
  const DownloadIdle();
}

final class DownloadSaving extends DownloadStatus {
  const DownloadSaving();
}

final class DownloadSaved extends DownloadStatus {
  const DownloadSaved();
}

final class DownloadFailed extends DownloadStatus {
  const DownloadFailed(this.error);

  final ImageDownloadException error;
}

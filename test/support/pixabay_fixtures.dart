/// Sample Pixabay payloads shaped like the documented `/api/` response.
library;

Map<String, dynamic> sampleHit({
  int id = 195893,
  String tags = 'blossom, bloom, flower',
  String user = 'Josch13',
}) {
  return <String, dynamic>{
    'id': id,
    'pageURL': 'https://pixabay.com/en/blossom-bloom-flower-$id/',
    'type': 'photo',
    'tags': tags,
    'previewURL': 'https://cdn.pixabay.com/photo/flower-${id}_150.jpg',
    'previewWidth': 150,
    'previewHeight': 84,
    'webformatURL': 'https://pixabay.com/get/35bbf209e13e39d2_640.jpg',
    'webformatWidth': 640,
    'webformatHeight': 360,
    'largeImageURL': 'https://pixabay.com/get/ed6a99fd0a76647_1280.jpg',
    'imageWidth': 4000,
    'imageHeight': 2250,
    'imageSize': 4731420,
    'views': 7671,
    'downloads': 6439,
    'likes': 5,
    'comments': 2,
    'user_id': 48777,
    'user': user,
    'userImageURL': 'https://cdn.pixabay.com/user/02-10-23-764_250x250.jpg',
  };
}

Map<String, dynamic> samplePage({int hitCount = 2}) {
  return <String, dynamic>{
    'total': 4692,
    'totalHits': 500,
    'hits': <Map<String, dynamic>>[
      for (var i = 0; i < hitCount; i++) sampleHit(id: 100 + i),
    ],
  };
}

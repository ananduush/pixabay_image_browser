import 'package:flutter_test/flutter_test.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_page.dart';

import '../../../support/pixabay_fixtures.dart';

void main() {
  group('PixabayImage.fromJson', () {
    test('parses every used field from a documented hit', () {
      final image = PixabayImage.fromJson(sampleHit());

      expect(image.id, 195893);
      expect(
        image.pageUrl,
        'https://pixabay.com/en/blossom-bloom-flower-195893/',
      );
      expect(image.tags, <String>['blossom', 'bloom', 'flower']);
      expect(image.previewUrl, endsWith('_150.jpg'));
      expect(
        image.webformatUrl,
        'https://pixabay.com/get/35bbf209e13e39d2_640.jpg',
      );
      expect(image.largeImageUrl, endsWith('_1280.jpg'));
      expect(image.imageWidth, 4000);
      expect(image.imageHeight, 2250);
      expect(image.views, 7671);
      expect(image.downloads, 6439);
      expect(image.likes, 5);
      expect(image.user, 'Josch13');
      expect(image.userImageUrl, endsWith('_250x250.jpg'));
    });

    test('trims tags and drops empty entries', () {
      final image = PixabayImage.fromJson(
        sampleHit(tags: ' fog ,, mountains ,'),
      );
      expect(image.tags, <String>['fog', 'mountains']);
    });

    test('defaults missing or oddly typed fields instead of throwing', () {
      final image = PixabayImage.fromJson(<String, dynamic>{'id': 7});

      expect(image.id, 7);
      expect(image.tags, isEmpty);
      expect(image.webformatUrl, '');
      expect(image.likes, 0);
      expect(image.user, '');
      expect(image.title, 'Untitled');
      expect(image.aspectRatio, 1);
    });
  });

  group('PixabayImage derived values', () {
    test('tileUrl swaps the _640 size suffix for _340', () {
      final image = PixabayImage.fromJson(sampleHit());
      expect(image.tileUrl, 'https://pixabay.com/get/35bbf209e13e39d2_340.jpg');
    });

    test('tileUrl leaves URLs without a _640 suffix untouched', () {
      final json = sampleHit()..['webformatURL'] = 'https://x.test/a.jpg';
      expect(PixabayImage.fromJson(json).tileUrl, 'https://x.test/a.jpg');
    });

    test('title joins up to three tags and capitalises the first letter', () {
      final image = PixabayImage.fromJson(
        sampleHit(tags: 'milky way, galaxy, space, stars'),
      );
      expect(image.title, 'Milky way · galaxy · space');
    });

    test('equality is by id', () {
      expect(
        PixabayImage.fromJson(sampleHit(user: 'a')),
        PixabayImage.fromJson(sampleHit(user: 'b')),
      );
      expect(
        PixabayImage.fromJson(sampleHit(id: 1)),
        isNot(PixabayImage.fromJson(sampleHit(id: 2))),
      );
    });
  });

  group('PixabayPage.fromJson', () {
    test('parses totals and hits', () {
      final page = PixabayPage.fromJson(samplePage(hitCount: 2));

      expect(page.total, 4692);
      expect(page.totalHits, 500);
      expect(page.hits.map((PixabayImage h) => h.id), <int>[100, 101]);
    });

    test('tolerates a missing hits list', () {
      final page = PixabayPage.fromJson(<String, dynamic>{'total': 0});
      expect(page.hits, isEmpty);
      expect(page.totalHits, 0);
    });
  });

  group('PixabayImage.toJson', () {
    test('round-trips through fromJson with Pixabay key names', () {
      final image = PixabayImage.fromJson(sampleHit());

      final json = image.toJson();
      final restored = PixabayImage.fromJson(json);

      expect(json['tags'], 'blossom, bloom, flower');
      expect(json['webformatURL'], image.webformatUrl);
      expect(json['largeImageURL'], image.largeImageUrl);
      expect(json['userImageURL'], image.userImageUrl);
      expect(restored, image);
      expect(restored.tags, image.tags);
      expect(restored.title, image.title);
      expect(restored.user, image.user);
      expect(restored.views, image.views);
      expect(restored.downloads, image.downloads);
      expect(restored.likes, image.likes);
      expect(restored.imageWidth, image.imageWidth);
      expect(restored.imageHeight, image.imageHeight);
      expect(restored.previewUrl, image.previewUrl);
      expect(restored.pageUrl, image.pageUrl);
    });

    test('persists only the fields the app reads', () {
      expect(
        PixabayImage.fromJson(sampleHit()).toJson().keys,
        unorderedEquals(<String>[
          'id',
          'pageURL',
          'tags',
          'previewURL',
          'webformatURL',
          'largeImageURL',
          'imageWidth',
          'imageHeight',
          'views',
          'downloads',
          'likes',
          'user',
          'userImageURL',
        ]),
      );
    });
  });
}

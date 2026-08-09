import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_header_value.dart';
import 'package:jmap_dart_client/jmap/mail/email/individual_header_identifier.dart';
import 'package:model/email/email_property.dart';
import 'package:model/extensions/email_extension.dart';

void main() {
  final urlsKey =
      IndividualHeaderIdentifier.asURLs(EmailProperty.headerUnsubscribeKey);

  Email makeEmail(Map<IndividualHeaderIdentifier, EmailHeaderValue> headers) =>
      Email(id: EmailId(Id('test')), individualHeaders: headers);

  group('EmailExtension::listUnsubscribeUrlsHeader', () {
    test('folds the asURLs form into an angle-bracketed, comma-joined string',
        () {
      final email = makeEmail({
        urlsKey: const URLsHeaderValue([
          'https://list.example/u?token=abc',
          'mailto:unsub@list.example',
        ]),
      });

      expect(
        email.listUnsubscribeUrlsHeader?.value,
        '<https://list.example/u?token=abc>, <mailto:unsub@list.example>',
      );
    });

    test('is null when the asURLs form is absent', () {
      expect(makeEmail({}).listUnsubscribeUrlsHeader, isNull);
    });

    test('is null when the asURLs form is present but empty', () {
      final email = makeEmail({urlsKey: const URLsHeaderValue([])});
      expect(email.listUnsubscribeUrlsHeader, isNull);
    });

    test('listUnsubscribe reads the asURLs form when no other source exists', () {
      final email = makeEmail({
        urlsKey: const URLsHeaderValue(['mailto:unsub@list.example']),
      });
      expect(email.listUnsubscribe, '<mailto:unsub@list.example>');
      expect(email.hasListUnsubscribe, isTrue);
    });

    test('the asText convenience form still wins when present', () {
      final email = makeEmail({
        IndividualHeaderIdentifier.listUnsubscribeHeader:
            const TextHeaderValue('<mailto:cached@list.example>'),
        urlsKey: const URLsHeaderValue(['mailto:fresh@list.example']),
      });
      expect(email.listUnsubscribe, '<mailto:cached@list.example>');
    });
  });
}

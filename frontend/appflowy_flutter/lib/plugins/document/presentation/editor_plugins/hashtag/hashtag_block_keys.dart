class HashtagBlockKeys {
  const HashtagBlockKeys._();

  static const hashtag = 'hashtag';
  static const name = 'name';

  // caractere interno invisível/placeholder, tal como o mention usa '$'
  static const hashtagChar = '%';

  static Map<String, dynamic> buildHashtagAttributes({
    required String name,
  }) {
    return {
      hashtag: {
        HashtagBlockKeys.name: name,
      },
    };
  }
}
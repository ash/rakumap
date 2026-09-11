unit module RakuMap::Sanitizer;

sub sanitizer-classification(%observation --> Str:D) is export {
    my $text = (%observation<compile><stderr> // '') ~ "\n"
      ~ (%observation<run><stderr> // '');
    return 'address' if $text.contains('AddressSanitizer');
    return 'undefined-behavior' if $text.contains('UndefinedBehaviorSanitizer')
        || $text.contains('runtime error:');
    return 'leak' if $text.contains('LeakSanitizer');
    return 'thread' if $text.contains('ThreadSanitizer');
    return 'memory' if $text.contains('MemorySanitizer');
    'none'
}

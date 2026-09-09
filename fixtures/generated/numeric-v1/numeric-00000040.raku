use v6.d;

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

my $source = (+(+(10 / NaN)));
my $value = $source;
say 'TYPE\t' ~ $value.^name;
say 'RAKU\t' ~ $value.raku;
say 'STR\t' ~ safe-str($value);
say 'BOOL\t' ~ $value.Bool;

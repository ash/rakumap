use v6.d;

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

my $value = (max((9223372036854775807 + "1.5"), (-NaN)) - 1+2i);
say 'TYPE\t' ~ $value.^name;
say 'RAKU\t' ~ $value.raku;
say 'STR\t' ~ safe-str($value);
say 'BOOL\t' ~ $value.Bool;

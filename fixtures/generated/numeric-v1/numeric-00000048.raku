use v6.d;

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

my @source = (((1+2i * 9223372036854775808) / max(7/3, 1+2i)),);
my $value = @source[0];
say 'TYPE\t' ~ $value.^name;
say 'RAKU\t' ~ $value.raku;
say 'STR\t' ~ safe-str($value);
say 'BOOL\t' ~ $value.Bool;

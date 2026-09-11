my $*FACTOR = 2;
sub scaled($x) { $x * $*FACTOR }
my $value = (scaled(2), { temp $*FACTOR = 3; scaled(2) }(), scaled(2));

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

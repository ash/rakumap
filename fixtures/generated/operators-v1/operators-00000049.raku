my $a = 1;
my $b = 13;
my $value = ($a == $b, $a != $b, $a < $b, $a <= $b, $a <=> $b);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

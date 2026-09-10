my $whole = "abc" ~~ / ^ a .* c $ /;
my $partial = "xabc" ~~ / ^ a .* c $ /;
my $value = (so $whole, so $partial);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

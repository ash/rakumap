my regex word { <[a..z]>+ }
my $match = "abc 42" ~~ / <word> \s+ \d+ /;
my $value = (so $match, ~$match<word>, $match.from, $match.to);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

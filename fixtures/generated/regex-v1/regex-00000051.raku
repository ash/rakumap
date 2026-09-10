my $match = "gamma" ~~ / alpha | beta | gamma | delta /;
my $value = (so $match, ~$match, $match.from, $match.to);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

sub classify(Int $x) { return "negative" if $x < 0; return "zero" if $x == 0; "positive" }
my $value = (classify(-7), classify(0), classify(7));

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

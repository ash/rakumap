role Tagged { method tag { "mixed" } }
my $source = 4 but Tagged;
my $value = ($source + 1, $source.tag, $source ~~ Tagged);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

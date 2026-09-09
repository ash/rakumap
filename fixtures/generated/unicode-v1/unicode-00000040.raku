my $source = "नमस्ते";
my $needle = $source.substr(0, 1);
my $value = ($source.index($needle), $source.starts-with($needle), $source.ends-with($needle));

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

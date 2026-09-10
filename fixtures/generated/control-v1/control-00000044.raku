my $source = 1;
my $value;
given $source { when 0 { $value = "zero" }; when 1..3 { $value = "small" }; default { $value = "large" } }

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

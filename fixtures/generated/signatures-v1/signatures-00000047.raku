multi bind(Int $x) { "Int:" ~ $x }
multi bind(Str $x) { "Str:" ~ $x }
my $value = bind("text");

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

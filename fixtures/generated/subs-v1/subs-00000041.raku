multi sub kind(Int $x) { "int:$x" }
multi sub kind(Str $x) { "str:$x" }
my $value = (kind(6), kind("6"));

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

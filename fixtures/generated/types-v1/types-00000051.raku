subset Small of Int where 0..10;
my Small $source = 4;
my $value = ($source, $source.^name, $source ~~ Small, $source ~~ Int);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

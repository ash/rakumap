sub ordered(*%items) { %items.keys.sort.map({ $_ => %items{$_} }).Array }
my $value = ordered(beta => 8, alpha => 9);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

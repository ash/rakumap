sub bind(*%x) { %x.keys.sort.map({ $_ ~ "=" ~ %x{$_}.raku }).join(";") }
my $value = bind(a => 0, b => True);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

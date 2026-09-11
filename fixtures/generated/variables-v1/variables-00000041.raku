my %source = alpha => 6, beta => 7;
%source<gamma> = 13;
my $value = %source.keys.sort.map({ $_ => %source{$_} }).Array;

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

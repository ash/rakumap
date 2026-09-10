my @matches = "one 22 three".match(/ <[a..z]>+ /, :g);
my $value = @matches.map({ ($_.Str, $_.from, $_.to) }).Array;

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

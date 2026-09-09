use v6.d;

my %source = a => -1, b => 1/2;
%source<a> = 1/2;
my $value = (%source<a>, %source<b>);
sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

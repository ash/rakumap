use v6.d;

sub replace($x is copy) { $x = -1; $x }
my $source = 0;
my $result = replace($source);
my $value = ($source, $result);
sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say 'TYPE\t' ~ $value.^name;
say 'RAKU\t' ~ $value.raku;
say 'STR\t' ~ safe-str($value);
say 'BOOL\t' ~ $value.Bool;

class Parent { method value { 2 } }
class Child is Parent { method value { callsame() + 7 } }
my $source = Child.new;
my $value = ($source.value, $source ~~ Parent, Child.^mro.map(*.^name).Array);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

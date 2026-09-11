role Named { method label { self.^name } }
class Item does Named { }
my $source = Item.new;
my $value = ($source.label, $source ~~ Named, Item.^roles.map(*.^name).Array);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

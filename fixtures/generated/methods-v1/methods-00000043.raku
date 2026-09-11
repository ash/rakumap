role Measured { method measure { self.value * 2 } }
class Item does Measured { has $.value }
my $value = Item.new(value => 4).measure;

sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

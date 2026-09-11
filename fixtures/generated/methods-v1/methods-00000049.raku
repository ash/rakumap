class Factory { method build(::?CLASS:U: $x) { ::?CLASS.new(:value($x)) }; has $.value }
my $value = Factory.build(6).value;

sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

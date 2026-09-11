class Counter { has $.base; method add($x) { self.base + $x }; method twice($x) { self.add($x) * 2 } }
my $value = Counter.new(base => 7).twice(3);

sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

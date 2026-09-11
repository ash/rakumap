class Engine { method power($x) { $x * 3 } }
class Vehicle { has Engine $.engine handles <power> }
my $value = Vehicle.new(engine => Engine.new).power(5);

sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

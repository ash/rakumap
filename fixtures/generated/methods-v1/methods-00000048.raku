class Render { multi method show(Int $x) { "int:$x" }; multi method show(Str $x) { "str:$x" } }
my $r = Render.new;
my $value = ($r.show(7), $r.show("7"));

sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

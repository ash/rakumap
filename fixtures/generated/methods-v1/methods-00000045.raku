class Math { method triple($x) { $x * 3 } }
my &operation = Math.^find_method("triple");
my $value = operation(Math.new, 2);

sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

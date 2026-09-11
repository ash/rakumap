class Secret { method !twice($x) { $x * 2 }; method reveal($x) { self!twice($x) } }
my $value = Secret.new.reveal(4);

sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

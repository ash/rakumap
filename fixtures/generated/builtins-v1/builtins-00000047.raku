my $value = sprintf("%04d:%0.2f", 8, 2.666667);

sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

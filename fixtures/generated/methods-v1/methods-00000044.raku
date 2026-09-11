class Point { has Int $.x is rw; has Int $.y }
my $point = Point.new(x => 3, y => 4);
$point.x += 3;
my $value = ($point.x, $point.y);

sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

my $lock = Lock.new;
my $counter = 0;
my @work = (1..4).map({ start { $lock.protect({ $counter++ }) } });
await @work;
my $value = $counter;

sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

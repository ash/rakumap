my @trace;
sub traced() { LEAVE { @trace.push("leave") }; @trace.push("body"); "done" }
my $result = traced();
my $value = ($result, @trace);

sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;

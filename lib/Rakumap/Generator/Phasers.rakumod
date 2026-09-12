unit module Rakumap::Generator::Phasers;

my constant @TEMPLATES =
    'begin', 'check', 'init', 'end',
    'enter', 'leave', 'keep', 'undo',
    'first', 'next', 'last', 'catch';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-phasers(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $n = 2 + choice($seed, 2, 8);
    my $body = do given $template {
        when 'begin' { "BEGIN constant COMPILED = $n * 2;\nmy \$value = COMPILED;" }
        when 'check' { "CHECK say \"PHASE\\tcheck-$n\";\nmy \$value = \"runtime\";" }
        when 'init' { "INIT say \"PHASE\\tinit-$n\";\nmy \$value = \"runtime\";" }
        when 'end' { "END say \"PHASE\\tend-$n\";\nmy \$value = \"runtime\";" }
        when 'enter' { 'my @events;' ~ "\n" ~ '{ ENTER @events.push("enter"); @events.push("body") }' ~ "\n" ~ 'my $value = @events.Array;' }
        when 'leave' { 'my @events;' ~ "\n" ~ '{ LEAVE @events.push("leave"); @events.push("body") }' ~ "\n" ~ 'my $value = @events.Array;' }
        when 'keep' { 'my @events;' ~ "\n" ~ '{ KEEP @events.push("keep"); @events.push("body") }' ~ "\n" ~ 'my $value = @events.Array;' }
        when 'undo' { 'my @events;' ~ "\n" ~ 'try { UNDO @events.push("undo"); die "stop" }' ~ "\n" ~ 'my $value = @events.Array;' }
        when 'first' { 'my @events;' ~ "\n" ~ 'for 1..3 { FIRST @events.push("first"); @events.push($_) }' ~ "\n" ~ 'my $value = @events.Array;' }
        when 'next' { 'my @events;' ~ "\n" ~ 'for 1..3 { NEXT @events.push("next"); @events.push($_) }' ~ "\n" ~ 'my $value = @events.Array;' }
        when 'last' { 'my @events;' ~ "\n" ~ 'for 1..3 { LAST @events.push("last"); @events.push($_) }' ~ "\n" ~ 'my $value = @events.Array;' }
        when 'catch' { 'my @events;' ~ "\n" ~ 'try { CATCH { default { @events.push(.^name) } }; die "stop" }' ~ "\n" ~ 'my $value = @events.Array;' }
    };
    my $source = $body ~ "\n\n" ~ q:to/OBSERVE/;
sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;
OBSERVE
    { source => $source, witness => {
        generator => 'phasers-v1', seed => $seed, template => $template,
        context => 'phaser', expression => "$n", confidence => 'C', features => [$template]
    } }
}

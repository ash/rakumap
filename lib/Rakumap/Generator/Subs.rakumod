unit module Rakumap::Generator::Subs;

my constant @TEMPLATES =
    'basic-call', 'named-argument', 'optional-argument', 'slurpy-positional',
    'slurpy-named', 'multi-dispatch', 'proto-dispatch', 'return-type',
    'closure', 'recursion', 'anonymous-sub', 'early-return';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-subs(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $n = 2 + choice($seed, 2, 7);
    my $body = do given $template {
        when 'basic-call' {
            'sub add($a, $b) { $a + $b }' ~ "\n"
              ~ "my \$value = add($n, " ~ ($n + 1) ~ ');'
        }
        when 'named-argument' {
            'sub describe(:$name!, :$count = 1) { "$name:$count" }' ~ "\n"
              ~ "my \$value = describe(name => \"raku\", count => $n);"
        }
        when 'optional-argument' {
            'sub scale($value, $factor = ' ~ $n ~ ') { $value * $factor }' ~ "\n"
              ~ 'my $value = (scale(3), scale(3, 2));'
        }
        when 'slurpy-positional' {
            'sub total(*@items) { [+] @items }' ~ "\n"
              ~ "my \$value = total(1, $n, " ~ ($n + 1) ~ ');'
        }
        when 'slurpy-named' {
            'sub ordered(*%items) { %items.keys.sort.map({ $_ => %items{$_} }).Array }' ~ "\n"
              ~ "my \$value = ordered(beta => $n, alpha => " ~ ($n + 1) ~ ');'
        }
        when 'multi-dispatch' {
            'multi sub kind(Int $x) { "int:$x" }' ~ "\n"
              ~ 'multi sub kind(Str $x) { "str:$x" }' ~ "\n"
              ~ "my \$value = (kind($n), kind(\"$n\"));"
        }
        when 'proto-dispatch' {
            'proto sub area(|) {*}' ~ "\n"
              ~ 'multi sub area(Int $side) { $side * $side }' ~ "\n"
              ~ 'multi sub area(Int $a, Int $b) { $a * $b }' ~ "\n"
              ~ "my \$value = (area($n), area($n, " ~ ($n + 1) ~ '));'
        }
        when 'return-type' {
            'sub doubled(Int $x --> Int) { $x * 2 }' ~ "\n"
              ~ "my \$value = (doubled($n), &doubled.returns.^name);"
        }
        when 'closure' {
            'sub multiplier($factor) { -> $value { $value * $factor } }' ~ "\n"
              ~ "my &times = multiplier($n);\nmy \$value = times(3);"
        }
        when 'recursion' {
            'sub factorial(Int $x) { $x <= 1 ?? 1 !! $x * factorial($x - 1) }' ~ "\n"
              ~ "my \$value = factorial($n);"
        }
        when 'anonymous-sub' {
            'my &transform = sub ($x) { $x + ' ~ $n ~ ' };' ~ "\n"
              ~ 'my $value = (transform(1), transform(4));'
        }
        when 'early-return' {
            'sub classify(Int $x) { return "negative" if $x < 0; return "zero" if $x == 0; "positive" }' ~ "\n"
              ~ "my \$value = (classify(-$n), classify(0), classify($n));"
        }
    };

    my $source = $body ~ "\n\n" ~ q:to/OBSERVE/;
sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;
OBSERVE

    { source => $source, witness => {
        generator => 'subs-v1', seed => $seed, template => $template,
        context => 'subroutine', expression => "$n",
        confidence => 'C', features => [$template]
    } }
}

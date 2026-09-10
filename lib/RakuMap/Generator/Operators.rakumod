unit module RakuMap::Generator::Operators;

my constant @NUMBERS = 1, 2, 3, 5, 8, 13;
my constant @TEMPLATES =
    'arithmetic', 'comparison', 'strings', 'logic',
    'range', 'junction', 'reduction', 'zip',
    'cross', 'assignment', 'ternary', 'smartmatch';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-operators(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $a = @NUMBERS[choice($seed, 2, @NUMBERS.elems)];
    my $b = @NUMBERS[choice($seed, 3, @NUMBERS.elems)];
    my $body = do given $template {
        when 'arithmetic' {
            "my \$a = $a;\nmy \$b = $b;\n"
              ~ 'my $value = ($a + $b, $a - $b, $a * $b, $a / $b, $a div $b, $a % $b);'
        }
        when 'comparison' {
            "my \$a = $a;\nmy \$b = $b;\n"
              ~ 'my $value = ($a == $b, $a != $b, $a < $b, $a <= $b, $a <=> $b);'
        }
        when 'strings' {
            'my $a = "ra";' ~ "\n" ~ 'my $b = "ku";' ~ "\n"
              ~ 'my $value = ($a ~ $b, $a x ' ~ (1 + $a % 4) ~ ', $a lt $b, $a cmp $b);'
        }
        when 'logic' {
            "my \$a = $a;\nmy \$zero = 0;\n"
              ~ 'my $value = ($a && "yes", $zero || "fallback", Nil // "defined");'
        }
        when 'range' {
            'my $value = (' ~ $a ~ ' .. ' ~ ($a + $b) ~ ').list;'
        }
        when 'junction' {
            "my \$needle = $a;\n"
              ~ 'my $value = ($needle == any(1, 2, 3, 5, 8, 13), $needle > all(0, -1));'
        }
        when 'reduction' {
            'my @source = (' ~ $a ~ ', ' ~ $b ~ ', 2);' ~ "\n"
              ~ 'my $value = ([+] @source, [*] @source, [min] @source, [max] @source);'
        }
        when 'zip' {
            'my $value = ((1, 2, 3) Z+ (' ~ $a ~ ', ' ~ $b ~ ', 4)).Array;'
        }
        when 'cross' {
            'my $value = (("a", "b") X (1, 2)).map({ $_.join(":") }).Array;'
        }
        when 'assignment' {
            "my \$value = $a;\n\$value += $b;\n\$value *= 2;"
        }
        when 'ternary' {
            "my \$source = $a;\n"
              ~ 'my $value = $source %% 2 ?? "even" !! "odd";'
        }
        when 'smartmatch' {
            "my \$source = $a;\n"
              ~ 'my $value = ($source ~~ Int, $source ~~ 1..10, $source ~~ (* > 0));'
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
        generator => 'operators-v1', seed => $seed, template => $template,
        context => 'operator', expression => "$a, $b",
        confidence => 'C', features => [$template]
    } }
}

unit module Rakumap::Generator::Builtins;

my constant @TEMPLATES =
    'numeric', 'rounding', 'minmax', 'string-shape',
    'split-join', 'map-grep', 'sorting', 'unique',
    'rotor', 'zip', 'conversions', 'formatting';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-builtins(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $n = 2 + choice($seed, 2, 8);
    my $body = do given $template {
        when 'numeric' { "my \$value = (abs(-$n), sign(-$n), sqrt(" ~ ($n * $n) ~ "), exp(0));" }
        when 'rounding' { 'my $source = 7.625;' ~ "\n" ~ 'my $value = ($source.floor, $source.ceiling, $source.round, $source.truncate);' }
        when 'minmax' { "my @source = ($n, 13, 2, " ~ ($n + 1) ~ ');' ~ "\n" ~ 'my $value = (@source.min, @source.max, @source.minmax.raku);' }
        when 'string-shape' { 'my $source = "Raku 🦋";' ~ "\n" ~ 'my $value = ($source.chars, $source.codes, $source.ords.Array, $source.flip);' }
        when 'split-join' { 'my $source = "alpha,beta,gamma";' ~ "\n" ~ 'my $value = $source.split(",").reverse.join("|");' }
        when 'map-grep' { "my @source = 1..$n;\n" ~ 'my $value = @source.grep(* %% 2).map(* ** 2).Array;' }
        when 'sorting' { "my @source = (13, $n, 2, " ~ ($n + 1) ~ ');' ~ "\n" ~ 'my $value = (@source.sort.Array, @source.sort(-*).Array);' }
        when 'unique' { "my @source = ($n, 2, $n, 3, 2);\n" ~ 'my $value = (@source.unique.Array, @source.repeated.Array);' }
        when 'rotor' { 'my $value = (1..8).rotor(3, :partial).map(*.Array).Array;' }
        when 'zip' { "my \$value = zip(<a b c>, ($n, " ~ ($n + 1) ~ ', 13)).map(*.Array).Array;' }
        when 'conversions' { "my \$source = \"$n\";\n" ~ 'my $value = ($source.Int, $source.Rat, $source.Num, $source.Bool);' }
        when 'formatting' { "my \$value = sprintf(\"%04d:%0.2f\", $n, " ~ ($n / 3) ~ ');' }
    };
    my $source = $body ~ "\n\n" ~ q:to/OBSERVE/;
sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;
OBSERVE
    { source => $source, witness => {
        generator => 'builtins-v1', seed => $seed, template => $template,
        context => 'builtin', expression => "$n", confidence => 'C', features => [$template]
    } }
}

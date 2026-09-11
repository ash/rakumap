unit module RakuMap::Generator::Variables;

my constant @TEMPLATES =
    'scalar-assignment', 'lexical-shadow', 'binding', 'destructure',
    'array-sigil', 'hash-sigil', 'topic', 'placeholder',
    'state-variable', 'dynamic-variable', 'package-variable', 'rw-parameter';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-variables(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $n = 2 + choice($seed, 2, 8);
    my $body = do given $template {
        when 'scalar-assignment' {
            "my \$value = $n;\n\$value += 3;\n\$value *= 2;"
        }
        when 'lexical-shadow' {
            "my \$source = $n;\n"
              ~ 'my $inner = { my $source = 20; $source + 1 }();' ~ "\n"
              ~ 'my $value = ($source, $inner);'
        }
        when 'binding' {
            "my \$source = $n;\nmy \$alias := \$source;\n"
              ~ '$source += 4;' ~ "\n" ~ 'my $value = ($source, $alias);'
        }
        when 'destructure' {
            "my (\$a, \$b, *@rest) = ($n, " ~ ($n + 1) ~ ', 8, 13);' ~ "\n"
              ~ 'my $value = ($a, $b, @rest.Array);'
        }
        when 'array-sigil' {
            "my @source = ($n, " ~ ($n + 1) ~ ');' ~ "\n"
              ~ '@source.push(13);' ~ "\n" ~ 'my $value = (@source.elems, @source[0], @source[*-1]);'
        }
        when 'hash-sigil' {
            "my %source = alpha => $n, beta => " ~ ($n + 1) ~ ';' ~ "\n"
              ~ '%source<gamma> = 13;' ~ "\n" ~ 'my $value = %source.keys.sort.map({ $_ => %source{$_} }).Array;'
        }
        when 'topic' {
            "my @source = ($n, " ~ ($n + 1) ~ ', 8);' ~ "\n"
              ~ 'my $value = @source.grep(* %% 2).map({ $_ * 2 }).Array;'
        }
        when 'placeholder' {
            'my &combine = { $^a * 10 + $^b };' ~ "\n"
              ~ "my \$value = combine($n, " ~ ($n + 1) ~ ');'
        }
        when 'state-variable' {
            'sub counter { state $seen = 0; ++$seen }' ~ "\n"
              ~ 'my $value = (counter(), counter(), counter());'
        }
        when 'dynamic-variable' {
            "my \$*FACTOR = $n;\n"
              ~ 'sub scaled($x) { $x * $*FACTOR }' ~ "\n"
              ~ 'my $value = (scaled(2), { temp $*FACTOR = 3; scaled(2) }(), scaled(2));'
        }
        when 'package-variable' {
            "our \$Counter = $n;\n"
              ~ 'sub bump { ++$Counter }' ~ "\n" ~ 'my $value = (bump(), bump(), $Counter);'
        }
        when 'rw-parameter' {
            'sub bump($target is rw) { $target += 2 }' ~ "\n"
              ~ "my \$source = $n;\nbump(\$source);\nmy \$value = \$source;"
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
        generator => 'variables-v1', seed => $seed, template => $template,
        context => 'variable', expression => "$n",
        confidence => 'C', features => [$template]
    } }
}

unit module RakuMap::Generator::Containers;

my constant @VALUES = '0', '1', '-1', '42', '1/2', '"text"', 'True';
my constant @TEMPLATES =
    'scalar-write', 'binding-alias', 'array-element', 'hash-element',
    'rw-parameter', 'copy-parameter', 'typed-scalar', 'list-item',
    'array-flatten', 'slip-flatten';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-containers(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $first = @VALUES[choice($seed, 2, @VALUES.elems)];
    my $second = @VALUES[choice($seed, 3, @VALUES.elems)];
    my $body = do given $template {
        when 'scalar-write' {
            "my \$source = $first;\n\$source = $second;\nmy \$value = \$source;"
        }
        when 'binding-alias' {
            "my \$source = $first;\nmy \$alias := \$source;\n\$alias = $second;\n"
              ~ 'my $value = ($source, $alias);'
        }
        when 'array-element' {
            "my \@source = ($first, $second);\n\@source[0] = $second;\n"
              ~ 'my $value = @source;'
        }
        when 'hash-element' {
            "my \%source = a => $first, b => $second;\n\%source<a> = $second;\n"
              ~ 'my $value = (%source<a>, %source<b>);'
        }
        when 'rw-parameter' {
            'sub replace($x is rw) { $x = ' ~ $second ~ " }\n"
              ~ 'my $source = ' ~ $first ~ ";\n"
              ~ 'replace($source);' ~ "\n" ~ 'my $value = $source;'
        }
        when 'copy-parameter' {
            'sub replace($x is copy) { $x = ' ~ $second ~ '; $x }' ~ "\n"
              ~ 'my $source = ' ~ $first ~ ";\n"
              ~ 'my $result = replace($source);' ~ "\n" ~ 'my $value = ($source, $result);'
        }
        when 'typed-scalar' {
            "my Numeric \$source = $first;\nmy \$value = \$source;"
        }
        when 'list-item' {
            "my \@inner = ($first, $second);\nmy \@source = item(\@inner);\n"
              ~ 'my $value = (@source.elems, @source[0].^name, @source[0]);'
        }
        when 'array-flatten' {
            "my \@inner = ($first, $second);\nmy \@source = (\@inner, $first);\n"
              ~ 'my $value = (@source.elems, @source);'
        }
        when 'slip-flatten' {
            "my \@source = (slip($first, $second), $first);\n"
              ~ 'my $value = (@source.elems, @source);'
        }
    };

    my $source = "use v6.d;\n\n" ~ $body ~ q:to/OBSERVE/;

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
        generator => 'containers-v1', seed => $seed, template => $template,
        context => 'container', expression => "$first -> $second",
        confidence => 'C', features => [$template]
    } }
}

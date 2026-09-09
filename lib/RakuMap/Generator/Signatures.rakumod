unit module RakuMap::Generator::Signatures;

my constant @VALUES = '0', '1', '-1', '42', '"text"', 'True';
my constant @INTS = '1', '2', '42', '9223372036854775808';
my constant @TEMPLATES =
    'positional', 'two-positional', 'optional-omitted', 'optional-provided',
    'named', 'named-alias', 'slurpy-positional', 'slurpy-named',
    'typed', 'where-constraint', 'capture', 'multi-dispatch';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-signatures(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $first = @VALUES[choice($seed, 2, @VALUES.elems)];
    my $second = @VALUES[choice($seed, 3, @VALUES.elems)];
    my $integer = @INTS[choice($seed, 4, @INTS.elems)];
    my $body = do given $template {
        when 'positional' {
            'sub bind($x) { ($x.^name, $x) }' ~ "\n"
              ~ 'my $value = bind(' ~ $first ~ ');'
        }
        when 'two-positional' {
            'sub bind($x, $y) { ($x, $y) }' ~ "\n"
              ~ 'my $value = bind(' ~ $first ~ ', ' ~ $second ~ ');'
        }
        when 'optional-omitted' {
            'sub bind($x = ' ~ $first ~ ') { $x }' ~ "\n"
              ~ 'my $value = bind();'
        }
        when 'optional-provided' {
            'sub bind($x = ' ~ $first ~ ') { $x }' ~ "\n"
              ~ 'my $value = bind(' ~ $second ~ ');'
        }
        when 'named' {
            'sub bind(:$x!) { $x }' ~ "\n"
              ~ 'my $value = bind(x => ' ~ $first ~ ');'
        }
        when 'named-alias' {
            'sub bind(:short(:$long)!) { $long }' ~ "\n"
              ~ 'my $value = bind(short => ' ~ $second ~ ');'
        }
        when 'slurpy-positional' {
            'sub bind(*@x) { (@x.elems, @x) }' ~ "\n"
              ~ 'my $value = bind(' ~ $first ~ ', ' ~ $second ~ ', ' ~ $first ~ ');'
        }
        when 'slurpy-named' {
            'sub bind(*%x) { %x.keys.sort.map({ $_ ~ "=" ~ %x{$_}.raku }).join(";") }' ~ "\n"
              ~ 'my $value = bind(a => ' ~ $first ~ ', b => ' ~ $second ~ ');'
        }
        when 'typed' {
            'sub bind(Int $x) { ($x.^name, $x) }' ~ "\n"
              ~ 'my $value = bind(' ~ $integer ~ ');'
        }
        when 'where-constraint' {
            'sub bind(Int $x where * > 0) { $x * 2 }' ~ "\n"
              ~ 'my $value = bind(' ~ $integer ~ ');'
        }
        when 'capture' {
            'sub bind(|c) { (c.elems, c.list) }' ~ "\n"
              ~ 'my $value = bind(' ~ $first ~ ', ' ~ $second ~ ');'
        }
        when 'multi-dispatch' {
            'multi bind(Int $x) { "Int:" ~ $x }' ~ "\n"
              ~ 'multi bind(Str $x) { "Str:" ~ $x }' ~ "\n"
              ~ 'my $value = bind(' ~ ($seed %% 2 ?? $integer !! '"text"') ~ ');'
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
        generator => 'signatures-v1', seed => $seed, template => $template,
        context => 'signature', expression => "$first, $second",
        confidence => 'C', features => [$template]
    } }
}

unit module Rakumap::Generator::Types;

my constant @TEMPLATES =
    'introspection', 'definedness', 'coercion', 'subset',
    'enum', 'role', 'inheritance', 'mixin',
    'type-object', 'pair', 'parameterized', 'where-constraint';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-types(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $n = 2 + choice($seed, 2, 8);
    my $body = do given $template {
        when 'introspection' {
            "my \$source = $n;\n"
              ~ 'my $value = ($source.^name, $source.WHAT.^name, $source ~~ Int);'
        }
        when 'definedness' {
            'my $value = (Int.defined, Nil.defined, 0.defined, "".defined);'
        }
        when 'coercion' {
            "my \$source = \"$n\";\n"
              ~ 'my $value = ($source.Int, $source.Numeric, $source.Bool, $source.Str);'
        }
        when 'subset' {
            "subset Small of Int where 0..10;\nmy Small \$source = $n;\n"
              ~ 'my $value = ($source, $source.^name, $source ~~ Small, $source ~~ Int);'
        }
        when 'enum' {
            'enum Direction <North East South West>;' ~ "\n"
              ~ 'my $source = Direction.enums<North>;' ~ "\n"
              ~ 'my $value = ($source, Direction::East.value, Direction.enums.keys.sort.Array);'
        }
        when 'role' {
            'role Named { method label { self.^name } }' ~ "\n"
              ~ 'class Item does Named { }' ~ "\n"
              ~ 'my $source = Item.new;' ~ "\n"
              ~ 'my $value = ($source.label, $source ~~ Named, Item.^roles.map(*.^name).Array);'
        }
        when 'inheritance' {
            'class Parent { method value { 2 } }' ~ "\n"
              ~ 'class Child is Parent { method value { callsame() + ' ~ $n ~ ' } }' ~ "\n"
              ~ 'my $source = Child.new;' ~ "\n"
              ~ 'my $value = ($source.value, $source ~~ Parent, Child.^mro.map(*.^name).Array);'
        }
        when 'mixin' {
            'role Tagged { method tag { "mixed" } }' ~ "\n"
              ~ 'my $source = ' ~ $n ~ ' but Tagged;' ~ "\n"
              ~ 'my $value = ($source + 1, $source.tag, $source ~~ Tagged);'
        }
        when 'type-object' {
            'my $source = Int;' ~ "\n"
              ~ 'my $value = ($source.^name, $source.defined, $source ~~ Int, $source.HOW.^name);'
        }
        when 'pair' {
            "my \$source = answer => $n;\n"
              ~ 'my $value = ($source.^name, $source.key, $source.value, $source ~~ Pair);'
        }
        when 'parameterized' {
            "my Int @source = ($n, " ~ ($n + 1) ~ ');' ~ "\n"
              ~ 'my $value = (@source.^name, @source.of.^name, @source.Array, @source ~~ Positional);'
        }
        when 'where-constraint' {
            'sub classify(Int $x where * > 0) { ($x.^name, $x * 2) }' ~ "\n"
              ~ "my \$value = classify($n);"
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
        generator => 'types-v1', seed => $seed, template => $template,
        context => 'type-system', expression => "$n",
        confidence => 'C', features => [$template]
    } }
}

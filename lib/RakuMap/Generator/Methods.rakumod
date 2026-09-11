unit module RakuMap::Generator::Methods;

my constant @TEMPLATES =
    'instance-method', 'class-method', 'attribute-accessor', 'private-method',
    'inheritance', 'override-callsame', 'multi-method', 'role-method',
    'delegation', 'method-reference', 'self-call', 'fallback';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-methods(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $n = 2 + choice($seed, 2, 8);
    my $body = do given $template {
        when 'instance-method' {
            'class Box { has $.value; method doubled { $.value * 2 } }' ~ "\n"
              ~ "my \$value = Box.new(value => $n).doubled;"
        }
        when 'class-method' {
            'class Factory { method build(::?CLASS:U: $x) { ::?CLASS.new(:value($x)) }; has $.value }' ~ "\n"
              ~ "my \$value = Factory.build($n).value;"
        }
        when 'attribute-accessor' {
            'class Point { has Int $.x is rw; has Int $.y }' ~ "\n"
              ~ "my \$point = Point.new(x => $n, y => " ~ ($n + 1) ~ ');' ~ "\n"
              ~ '$point.x += 3;' ~ "\n" ~ 'my $value = ($point.x, $point.y);'
        }
        when 'private-method' {
            'class Secret { method !twice($x) { $x * 2 }; method reveal($x) { self!twice($x) } }' ~ "\n"
              ~ "my \$value = Secret.new.reveal($n);"
        }
        when 'inheritance' {
            'class Parent { method label { "parent" } }' ~ "\n"
              ~ 'class Child is Parent { }' ~ "\n"
              ~ 'my $value = (Child.new.label, Child.^mro.map(*.^name).Array);'
        }
        when 'override-callsame' {
            'class Base { method score { 2 } }' ~ "\n"
              ~ 'class Derived is Base { method score { callsame() + ' ~ $n ~ ' } }' ~ "\n"
              ~ 'my $value = Derived.new.score;'
        }
        when 'multi-method' {
            'class Render { multi method show(Int $x) { "int:$x" }; multi method show(Str $x) { "str:$x" } }' ~ "\n"
              ~ "my \$r = Render.new;\nmy \$value = (\$r.show($n), \$r.show(\"$n\"));"
        }
        when 'role-method' {
            'role Measured { method measure { self.value * 2 } }' ~ "\n"
              ~ 'class Item does Measured { has $.value }' ~ "\n"
              ~ "my \$value = Item.new(value => $n).measure;"
        }
        when 'delegation' {
            'class Engine { method power($x) { $x * 3 } }' ~ "\n"
              ~ 'class Vehicle { has Engine $.engine handles <power> }' ~ "\n"
              ~ "my \$value = Vehicle.new(engine => Engine.new).power($n);"
        }
        when 'method-reference' {
            'class Math { method triple($x) { $x * 3 } }' ~ "\n"
              ~ 'my &operation = Math.^find_method("triple");' ~ "\n"
              ~ "my \$value = operation(Math.new, $n);"
        }
        when 'self-call' {
            'class Counter { has $.base; method add($x) { self.base + $x }; method twice($x) { self.add($x) * 2 } }' ~ "\n"
              ~ "my \$value = Counter.new(base => $n).twice(3);"
        }
        when 'fallback' {
            'class Dynamic { method FALLBACK($name, |c) { "$name:" ~ c.elems } }' ~ "\n"
              ~ "my \$value = Dynamic.new.unknown($n, " ~ ($n + 1) ~ ');'
        }
    };

    my $source = $body ~ "\n\n" ~ q:to/OBSERVE/;
sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;
OBSERVE

    { source => $source, witness => {
        generator => 'methods-v1', seed => $seed, template => $template,
        context => 'method', expression => "$n", confidence => 'C', features => [$template]
    } }
}

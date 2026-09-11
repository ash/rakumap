unit module RakuMap::Generator::Invalid;

my constant @TEMPLATES =
    'unclosed-paren', 'unterminated-string', 'unclosed-block', 'duplicate-parameter',
    'bad-sigil', 'bad-radix', 'malformed-pair', 'unknown-trait',
    'bad-regex', 'malformed-method', 'adjacent-terms', 'orphan-else';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-invalid(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $source = do given $template {
        when 'unclosed-paren' { 'my $value = (1 + 2;' ~ "\n" }
        when 'unterminated-string' { 'my $value = "unfinished;' ~ "\n" }
        when 'unclosed-block' { 'if True { say 1;' ~ "\n" }
        when 'duplicate-parameter' { 'sub f($x, $x) { };' ~ "\n" }
        when 'bad-sigil' { 'my ?value = 1;' ~ "\n" }
        when 'bad-radix' { 'my $value = :1<2>;' ~ "\n" }
        when 'malformed-pair' { 'my $value = :;' ~ "\n" }
        when 'unknown-trait' { 'sub f() is definitely-not-a-trait { };' ~ "\n" }
        when 'bad-regex' { 'my $value = rx/ [ /;' ~ "\n" }
        when 'malformed-method' { 'class C { method 42() { } }' ~ "\n" }
        when 'adjacent-terms' { 'my $value = 1 2;' ~ "\n" }
        when 'orphan-else' { 'else { say 1 }' ~ "\n" }
    };
    { source => $source, witness => {
        generator => 'invalid-v1', seed => $seed, template => $template,
        context => 'diagnostic', expression => $template,
        confidence => 'I', expected => 'reject', features => [$template]
    } }
}

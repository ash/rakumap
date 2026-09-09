unit module RakuMap::Generator::Numeric;

my constant @LEAVES =
    '0', '1', '-1', '2', '10',
    '9223372036854775807', '9223372036854775808',
    '1/2', '-3/4', '7/3',
    '0e0', '-0e0', '1.5e0', 'Inf', '-Inf', 'NaN',
    '1+2i', '0+1i',
    'True', 'False', '"0"', '"12"', '"1.5"';

my constant @BINARY = '+', '-', '*', '/', 'min', 'max';
my constant @CONTEXT = <direct scalar parameter return array>;

sub rng(Int:D $seed --> Hash:D) {
    my $state = ($seed.abs % 2147483646) + 1;
    { next => sub (Int:D $limit --> Int:D) {
        $state = ($state * 48271) % 2147483647;
        $state % $limit
    } }
}

sub expression(%r, Int:D $depth --> Str:D) {
    return @LEAVES[%r<next>(@LEAVES.elems)] if $depth <= 0;
    given %r<next>(4) {
        when 0 { @LEAVES[%r<next>(@LEAVES.elems)] }
        when 1 {
            my $op = %r<next>(2) ?? '-' !! '+';
            "($op" ~ expression(%r, $depth - 1) ~ ')'
        }
        default {
            my $left = expression(%r, $depth - 1);
            my $right = expression(%r, $depth - 1);
            my $op = @BINARY[%r<next>(@BINARY.elems)];
            if $op eq 'min' || $op eq 'max' {
                $op ~ '(' ~ $left ~ ', ' ~ $right ~ ')'
            }
            else {
                "($left $op $right)"
            }
        }
    }
}

sub generate-numeric(Int:D $seed --> Hash:D) is export {
    my %r = rng($seed);
    my $depth = 1 + %r<next>(3);
    my $expr = expression(%r, $depth);
    my $context = @CONTEXT[%r<next>(@CONTEXT.elems)];
    my $setup = do given $context {
        when 'direct'    { 'my $value = ' ~ $expr ~ ';' }
        when 'scalar'    { 'my $source = ' ~ $expr ~ ";\n" ~ 'my $value = $source;' }
        when 'parameter' { 'sub carry($x) { $x }' ~ "\n" ~ 'my $value = carry(' ~ $expr ~ ');' }
        when 'return'    { 'sub carry() { ' ~ $expr ~ " }\n" ~ 'my $value = carry();' }
        when 'array'     { 'my @source = (' ~ $expr ~ ",);\n" ~ 'my $value = @source[0];' }
    };

    my $source = q:to/HEADER/;
sub safe-str($v) {
    my $s = try $v.Str;
    $s.defined ?? $s !! '<undefined>'
}

HEADER
    $source ~= $setup ~ q:to/OBSERVE/;

say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;
OBSERVE

    { source => $source, witness => {
        generator => 'numeric-v1', seed => $seed, depth => $depth,
        context => $context, expression => $expr, confidence => 'C'
    } }
}

unit module RakuMap::Generator::Literals;

my constant @TEMPLATES =
    'integer-bases', 'digit-separators', 'rationals', 'scientific-num',
    'complex', 'boolean-nil', 'quoting', 'interpolation',
    'array', 'hash', 'pair', 'version';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-literals(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $n = 2 + choice($seed, 2, 8);
    my $body = do given $template {
        when 'integer-bases' { 'my $value = (0b101101, 0o755, 0xCAFE, :16<ff>);' }
        when 'digit-separators' { 'my $value = (1_000_000, 0b1010_0101, 12_345.67_89);' }
        when 'rationals' { 'my $value = (1/3, 2/6, 7/2, (1/3 + 2/3));' }
        when 'scientific-num' { 'my $value = (1e3, 2.5e-2, 6.022e23, -0e0);' }
        when 'complex' { 'my $value = (2+3i, (2+3i).conj, (3+4i).abs);' }
        when 'boolean-nil' { 'my $value = (True, False, Nil, Any, Failure.new("x").defined);' }
        when 'quoting' { 'my $value = (q[raw $text], qq[double\nline], Q:c[\x52aku], ｢corner quotes｣);' }
        when 'interpolation' { "my \$n = $n;\n" ~ 'my $value = ("value=$n", "next={ $n + 1 }", "array={($n, $n + 1).join(q[,])}");' }
        when 'array' { "my \$value = [$n, " ~ ($n + 1) ~ ', [8, 13], "raku"];' }
        when 'hash' { 'my $value = { alpha => ' ~ $n ~ ', beta => ' ~ ($n + 1) ~ ', nested => { ok => True } };' }
        when 'pair' { "my \$value = (answer => $n, :enabled, :!hidden, :count(" ~ ($n + 1) ~ '));' }
        when 'version' { 'my $value = (v1.2.3, v1.2.4, v2.0.0, v1.2.3 ~~ Version);' }
    };
    my $source = $body ~ "\n\n" ~ q:to/OBSERVE/;
sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;
OBSERVE
    { source => $source, witness => {
        generator => 'literals-v1', seed => $seed, template => $template,
        context => 'literal', expression => "$n", confidence => 'C', features => [$template]
    } }
}

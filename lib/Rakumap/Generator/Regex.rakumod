unit module Rakumap::Generator::Regex;

my constant @WORDS = <alpha beta gamma delta>;
my constant @TEMPLATES =
    'literal-match', 'positional-capture', 'named-capture', 'alternation',
    'quantifier', 'anchors', 'ignorecase', 'global-match',
    'substitution', 'comb', 'split', 'named-subrule';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-regex(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $word = @WORDS[choice($seed, 2, @WORDS.elems)];
    my $body = do given $template {
        when 'literal-match' {
            'my $match = "xxabcxx" ~~ / abc /;' ~ "\n"
              ~ 'my $value = (so $match, $match.from, $match.to, ~$match);'
        }
        when 'positional-capture' {
            'my $match = "aaab" ~~ / (a+) b /;' ~ "\n"
              ~ 'my $value = (so $match, ~$match[0], $match[0].from, $match[0].to);'
        }
        when 'named-capture' {
            'my $match = "abc-42" ~~ / $<word>=[<[a..z]>+] \- $<number>=[\d+] /;' ~ "\n"
              ~ 'my $value = (so $match, ~$match<word>, ~$match<number>);'
        }
        when 'alternation' {
            'my $match = "' ~ $word ~ '" ~~ / alpha | beta | gamma | delta /;' ~ "\n"
              ~ 'my $value = (so $match, ~$match, $match.from, $match.to);'
        }
        when 'quantifier' {
            'my $match = "baaac" ~~ / a ** 2..4 /;' ~ "\n"
              ~ 'my $value = (so $match, ~$match, $match.chars);'
        }
        when 'anchors' {
            'my $whole = "abc" ~~ / ^ a .* c $ /;' ~ "\n"
              ~ 'my $partial = "xabc" ~~ / ^ a .* c $ /;' ~ "\n"
              ~ 'my $value = (so $whole, so $partial);'
        }
        when 'ignorecase' {
            'my $match = "AbC" ~~ m:i/ abc /;' ~ "\n"
              ~ 'my $value = (so $match, ~$match, $match.from, $match.to);'
        }
        when 'global-match' {
            'my @matches = "one 22 three".match(/ <[a..z]>+ /, :g);' ~ "\n"
              ~ 'my $value = @matches.map({ ($_.Str, $_.from, $_.to) }).Array;'
        }
        when 'substitution' {
            'my $value = "a1b22c333".subst(/ \d+ /, "#", :g);'
        }
        when 'comb' {
            'my $value = "a1 bb22 ccc333".comb(/ <[a..z]>+ /).Array;'
        }
        when 'split' {
            'my $value = "alpha  beta\tgamma".split(/ \s+ /).Array;'
        }
        when 'named-subrule' {
            'my regex word { <[a..z]>+ }' ~ "\n"
              ~ 'my $match = "abc 42" ~~ / <word> \s+ \d+ /;' ~ "\n"
              ~ 'my $value = (so $match, ~$match<word>, $match.from, $match.to);'
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
        generator => 'regex-v1', seed => $seed, template => $template,
        context => 'regex', expression => $word,
        confidence => 'C', features => [$template]
    } }
}

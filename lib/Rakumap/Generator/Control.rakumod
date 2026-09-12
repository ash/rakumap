unit module Rakumap::Generator::Control;

my constant @VALUES = 0, 1, 2, 3, 5, 8;
my constant @TEMPLATES =
    'if-else', 'unless', 'given-when', 'for-loop',
    'while-loop', 'repeat-loop', 'loop-form', 'gather-take',
    'try-exception', 'return-nested', 'next-loop', 'leave-phaser';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-control(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $n = @VALUES[choice($seed, 2, @VALUES.elems)];
    my $limit = 2 + $n;
    my $body = do given $template {
        when 'if-else' {
            "my \$source = $n;\n"
              ~ 'my $value; if $source %% 2 { $value = "even" } else { $value = "odd" }'
        }
        when 'unless' {
            "my \$source = $n;\nmy \@trace;\n"
              ~ '@trace.push("zero") unless $source;' ~ "\n"
              ~ '@trace.push("nonzero") if $source;' ~ "\n"
              ~ 'my $value = @trace;'
        }
        when 'given-when' {
            "my \$source = $n;\nmy \$value;\n"
              ~ 'given $source { when 0 { $value = "zero" }; when 1..3 { $value = "small" }; default { $value = "large" } }'
        }
        when 'for-loop' {
            'my @result;' ~ "\nfor 0 .. $limit" ~ ' -> $i { @result.push($i * $i) }'
              ~ "\n" ~ 'my $value = @result;'
        }
        when 'while-loop' {
            'my $i = 0;' ~ "\n" ~ 'my @result;' ~ "\n"
              ~ 'while $i < ' ~ $limit ~ ' { @result.push($i); $i++ }'
              ~ "\n" ~ 'my $value = @result;'
        }
        when 'repeat-loop' {
            'my $i = 0;' ~ "\n" ~ 'my @result;' ~ "\n"
              ~ 'repeat { @result.push($i); $i++ } while $i < ' ~ $limit ~ ';'
              ~ "\n" ~ 'my $value = @result;'
        }
        when 'loop-form' {
            'my @result;' ~ "\n" ~ 'loop (my $i = 0; $i < ' ~ $limit
              ~ '; $i++) { @result.push($i + 1) }'
              ~ "\n" ~ 'my $value = @result;'
        }
        when 'gather-take' {
            'my $value = gather for 0 .. ' ~ $limit ~ ' -> $i { take $i if $i %% 2 };'
        }
        when 'try-exception' {
            'my $result = try { die "planted" };' ~ "\n"
              ~ 'my $value = ($result.defined, $!.^name);'
        }
        when 'return-nested' {
            'sub choose($x) { for 1..3 -> $i { return $i * 10 if $i == $x }; -1 }'
              ~ "\n" ~ 'my $value = choose(' ~ (1 + $n % 4) ~ ');'
        }
        when 'next-loop' {
            'my @result;' ~ "\nfor 0 .. $limit" ~ ' -> $i { next if $i %% 2; @result.push($i) }'
              ~ "\n" ~ 'my $value = @result;'
        }
        when 'leave-phaser' {
            'my @trace;' ~ "\n"
              ~ 'sub traced() { LEAVE { @trace.push("leave") }; @trace.push("body"); "done" }' ~ "\n"
              ~ 'my $result = traced();' ~ "\n"
              ~ 'my $value = ($result, @trace);'
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
        generator => 'control-v1', seed => $seed, template => $template,
        context => 'control', expression => $n.Str,
        confidence => 'C', features => [$template]
    } }
}

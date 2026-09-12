unit module Rakumap::Generator::Concurrency;

my constant @TEMPLATES =
    'start-await', 'await-list', 'kept-promise', 'broken-promise',
    'then-chain', 'channel-roundtrip', 'channel-close', 'lock-protect',
    'locked-counter', 'thread-join', 'supply-list', 'react-whenever';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-concurrency(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $n = 2 + choice($seed, 2, 8);
    my $body = do given $template {
        when 'start-await' { 'my $work = start { ' ~ $n ~ ' * 2 };' ~ "\n" ~ 'my $value = await $work;' }
        when 'await-list' { 'my @work = (start { ' ~ $n ~ ' + 1 }, start { ' ~ $n ~ ' + 2 });' ~ "\n" ~ 'my $value = await(@work);' }
        when 'kept-promise' { "my \$promise = Promise.kept($n);\nmy \$value = (\$promise.status.Str, await \$promise);" }
        when 'broken-promise' { 'my $promise = Promise.broken("failure");' ~ "\n" ~ 'my $error = try await $promise;' ~ "\n" ~ 'my $value = ($promise.status.Str, $error.defined);' }
        when 'then-chain' { 'my $promise = Promise.kept(' ~ $n ~ ').then({ .result * 3 });' ~ "\n" ~ 'my $value = await $promise;' }
        when 'channel-roundtrip' { "my \$channel = Channel.new;\n\$channel.send($n);\nmy \$value = \$channel.receive;\n\$channel.close;" }
        when 'channel-close' { "my \$channel = Channel.new;\n\$channel.send($n);\n\$channel.close;\nmy \$value = \$channel.list.Array;" }
        when 'lock-protect' { 'my $lock = Lock.new;' ~ "\n" ~ 'my $source = ' ~ $n ~ ';' ~ "\n" ~ 'my $value = $lock.protect({ $source += 2; $source });' }
        when 'locked-counter' { 'my $lock = Lock.new;' ~ "\n" ~ 'my $counter = 0;' ~ "\n" ~ 'my @work = (1..4).map({ start { $lock.protect({ $counter++ }) } });' ~ "\n" ~ 'await @work;' ~ "\n" ~ 'my $value = $counter;' }
        when 'thread-join' { 'my $result;' ~ "\n" ~ 'my $thread = Thread.start({ $result = ' ~ $n ~ ' * 4 });' ~ "\n" ~ '$thread.join;' ~ "\n" ~ 'my $value = $result;' }
        when 'supply-list' { "my \$value = Supply.from-list(($n, " ~ ($n + 1) ~ ', 13)).list;' }
        when 'react-whenever' { 'my @seen;' ~ "\n" ~ 'react whenever Supply.from-list((' ~ $n ~ ', ' ~ ($n + 1) ~ ')) { @seen.push($_) }' ~ "\n" ~ 'my $value = @seen.Array;' }
    };
    my $source = $body ~ "\n\n" ~ q:to/OBSERVE/;
sub safe-str($v) { my $s = try $v.Str; $s.defined ?? $s !! '<undefined>' }
say "TYPE\t" ~ $value.^name;
say "RAKU\t" ~ $value.raku;
say "STR\t" ~ safe-str($value);
say "BOOL\t" ~ $value.Bool;
OBSERVE
    { source => $source, witness => {
        generator => 'concurrency-v1', seed => $seed, template => $template,
        context => 'concurrency', expression => "$n", confidence => 'C', features => [$template]
    } }
}

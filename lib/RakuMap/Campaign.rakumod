unit module RakuMap::Campaign;

use RakuMap::Generator::Registry;
use RakuMap::Runner;

sub json-escape(Str:D $s --> Str:D) {
    my $out = '';
    for $s.ords -> $o {
        given $o {
            when 34 { $out ~= '\\"' }; when 92 { $out ~= '\\\\' };
            when 10 { $out ~= '\\n' }; when 13 { $out ~= '\\r' };
            when 9 { $out ~= '\\t' };
            default { $out ~= $o < 32 ?? sprintf('\\u%04x', $o) !! $o.chr }
        }
    }
    '"' ~ $out ~ '"'
}

sub write-text(IO::Path:D $path, Str:D $text) {
    $path.spurt($text.ends-with("\n") ?? $text !! $text ~ "\n")
}

sub save-observation(IO::Path:D $dir, Str:D $name, %o) {
    write-text($dir.add("$name.compile.stdout"), %o<compile><stdout>);
    write-text($dir.add("$name.compile.stderr"), %o<compile><stderr>);
    write-text($dir.add("$name.stdout"), %o<run><stdout>);
    write-text($dir.add("$name.stderr"), %o<run><stderr>);
}

sub finding-json(Int:D $seed, %case, Str:D $oracle, Str:D $candidate,
                 %oo, %co, Str:D $stability --> Str:D) {
    my %w = %case<witness>;
    my @fields = '  "format": 1',
        '  "generator": ' ~ json-escape(%w<generator>),
        '  "seed": ' ~ $seed,
        '  "confidence": ' ~ json-escape(%w<confidence>),
        '  "context": ' ~ json-escape(%w<context>),
        '  "expression": ' ~ json-escape(%w<expression>),
        '  "oracle": ' ~ json-escape($oracle),
        '  "candidate": ' ~ json-escape($candidate),
        '  "oracle-accepted": ' ~ (%oo<accepted> ?? 'true' !! 'false'),
        '  "candidate-accepted": ' ~ (%co<accepted> ?? 'true' !! 'false'),
        '  "oracle-exit": ' ~ %oo<run><exit>,
        '  "candidate-exit": ' ~ %co<run><exit>,
        '  "stability": ' ~ json-escape($stability);
    '{' ~ "\n" ~ @fields.join(",\n") ~ "\n}\n"
}

sub stable-observation(Str:D $engine, IO::Path:D $source, IO::Path:D $tmp,
                       %first, Int:D :$timeout = 5,
                       Int:D :$repetitions = 2 --> Bool:D) {
    my $want = observation-signature(%first);
    for 2 .. $repetitions { return False if observation-signature(
        observe($engine, $source, $tmp, :$timeout)) ne $want }
    True
}

sub generate-cases(Str:D :$generator = 'numeric', Int:D :$seed = 1,
                   Int:D :$cases = 1, IO::Path:D :$out! --> Int:D) is export {
    $out.mkdir unless $out.d;
    my @generators = selected-generators($generator);
    for @generators -> $name {
        my $dir = @generators.elems > 1 ?? $out.add($name) !! $out;
        $dir.mkdir unless $dir.d;
        for ^$cases -> $offset {
            my $n = $seed + $offset;
            my %case = generate-case($name, $n);
            write-text($dir.add($name ~ '-' ~ $n.fmt('%08d') ~ '.raku'), %case<source>);
        }
    }
    $cases * @generators.elems
}

sub explore(Str:D :$oracle = 'raku', Str:D :$candidate = 'rakupp',
            Str:D :$generator = 'numeric',
            Int:D :$seed = 1, Int:D :$cases = 100, Int:D :$timeout = 5,
            Int:D :$repetitions = 2, IO::Path:D :$out! --> Hash:D) is export {
    $out.mkdir unless $out.d;
    my $tmp = $out.add('tmp'); my $findings = $out.add('findings');
    $tmp.mkdir unless $tmp.d; $findings.mkdir unless $findings.d;
    my $divergent = 0; my $stable = 0; my $invalid = 0;
    my @generators = selected-generators($generator);
    for @generators -> $name {
        for ^$cases -> $offset {
            my $n = $seed + $offset; my %case = generate-case($name, $n);
            my $source = $tmp.add($name ~ '-' ~ $n ~ '.raku');
            write-text($source, %case<source>);
            my %oo = observe($oracle, $source, $tmp, :$timeout);
            my %co = observe($candidate, $source, $tmp, :$timeout);
            $invalid++ unless %oo<accepted>;
            next if observation-signature(%oo) eq observation-signature(%co);
            $divergent++;
            my $os = stable-observation($oracle, $source, $tmp, %oo, :$timeout, :$repetitions);
            my $cs = stable-observation($candidate, $source, $tmp, %co, :$timeout, :$repetitions);
            my $stability = $os && $cs ?? 'stable'
                !! !$os && !$cs ?? 'both-unstable' !! !$os ?? 'oracle-unstable'
                !! 'candidate-unstable';
            $stable++ if $stability eq 'stable';
            my $dir = $findings.add($name ~ '-' ~ $n.fmt('%08d'));
            $dir.mkdir unless $dir.d;
            write-text($dir.add('case.raku'), %case<source>);
            write-text($dir.add('original.raku'), %case<source>);
            $dir.add('finding.json').spurt(finding-json($n, %case, $oracle,
                $candidate, %oo, %co, $stability));
            save-observation($dir, 'oracle', %oo); save-observation($dir, 'candidate', %co);
            write-text($dir.add('oracle.signature'), observation-signature(%oo));
            write-text($dir.add('candidate.signature'), observation-signature(%co));
            say "divergence generator=$name seed=$n $stability -> {$dir.Str}";
        }
    }
    my %summary = cases => $cases * @generators.elems, divergent => $divergent,
        stable => $stable, oracle-invalid => $invalid;
    write-text($out.add('summary.txt'),
        join("\n", %summary.keys.sort.map({ "$_={%summary{$_}}" })));
    %summary
}

sub replay(IO::Path:D $dossier, Str:D :$oracle = 'raku',
           Str:D :$candidate = 'rakupp', Int:D :$timeout = 5 --> Bool:D) is export {
    my $source = $dossier.add('case.raku');
    die "no case.raku in {$dossier.Str}" unless $source.f;
    my $tmp = $dossier.add('.replay'); $tmp.mkdir unless $tmp.d;
    my %oo = observe($oracle, $source, $tmp, :$timeout);
    my %co = observe($candidate, $source, $tmp, :$timeout);
    my $different = observation-signature(%oo) ne observation-signature(%co);
    say $different ?? 'REPRODUCED' !! 'NO DIVERGENCE';
    say "oracle:   " ~ (%oo<accepted> ?? "exit {%oo<run><exit>}" !! 'compile rejected');
    say "candidate:" ~ (%co<accepted> ?? " exit {%co<run><exit>}" !! ' compile rejected');
    $different
}

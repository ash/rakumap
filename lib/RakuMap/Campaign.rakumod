unit module RakuMap::Campaign;

use RakuMap::Generator::Registry;
use RakuMap::Runner;
use RakuMap::Sanitizer;

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
                 Str:D $oracle-id, Str:D $candidate-id, Str:D $cluster,
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
        '  "oracle-identity": ' ~ json-escape($oracle-id),
        '  "candidate-identity": ' ~ json-escape($candidate-id),
        '  "cluster-key": ' ~ json-escape($cluster),
        '  "oracle-accepted": ' ~ (%oo<accepted> ?? 'true' !! 'false'),
        '  "candidate-accepted": ' ~ (%co<accepted> ?? 'true' !! 'false'),
        '  "oracle-exit": ' ~ %oo<run><exit>,
        '  "candidate-exit": ' ~ %co<run><exit>,
        '  "sanitizer": ' ~ json-escape(sanitizer-classification(%co)),
        '  "stability": ' ~ json-escape($stability);
    '{' ~ "\n" ~ @fields.join(",\n") ~ "\n}\n"
}

sub stable-observation(Str:D $engine, IO::Path:D $source, IO::Path:D $tmp,
                       %first, Int:D :$timeout = 5,
                       Int:D :$repetitions = 2,
                       Int:D :$max-output = 65536 --> Bool:D) {
    my $want = observation-signature(%first);
    for 2 .. $repetitions { return False if observation-signature(
        observe($engine, $source, $tmp, :$timeout, :$max-output)) ne $want }
    True
}

sub signature-key(Str:D $generator, Str:D $template, Str:D $pair --> Str:D) {
    my Int $hash = 5381;
    for ($generator ~ "\x1f" ~ $template ~ "\x1f" ~ $pair).ords -> $ord {
        $hash = (($hash * 33) + $ord) % 4294967291;
    }
    $generator ~ '-' ~ $template ~ '-' ~ $hash.fmt('%08x')
}

sub atomic-write(IO::Path:D $path, Str:D $text) {
    my $temporary = $path.parent.add($path.basename ~ '.tmp-' ~ $*PID);
    write-text($temporary, $text);
    $temporary.rename($path);
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
            Int:D :$repetitions = 2, Int:D :$max-output = 65536,
            Bool:D :$resume = False, IO::Path:D :$out! --> Hash:D) is export {
    $out.mkdir unless $out.d;
    my $tmp = $out.add('tmp'); my $findings = $out.add('findings');
    my $results = $out.add('results');
    $tmp.mkdir unless $tmp.d; $findings.mkdir unless $findings.d;
    $results.mkdir unless $results.d;
    my $oracle-id = engine-identity($oracle, $tmp);
    my $candidate-id = engine-identity($candidate, $tmp);
    atomic-write($out.add('campaign.json'), '{' ~ "\n"
      ~ '  "format": 1,' ~ "\n"
      ~ '  "generator": ' ~ json-escape($generator) ~ ',' ~ "\n"
      ~ '  "seed": ' ~ $seed ~ ',' ~ "\n"
      ~ '  "cases": ' ~ $cases ~ ',' ~ "\n"
      ~ '  "timeout": ' ~ $timeout ~ ',' ~ "\n"
      ~ '  "repetitions": ' ~ $repetitions ~ ',' ~ "\n"
      ~ '  "max-output": ' ~ $max-output ~ ',' ~ "\n"
      ~ '  "oracle": ' ~ json-escape($oracle) ~ ',' ~ "\n"
      ~ '  "oracle-identity": ' ~ json-escape($oracle-id) ~ ',' ~ "\n"
      ~ '  "candidate": ' ~ json-escape($candidate) ~ ',' ~ "\n"
      ~ '  "candidate-identity": ' ~ json-escape($candidate-id) ~ "\n}");
    my $divergent = 0; my $stable = 0; my $invalid = 0; my $sanitizer = 0;
    my %clusters;
    my @generators = selected-generators($generator);
    for @generators -> $name {
        for ^$cases -> $offset {
            my $n = $seed + $offset; my %case = generate-case($name, $n);
            my $result = $results.add($name ~ '-' ~ $n.fmt('%08d') ~ '.tsv');
            if $resume && $result.f {
                my ($d, $s, $i, $z, $cluster) = $result.slurp.trim.split("\t");
                $divergent += +$d; $stable += +$s; $invalid += +$i; $sanitizer += +$z;
                %clusters{$cluster}<count>++ if $cluster.chars;
                %clusters{$cluster}<seed> //= $n if $cluster.chars;
                next;
            }
            my $source = $tmp.add($name ~ '-' ~ $n ~ '.raku');
            write-text($source, %case<source>);
            my %oo = observe($oracle, $source, $tmp, :$timeout, :$max-output);
            my %co = observe($candidate, $source, $tmp, :$timeout, :$max-output);
            my $has-sanitizer = sanitizer-classification(%co) ne 'none';
            $sanitizer++ if $has-sanitizer;
            my $expects-rejection = (%case<witness><expected> // '') eq 'reject';
            my $is-invalid = !(%oo<accepted> || $expects-rejection);
            $invalid++ if $is-invalid;
            my $pair = observation-signature(%oo) ~ "\x1d" ~ observation-signature(%co);
            unless observation-signature(%oo) ne observation-signature(%co) {
                atomic-write($result, "0\t0\t{$is-invalid.Int}\t{$has-sanitizer.Int}\t"); next;
            }
            $divergent++;
            my $os = stable-observation($oracle, $source, $tmp, %oo, :$timeout, :$repetitions, :$max-output);
            my $cs = stable-observation($candidate, $source, $tmp, %co, :$timeout, :$repetitions, :$max-output);
            my $stability = $os && $cs ?? 'stable'
                !! !$os && !$cs ?? 'both-unstable' !! !$os ?? 'oracle-unstable'
                !! 'candidate-unstable';
            $stable++ if $stability eq 'stable';
            my $cluster = signature-key($name,
                (%case<witness><template> // 'generated').Str, $pair);
            %clusters{$cluster}<count>++;
            %clusters{$cluster}<seed> //= $n;
            my $dir = $findings.add($name ~ '-' ~ $n.fmt('%08d'));
            $dir.mkdir unless $dir.d;
            write-text($dir.add('case.raku'), %case<source>);
            write-text($dir.add('original.raku'), %case<source>);
            $dir.add('finding.json').spurt(finding-json($n, %case, $oracle,
                $candidate, $oracle-id, $candidate-id, $cluster, %oo, %co, $stability));
            save-observation($dir, 'oracle', %oo); save-observation($dir, 'candidate', %co);
            write-text($dir.add('oracle.signature'), observation-signature(%oo));
            write-text($dir.add('candidate.signature'), observation-signature(%co));
            atomic-write($result, "1\t{($stability eq 'stable').Int}\t{$is-invalid.Int}\t{$has-sanitizer.Int}\t$cluster");
            say "divergence generator=$name seed=$n $stability -> {$dir.Str}";
        }
    }
    my %summary = cases => $cases * @generators.elems, divergent => $divergent,
        stable => $stable, oracle-invalid => $invalid, sanitizer => $sanitizer;
    write-text($out.add('summary.txt'),
        join("\n", %summary.keys.sort.map({ "$_={%summary{$_}}" })));
    write-text($out.add('clusters.tsv'), "cluster\tcount\trepresentative-seed\n" ~
        %clusters.keys.sort.map({ "$_\t{%clusters{$_}<count>}\t{%clusters{$_}<seed>}" }).join("\n"));
    %summary
}

sub recorded-string(IO::Path:D $json, Str:D $name --> Str) {
    return Str unless $json.f;
    my $prefix = '  "' ~ $name ~ '": "';
    my $line = $json.lines.first(*.starts-with($prefix));
    return Str unless $line.defined;
    $line.substr($prefix.chars).subst(/ '"' ','? \s* $/, '')
        .subst('\\n', "\n", :g).subst('\\"', '"', :g).subst('\\\\', '\\', :g)
}

sub replay(IO::Path:D $dossier, Str:D :$oracle = 'raku',
           Str:D :$candidate = 'rakupp', Int:D :$timeout = 5,
           Bool:D :$relax-identity = False --> Bool:D) is export {
    my $source = $dossier.add('case.raku');
    die "no case.raku in {$dossier.Str}" unless $source.f;
    my $tmp = $dossier.add('.replay'); $tmp.mkdir unless $tmp.d;
    unless $relax-identity {
        my $metadata = $dossier.add('finding.json');
        my $want-oracle = recorded-string($metadata, 'oracle-identity');
        my $want-candidate = recorded-string($metadata, 'candidate-identity');
        my $got-oracle = engine-identity($oracle, $tmp);
        my $got-candidate = engine-identity($candidate, $tmp);
        die "oracle identity mismatch: recorded '$want-oracle', got '$got-oracle'"
            if $want-oracle.defined && $want-oracle ne $got-oracle;
        die "candidate identity mismatch: recorded '$want-candidate', got '$got-candidate'"
            if $want-candidate.defined && $want-candidate ne $got-candidate;
    }
    my %oo = observe($oracle, $source, $tmp, :$timeout);
    my %co = observe($candidate, $source, $tmp, :$timeout);
    my $different = observation-signature(%oo) ne observation-signature(%co);
    say $different ?? 'REPRODUCED' !! 'NO DIVERGENCE';
    say "oracle:   " ~ (%oo<accepted> ?? "exit {%oo<run><exit>}" !! 'compile rejected');
    say "candidate:" ~ (%co<accepted> ?? " exit {%co<run><exit>}" !! ' compile rejected');
    $different
}

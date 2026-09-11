unit module RakuMap::Shrink;

use RakuMap::Runner;

sub json-string(Str:D $value --> Str:D) {
    '"' ~ $value.subst('\\', '\\\\', :g).subst('"', '\\"', :g)
        .subst("\n", '\\n', :g) ~ '"'
}

sub matching-pair(Str:D $source, Str:D $oracle, Str:D $candidate,
                  Str:D $oracle-signature, Str:D $candidate-signature,
                  IO::Path:D $tmp, Int:D :$timeout, Int:D :$repetitions,
                  Int:D :$max-output --> Bool:D) {
    my $path = $tmp.add('candidate.raku');
    $path.spurt($source);
    for ^$repetitions {
        return False unless observation-signature(observe($oracle, $path, $tmp,
            :$timeout, :$max-output)) eq $oracle-signature;
        return False unless observation-signature(observe($candidate, $path, $tmp,
            :$timeout, :$max-output)) eq $candidate-signature;
    }
    True
}

sub shrink-dossier(IO::Path:D $dossier, Str:D :$oracle!, Str:D :$candidate!,
                    Int:D :$timeout = 5, Int:D :$repetitions = 2,
                    Int:D :$max-output = 65536, Int:D :$budget = 200 --> Hash:D) is export {
    my $case = $dossier.add('case.raku');
    die "no case.raku in {$dossier.Str}" unless $case.f;
    my $original = $dossier.add('original.raku');
    $original.spurt($case.slurp) unless $original.f;
    my $oracle-signature = $dossier.add('oracle.signature').slurp.chomp;
    my $candidate-signature = $dossier.add('candidate.signature').slurp.chomp;
    my $tmp = $dossier.add('.shrink'); $tmp.mkdir unless $tmp.d;
    my $source = $case.slurp;
    my $calls = 0; my $changed = True;
    while $changed && $calls < $budget {
        $changed = False;
        my @lines = $source.lines;
        for reverse ^@lines.elems -> $index {
            last if $calls >= $budget;
            my @candidate-lines = @lines;
            @candidate-lines.splice($index, 1);
            my $attempt = @candidate-lines.join("\n") ~ (@candidate-lines.elems ?? "\n" !! '');
            $calls++;
            if matching-pair($attempt, $oracle, $candidate,
                    $oracle-signature, $candidate-signature, $tmp,
                    :$timeout, :$repetitions, :$max-output) {
                $source = $attempt; $changed = True; last;
            }
        }
    }
    $case.spurt($source);
    my %result = calls => $calls, original-bytes => $original.s,
        minimum-bytes => $source.encode.elems,
        exhausted => $calls >= $budget;
    $dossier.add('shrink.json').spurt('{\n'
      ~ '  "format": 1,\n'
      ~ '  "strategy": "statement-line-v1",\n'
      ~ '  "calls": ' ~ $calls ~ ',\n'
      ~ '  "original-bytes": ' ~ %result<original-bytes> ~ ',\n'
      ~ '  "minimum-bytes": ' ~ %result<minimum-bytes> ~ ',\n'
      ~ '  "budget": ' ~ $budget ~ ',\n'
      ~ '  "exhausted": ' ~ (%result<exhausted> ?? 'true' !! 'false') ~ "\n}\n");
    %result
}

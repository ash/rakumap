unit module RakuMap::Runner;

my $GUARD = 0;

sub sh-quote(Str:D $s --> Str:D) { "'" ~ $s.subst("'", "'\\''", :g) ~ "'" }

sub run-guarded(Str:D $engine, @args, IO::Path:D $tmp,
                Int:D :$timeout = 5 --> Hash:D) is export {
    $tmp.mkdir unless $tmp.d;
    my $base = $tmp.add('guard-' ~ $*PID ~ '-' ~ $GUARD++).absolute;
    my $out-file = $base ~ '.out';
    my $err-file = $base ~ '.err';
    my $line = ([$engine, |@args].map({ sh-quote(~$_) })).join(' ');
    my $script = "exec >/dev/null 2>&1; set -m 2>/dev/null || true; "
        ~ "$line > {sh-quote($out-file)} 2> {sh-quote($err-file)} & p=\$!; "
        ~ "( sleep $timeout; kill -9 -\$p 2>/dev/null || kill -9 \$p 2>/dev/null ) & w=\$!; "
        ~ "wait \$p; rc=\$?; kill \$w 2>/dev/null; wait \$w 2>/dev/null; exit \$rc";
    my $started = now;
    my $proc = run('/bin/sh', '-c', $script);
    my $elapsed = ((now - $started) * 1000).Int;
    my $out = $out-file.IO.e ?? $out-file.IO.slurp !! '';
    my $err = $err-file.IO.e ?? $err-file.IO.slurp !! '';
    $out-file.IO.unlink if $out-file.IO.e;
    $err-file.IO.unlink if $err-file.IO.e;
    { status => $proc.exitcode == 137 ?? 'timeout' !! 'completed',
      exit => $proc.exitcode, stdout => $out, stderr => $err,
      duration-ms => $elapsed }
}

sub observe(Str:D $engine, IO::Path:D $source, IO::Path:D $tmp,
            Int:D :$timeout = 5 --> Hash:D) is export {
    my %compile = run-guarded($engine, ['-c', $source.absolute.Str], $tmp, :$timeout);
    my $accepted = %compile<status> eq 'completed' && %compile<exit> == 0;
    if %compile<status> eq 'completed' {
        %compile<status> = $accepted ?? 'accepted' !! 'rejected';
    }
    my %run = $accepted
        ?? run-guarded($engine, [$source.absolute.Str], $tmp, :$timeout)
        !! { status => 'not-run', exit => -1, stdout => '', stderr => '', duration-ms => 0 };
    { engine => $engine, compile => %compile, accepted => $accepted, run => %run }
}

sub observation-signature(%o --> Str:D) is export {
    join("\x1e", %o<accepted> ?? 'accept' !! 'reject',
        %o<compile><status>, %o<compile><exit>, %o<run><status>,
        %o<run><exit>, %o<run><stdout>, %o<run><stderr>)
}

unit module Rakumap::Generator::Registry;

use Rakumap::Generator::Numeric;
use Rakumap::Generator::Containers;
use Rakumap::Generator::Signatures;
use Rakumap::Generator::Unicode;
use Rakumap::Generator::Regex;
use Rakumap::Generator::Control;
use Rakumap::Generator::Operators;
use Rakumap::Generator::Types;
use Rakumap::Generator::Variables;
use Rakumap::Generator::Subs;
use Rakumap::Generator::Methods;
use Rakumap::Generator::Builtins;
use Rakumap::Generator::Literals;
use Rakumap::Generator::Phasers;
use Rakumap::Generator::Concurrency;
use Rakumap::Generator::Invalid;

our constant @GENERATORS is export = <numeric containers signatures unicode regex control operators types variables subs methods builtins literals phasers concurrency invalid>;

sub generator-names(--> List:D) is export { @GENERATORS.List }

sub selected-generators(Str:D $selection --> List:D) is export {
    return generator-names() if $selection eq 'all';
    die "unknown generator '$selection' (choose {generator-names().join(', ')} or all)"
        unless $selection (elem) @GENERATORS;
    ($selection,).List
}

sub generate-case(Str:D $generator, Int:D $seed --> Hash:D) is export {
    given $generator {
        when 'numeric' { generate-numeric($seed) }
        when 'containers' { generate-containers($seed) }
        when 'signatures' { generate-signatures($seed) }
        when 'unicode' { generate-unicode($seed) }
        when 'regex' { generate-regex($seed) }
        when 'control' { generate-control($seed) }
        when 'operators' { generate-operators($seed) }
        when 'types' { generate-types($seed) }
        when 'variables' { generate-variables($seed) }
        when 'subs' { generate-subs($seed) }
        when 'methods' { generate-methods($seed) }
        when 'builtins' { generate-builtins($seed) }
        when 'literals' { generate-literals($seed) }
        when 'phasers' { generate-phasers($seed) }
        when 'concurrency' { generate-concurrency($seed) }
        when 'invalid' { generate-invalid($seed) }
        default { die "unknown generator '$generator'" }
    }
}

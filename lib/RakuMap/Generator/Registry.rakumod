unit module RakuMap::Generator::Registry;

use RakuMap::Generator::Numeric;
use RakuMap::Generator::Containers;
use RakuMap::Generator::Signatures;
use RakuMap::Generator::Unicode;
use RakuMap::Generator::Regex;
use RakuMap::Generator::Control;
use RakuMap::Generator::Operators;
use RakuMap::Generator::Types;
use RakuMap::Generator::Variables;

our constant @GENERATORS is export = <numeric containers signatures unicode regex control operators types variables>;

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
        default { die "unknown generator '$generator'" }
    }
}

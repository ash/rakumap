unit module RakuMap::Generator::Registry;

use RakuMap::Generator::Numeric;
use RakuMap::Generator::Containers;
use RakuMap::Generator::Signatures;

our constant @GENERATORS is export = <numeric containers signatures>;

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
        default { die "unknown generator '$generator'" }
    }
}

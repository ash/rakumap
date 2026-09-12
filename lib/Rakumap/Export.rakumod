unit module Rakumap::Export;

my constant @CLASSIFICATIONS =
    'candidate-defect', 'intentional-divergence', 'oracle-suspect',
    'unspecified', 'unsupported-feature', 'duplicate', 'generator-defect',
    'normalizer-defect', 'pending';

sub json-escape(Str:D $value --> Str:D) {
    '"' ~ $value.subst('\\', '\\\\', :g).subst('"', '\\"', :g)
        .subst("\n", '\\n', :g).subst("\r", '\\r', :g)
        .subst("\t", '\\t', :g) ~ '"'
}

sub classify-dossier(IO::Path:D $dossier, Str:D $classification --> IO::Path:D) is export {
    die "unknown classification '$classification'" unless $classification (elem) @CLASSIFICATIONS;
    my $path = $dossier.add('classification.txt');
    $path.spurt($classification ~ "\n"); $path
}

sub export-dossier(IO::Path:D $dossier, Str:D :$format!, IO::Path:D :$out! --> IO::Path:D) is export {
    my $case = $dossier.add('case.raku');
    die "no case.raku in {$dossier.Str}" unless $case.f;
    my $source = $case.slurp;
    my $classification = $dossier.add('classification.txt').f
        ?? $dossier.add('classification.txt').slurp.trim !! 'pending';
    given $format {
        when 'rakupp' {
            $out.spurt($source ~ ($source.ends-with("\n") ?? '' !! "\n") ~ "say \"PASS\";\n");
        }
        when 'rakugrid' {
            my $oracle = $dossier.add('oracle.stdout').f ?? $dossier.add('oracle.stdout').slurp !! '';
            $out.spurt('{' ~ "\n  \"format\": 1,\n  \"kind\": \"rakumap-finding\",\n"
              ~ '  "classification": ' ~ json-escape($classification) ~ ",\n"
              ~ '  "source": ' ~ json-escape($source) ~ ",\n"
              ~ '  "oracle-output": ' ~ json-escape($oracle) ~ "\n}\n");
        }
        when 'standalone' {
            $out.spurt("# Rakumap finding\n\nClassification: `$classification`\n\n"
              ~ "```raku\n$source" ~ ($source.ends-with("\n") ?? '' !! "\n") ~ "```\n");
        }
        default { die "unknown export format '$format'" }
    }
    $out
}

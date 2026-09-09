unit module RakuMap::Generator::Unicode;

# These are source literals, not host strings: retaining both composed and
# decomposed spellings is the point of this domain.
my constant @STRINGS =
    '"é"', '"é"', '"Straße"', '"Σίσυφος"', '"👩‍💻"',
    '"नमस्ते"', '"Ångström"', '"東京"';
my constant @TEMPLATES =
    'grapheme-shape', 'codepoint-shape', 'normalize-nfc', 'normalize-nfd',
    'uppercase', 'lowercase', 'substr-grapheme', 'comb-grapheme',
    'ord-roundtrip', 'utf8-roundtrip', 'search', 'translation';

sub choice(Int:D $seed, Int:D $salt, Int:D $size --> Int:D) {
    (($seed.abs + 1) * 48271 + $salt * 7919) % 2147483647 % $size
}

sub generate-unicode(Int:D $seed --> Hash:D) is export {
    my $template = @TEMPLATES[choice($seed, 1, @TEMPLATES.elems)];
    my $text = @STRINGS[choice($seed, 2, @STRINGS.elems)];
    my $body = do given $template {
        when 'grapheme-shape' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $value = ($source.chars, $source.comb.elems);'
        }
        when 'codepoint-shape' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $value = ($source.codes, $source.ords);'
        }
        when 'normalize-nfc' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $normalized = $source.NFC;' ~ "\n"
              ~ 'my $value = ($normalized.Str, [$normalized.list]);'
        }
        when 'normalize-nfd' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $normalized = $source.NFD;' ~ "\n"
              ~ 'my $value = ($normalized.Str, [$normalized.list]);'
        }
        when 'uppercase' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $value = ($source.uc, $source.uc.ords);'
        }
        when 'lowercase' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $value = ($source.lc, $source.lc.ords);'
        }
        when 'substr-grapheme' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $value = (0 ..^ $source.chars).map({ $source.substr($_, 1) });'
        }
        when 'comb-grapheme' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $value = $source.comb.map({ ($_.Str, $_.ords) });'
        }
        when 'ord-roundtrip' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $value = ($source.ords.map(*.chr).join, $source.ords);'
        }
        when 'utf8-roundtrip' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $bytes = $source.encode("utf8");' ~ "\n"
              ~ 'my $value = ($bytes.list, $bytes.decode("utf8"));'
        }
        when 'search' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $needle = $source.substr(0, 1);' ~ "\n"
              ~ 'my $value = ($source.index($needle), $source.starts-with($needle), $source.ends-with($needle));'
        }
        when 'translation' {
            'my $source = ' ~ $text ~ ";\n"
              ~ 'my $value = $source.trans(["a".."z"] => ["A".."Z"]);'
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
        generator => 'unicode-v1', seed => $seed, template => $template,
        context => 'unicode', expression => $text,
        confidence => 'C', features => [$template]
    } }
}

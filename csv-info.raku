=begin comment

Author: Krzysztof Cieslak

The script is used to determine the delimiters and data types of the given CSV 
file. 

=end comment
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
use lib ('.\lib');
use csv-delimiter;
use csv-types;

sub get_number_of_lines($fileHandler) {
    my $result = $fileHandler.lines.elems;
    $fileHandler.seek(0);
    $result;
}

sub about() {
    say "\n[{$*PROGRAM-NAME}] by Krzysztof Cieslak!2021\n";
}

subset encoding of Str where * (elem) (
    "utf8", 
    "utf16", 
    "utf16le", 
    "utf16be", 
    "utf8-c8", 
    "iso-8859-1", 
    "windows-1251", 
    "windows-1252", 
    "windows-932", 
    "ascii"
);

subset Char of Str where { $_ ?? $_.chars == 1 !! True; };

sub MAIN(
          $file, 
    Char :$delimiter,             #= Delimiter.
    UInt :$skip-header = 0,       #= Skip the first N lines during fields
                                  #= analysis.
    encoding :$encoding = "utf8"  #= File encoding: utf8 (default), utf16, 
                                  #= utf16le, utf16be, utf8-c8, iso-8859-1, 
                                  #= windows-1251, windows-1252, windows-932, 
                                  #= ascii
) {
    about;

    with $file.IO {
        my $fh will leave {.close} = .open;
        $fh.encoding: $encoding;

        say "CSV File {$file}:\n";

        my @delimiters;
        my $number_of_lines = get_number_of_lines($fh);
        say "Number of lines: {$number_of_lines}";

        if $number_of_lines == 0 {
            say "Nothing to do.";
            exit;
        }

        with $delimiter {
            @delimiters = $delimiter;
            say "Delimiter: {get_escaped_char($delimiter.first)}";
        }
        else {
            @delimiters = get_delimiters($fh);
            if @delimiters.elems > 0 {
                say "Delimiters: { @delimiters.map({get_escaped_char($_)}) }";
            } else {
                say "Delimiters: Not found";
                exit(1);
            }
        }

        if ($skip-header > 0) {
            say "Skipping header lines: {$skip-header}";
        }

        my @fields_types = get_fields_types(
            $fh,
            @delimiters.first, 
            $skip-header
        );

        say "\nField type: ";
        for ^@fields_types.elems -> $idx {
            say "[{$idx}] {@fields_types[$idx].Str}"
        }

        say "";
    }
}

sub USAGE(){
    about;
    say "{$*USAGE}\n";
}

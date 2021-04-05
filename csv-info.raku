=begin comment

Author: Krzysztof Cieslak

The script is used to determine the delimiters and data types of the given CSV 
file. 

=end comment
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
my @common_delimiters = ( 
    "|", 
    ";", 
    "\t",
    ","
);

my regex IntegerRegex {
    ^^ \-?\d+ $$
    ||
    ^^$$
};

my regex DecimalRegex {
    ^^(<[+-]>?\d+)?(<[,.]>\d+)?$$
    ||
    ^^$$
};

my regex DateTimeRegex {
    ^^
    (
        \d ** 4 (<[-./]> ** 1) \d ** 2 $0 \d ** 2
        ||
        \d ** 2 (<[-./]> ** 1) \d ** 2 $0 \d ** 4
    )?(
        (<[\sT]>||^^)\d ** 2 \: \d ** 2 (\: \d ** 2)?
    )?
    $$
};

class ProgressiveType {
    has @!types = [
        { name => "Unknown", 
          validate => -> $value { $value.chars == 0 } 
        },
        { name => "Integer", 
          validate => -> $value { so $value ~~ &IntegerRegex } 
        },
        { name => "Decimal", 
          validate => -> $value { so $value ~~ &DecimalRegex } 
        },
        { name => "Datetime", 
          validate => -> $value { so $value ~~ &DateTimeRegex } 
        },
        { name => "String",
          validate => -> $value { True } 
        },
    ];

    method validate($value) {
        until @!types.first<validate>($value) || @!types.elems == 0 {
            @!types.shift;
        }
    }

    method Str() {
        @!types.first<name>;
    }
}

sub get_delimiters($fileHandler) {
    my %chars_o;  # characters occurences
    my %chars_ol; # characters occurences per line
    my %temp;

    for $fileHandler.lines -> $line {
        next unless $line;

        %temp{$_}++ for $line.comb;

        unless %chars_o {
            %chars_o{%temp.keys} = 0 xx *;
            %chars_ol = %temp;
            %temp = Empty;

            next;
        }

        for %chars_ol{%temp.keys}:k -> $t {
            next if %chars_ol{$t} != %temp{$t};
            %chars_o{$t}++;
        }

        %temp = Empty;
    }
    $fileHandler.seek(0);
    %chars_o
       ==> grep({ 
               $_.key ~~ /<-[a..zA..Z0..9\"\']>/
               && $_.value == %chars_o.values.max
           })
       ==> sort({
          $^a.key (elem) @common_delimiters ?? 0 !! 1
       })
       ==> map({ $_.key })
}

sub get_escaped_char($c) {
    my $result = $c;
    given ord($c) {
        when 9 { $result = '\t' }
        when 32 { $result = '\s' }
    }
    $result;
}

sub get_fields_types($fileHandler, $delimiter, $from) {
    my @fields_types of ProgressiveType;
    my @fields;

    for $fileHandler.lines[$from..*] -> $line {
        next unless $line;

        @fields = $line.split($delimiter);
        
        unless @fields_types {
            @fields_types = ProgressiveType.new xx ^@fields.elems;
        }
        
        if @fields.elems > @fields_types.elems {
            @fields_types.append: 
                ProgressiveType.new xx @fields.elems - @fields_types.elems;
        }
        
        (^@fields.elems).map({ @fields_types[$_].validate(@fields[$_]) });
    }
    $fileHandler.seek(0);
    @fields_types;
}

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

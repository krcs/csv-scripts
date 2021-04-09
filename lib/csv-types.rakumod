unit module csv-types;

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

sub get_fields_types($fileHandler, $delimiter, $from) is export {
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


unit module csv-delimiter;

my @common_delimiters = ( 
    "|", 
    ";", 
    "\t",
    ","
);

sub get_delimiters($fileHandler) is export {
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

sub get_escaped_char($c) is export {
    my $result = $c;
    given ord($c) {
        when 9 { $result = '\t' }
        when 32 { $result = '\s' }
    }
    $result;
}

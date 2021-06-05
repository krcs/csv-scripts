# csv-scripts

## csv-info.raku
The script is used to determine the delimiters and data types of the given CSV file. 

Usage:
``` 
.\csv-info.raku [--delimiter=<Char>] [--skip-header[=UInt]] [--encoding=<encoding>] <file>

    --delimiter=<Char>       Delimiter.
    --skip-header[=UInt]     Skip the first N lines during fields analysis.
    --encoding=<encoding>    File encoding: utf8 (default), utf16, utf16le, utf16be, 
                                            utf8-c8, iso-8859-1, windows-1251, windows-1252, 
                                            windows-932, ascii
```

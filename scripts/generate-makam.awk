BEGIN { inmakam = 0; inyaml = 0;
        outputfile = gensub(/.md$/, ".makam", "g", ARGV[1]);
        print "Generating", outputfile;
        print "(*" > outputfile }

/^---$/ { if (inyaml == 0) { inyaml = 1; } else if (inyaml == 1) { inyaml = 2; } }
/^```makam$/ { print "*)" >> outputfile; print "" >> outputfile; inmakam = 1 }
/^```$/ { if (inmakam) { inmakam = 0; print "" >> outputfile; print "(*" >> outputfile;} else { print $0 >> outputfile } }
/^>>/ { if (inmakam) { print "(*" >> outputfile; print $0 >> outputfile; print "*)" >> outputfile; } }
!(/^---$/ || /^```$/ || /^```makam$/ || /^>>/) { if (inyaml == 2) { print $0 >> outputfile } }

END { if (!inmakam) { print "*)" >> outputfile } }

BEGIN { inmakam = 0; inyaml = 0;
        outputfile = gensub(/.md$/, ".makam", "g", ARGV[1]);
        print "Generating", outputfile;
        print "(*" > outputfile }

/^---$/ { if (inyaml) { inyaml = 0; } else { inyaml = 1; } }
/^```makam$/ { print "*)" >> outputfile; print "" >> outputfile; inmakam = 1 }
/^```$/ { if (inmakam) { inmakam = 0; print "" >> outputfile; print "(*" >> outputfile;} else { print $0 >> outputfile } }
!(/^---$/ || /^```$/ || /^```makam$/) { if (!inyaml) { print $0 >> outputfile } }

END { if (!inmakam) { print "*)" >> outputfile } }

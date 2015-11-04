BEGIN { inmakam = 0; outputfile = gensub(/.md$/, ".makam", "g", ARGV[1]); print "" > outputfile }
/^```makam$/ { inmakam = 1 }
/^```$/ { if (inmakam) { inmakam = 0; print "" >> outputfile; } }
! /^```/ { if (inmakam) print $0 >> outputfile }

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use AI::NeuralNet::BackProp;
$loaded = 1;
print "ok 1\n";

my $net = new AI::NeuralNet::BackProp(2,3);
$out = ($net)?"ok 2":"not ok 2";
print "$out\n";

$out = ($net->learn([1,1,2],[2,2,1]))?"ok 3":"not ok 3";
print "$out\n";

$out = ($net->learn([3,4,3],[5,3,5]))?"ok 4":"not ok 4";
print "$out\n";

$out = ($net->run([3,1,1]))?"ok 5":"not ok 5";
print "$out\n";

$out = ($net->intr(0.5) eq 1)?"ok 6":"not ok 6";
print "$out\n";



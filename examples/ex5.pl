=begin

File:   ex2.pl
Author: Josiah Bryan, jdb@wcoil.com

This demonstrates more simple pattern learning.
This also demonstrates saving of the network state and
showing the weight outputs. ex6.pl demonstrates loading the
netwrok again.

=cut

	use AI::NeuralNet::BackProp;
	
	# Create a new neural net with 2 layers and 3 neurons per layer
	my $net = new AI::NeuralNet::BackProp(2,3);

#	$net->debug(1);
	
	for(0..4) {
		for my $x (0..2) {
			@a = ($x+1,$x+2,$x+3);
			@b = ($x+4,$x+5,$x+6);
			print join(",",@a)," ",$net->learn(\@a,\@a),"\n";
			print join(",",@b)," ",$net->learn(\@b,\@b),"\n";
		}
	}
	
	# Run a test pattern
	print "1,2,3:".join(',',@{$net->run([1,2,3])})."\n";
	print "4,5,6:".join(',',@{$net->run([4,5,6])})."\n";
	
	$net->show();
	
	$net->save("ex5.net");
	

=begin

File:   ex6.pl
Author: Josiah Bryan, jdb@wcoil.com

This demonstrates loading the network state completly from
disk without having to re-learn anything.

=cut

	use AI::NeuralNet::BackProp;
	
	# Create a new neural net with 2 layers and 3 neurons per layer
	my $net = new AI::NeuralNet::BackProp(2,3);

#	$net->debug(1);
	
	$net->load("ex5.net");
	
	# Run a test pattern
	print "1,2,3:".join(',',@{$net->run([1,2,3])})."\n";
	print "4,5,6:".join(',',@{$net->run([4,5,6])})."\n";
	
	$net->show();
	

=begin

File:   ex4.pl
Author: Josiah Bryan, jdb@wcoil.com

This network trains itself to recognize "good" and "bad" beats, as in 
drum beats. Think of a 2 as a beat and a 1 as a rest. This network 
uses only one output neuron, which goes to 2 if it is a good beat, or
2 if it is a bad beat.

=cut

	use AI::NeuralNet::BackProp;
	$net=AI::NeuralNet::BackProp->new(2,10,1);
	print "Learning bad (1) and good (2) beats...\n";
	for (1..3) {
		@a=(1,1,1,1,1,
			1,1,1,1,1); 
		print $net->learn(\@a,[1], max=>100,inc=>0.17)."\n";
		print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 
		@a=(2,2,2,2,2,
			2,2,2,2,2); 
		print $net->learn(\@a,[2], max=>100,inc=>0.17)."\n";
		print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 
	}	
	
	print "Running test beats...\n";
	@a=(1,2,1,1,2,
		1,2,2,1,2); 
	print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 	
	
	@a=(1,2,1,1,1,
		1,1,2,1,2); 
	print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 	

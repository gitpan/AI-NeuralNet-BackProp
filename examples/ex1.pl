=begin

File:   ex1.pl
Author: Josiah Bryan, jdb@wcoil.com

This demonstrates the crunch() and uncrunch() methods.

=cut


	use AI::NeuralNet::BackProp;
	my $net = AI::NeuralNet::BackProp->new(2,3);
	
	for (0..3) {
		$net->learn($net->crunch(qw(I love chips.)),  $net->crunch(qw(That's Junk Food!)));
		$net->learn($net->crunch(qw(I love apples.)), $net->crunch(qw(Good, Healthy Food.)));
		$net->learn($net->crunch(qw(I love pop.)),    $net->crunch(qw(That's Junk Food!)));
		$net->learn($net->crunch(qw(I love oranges.)),$net->crunch(qw(Good, Healthy Food.)));
	}
	
	my $response = $net->run($net->crunch(qw(I love corn.)));
	
	print join(' ',$net->uncrunch($response));

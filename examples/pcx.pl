=begin

File:   pcx.pl
Author: Josiah Bryan, jdb@wcoil.com

This demonstrates simple usage of the pcx loader.

=cut

	use AI::NeuralNet::BackProp;
	
	my $net=AI::NeuralNet::BackProp->new(2,2);
	
	my $img = $net->load_pcx("josiah.pcx");             
	
	$net->join_cols($img->get_block([0,0,50,50]),50,0);
	

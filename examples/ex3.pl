=begin

File:   ex3.pl
Author: Josiah Bryan, jdb@wcoil.com

This demonstrates more simple pattern learning.

=cut

	use AI::NeuralNet::BackProp;
	$net=AI::NeuralNet::BackProp->new(2,4,4);
	@a=(1,2,1,2); 
	print $net->learn(\@a,\@a, max=>100,inc=>0.17)."\n";
	print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 
	@a=(2,2,1,2); 
	print $net->learn(\@a,\@a, max=>100,inc=>0.17)."\n";
	print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 
	@a=(1,1,1,2); 
	print $net->learn(\@a,\@a, max=>100,inc=>0.17)."\n";
	print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 
	
	@a=(1,2,1,2); 
	print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 
	@a=(2,2,1,2); 
	print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 
	@a=(1,1,1,2); 
	print join(",",@a),":",join(",",@{$net->run(\@a)}), "\n"; 

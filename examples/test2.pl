=begin

File:   test2.pl
Author: Josiah Bryan, jdb@wcoil.com

This is just a simple example of association of patterns. We have a
2x2 network (2 layers, 2 neurons per layer). We first teach it two
patters and then run a third pattern and compare results.

=cut

	use AI::NeuralNet::BackProp;

	my $net = new AI::NeuralNet::BackProp(2,2);
	
	#$net->debug(4);
	
	my @map1	=	(1,1);
	my @res1	=	(1,0);
	
    my @map2	=	(1,2);
	my @res2	=	(1,1);
	
	print "Learning started, map1...\n";
	print $net->learn(\@map1,\@res1,0.51)."\n";
	print "Learning done, map1.\n";
	
	print "Learning started, map2...\n";
	print $net->learn(\@map2,\@res2,0.51)."\n";
	print "Learning done, map2...\n";
	
		
	my @map	=	(2,1);
	
	print "Running map (".join(",",@map).")...\n";
		                    
	my $map;
	if(!($map=$net->run(\@map))) {
		print "Error running network map.";
	}
	
	print "\n\nMapping results from $map:\n";
	
	$net->join_cols($map,5); 
	
	print "\nDifference from input and output: ".$net->pdiff(\@map,$map)."\n";
	
	
	
	

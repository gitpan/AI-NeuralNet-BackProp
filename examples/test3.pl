=begin

File:   test2.pl
Author: Josiah Bryan, jdb@wcoil.com
	
This demonstrates the use of a wide range of numbers in learning
and association. Same learn and result process as the rest of
the test*.pl scripts.

=cut

        use AI::NeuralNet::BackProp;

	my $net = new AI::NeuralNet::BackProp(2,3);
	
#	$net->debug(1);
	
	my @map1	=	(1,5,1);
	my @res1	=	(31,1,0);
	
    my @map2	=	(3,5,2);
	my @res2	=	(1,16,5);
	
	print "Learning started, (".join(",",@map1).")...\n";

	print $net->learn(\@map1,\@res1,0.3);

	print "Learning done, (".join(",",@res1).").\n";
	
	print "Learning started, (".join(",",@map2).")...\n";

	print $net->learn(\@map2,\@res2,0.3);

	print "Learning done, (".join(",",@res2).").\n";
	
	my @map	=	(5,10,2);
	
	print "Running map (".join(",",@map).")...\n";
		                    
	my $map=$net->run(\@map);
	
	print "Run results:\n";
	
	AI::NeuralNet::BackProp::join_cols($map,5,0);
	
	print "Diff: Map1 map vs. Map1 result: ".AI::NeuralNet::BackProp::pdiff(\@map1,\@res1)."\%\n";
	print "Diff: Map2 map vs. Map2 result: ".AI::NeuralNet::BackProp::pdiff(\@map2,\@res2)."\%\n";
	print "Diff: Run map vs. Run result:\t".AI::NeuralNet::BackProp::pdiff($map,\@map)."\%\n";
	#print "Diff: Original test map vs. run map:\t\t".AI::NeuralNet::BackProp::pdiff(\@map,\@map1)."\%\n";
	#print "Diff: Original result map vs. run result map:\t".AI::NeuralNet::BackProp::pdiff(\@res1,$map)."\%\n";
	
	

=begin

File:   test2.pl
Author: Josiah Bryan, jdb@wcoil.com

Synopsis example code from embeded POD documentation.

=cut

        use AI::NeuralNet::BackProp;
	
	# Create a new neural net with 2 layers and 3 neurons per layer
	my $net = new AI::NeuralNet::BackProp(2,3);
	
#	$net->debug();
	
	# Associate first pattern and print benchmark
	print "Associating (1,2,3) with (4,5,6)...\n";
	print $net->learn([1,2,3],[4,5,6]);
	
	# Associate second pattern and print benchmark
	print "Associating (4,5,6) with (1,2,3)...\n";
	print $net->learn([4,5,6],[1,2,3]);
	
	# Run a test pattern
	print "\nFirst run output: (".join(',',@{$net->run([1,3,2])}).")\n\n";
	
	
	# Declare patterns to learn
	my @pattern = (	15, 3,  5  );
	my @result  = ( 16, 10, 11 );
	
	# Display patterns to associate using sub interpolation into a string.
	print "Associating (@{[join(',',@pattern)]}) with (@{[join(',',@result)]})...\n";
	
	# Run learning loop and print benchmarking info.
	print $net->learn(\@pattern,\@result);
	
	# Run final test
	my @test 	  = ( 14, 9,  3  );
	my $array_ref = $net->run(\@test);
	
	# Display test output
	print "\nSecond run output: (".join(',',@{$array_ref}).")\n";

=begin

File:   test1.pl
Author: Josiah Bryan, jdb@wcoil.com

This is the first example script. It creates a network with
2 layers and 35 neurons per layer. Then we associate a
digitized 5x7 "J" with a 5x7 "D" using learn() and print benchmark
results. Then we run() a deformed J through the network and compare
results. See letters.pl for another such letter-recognizer.

NOTE: THE LEARN LOOP IS KNOWN TO TAKE LONG TIMES, UP TO 300 SECONDS.

=cut

	use AI::NeuralNet::BackProp;

	# Create a new network with 2 layers and 35 neurons in each layer.
	my $net = new AI::NeuralNet::BackProp(2,35);
	
	# Debug level of 4 gives JUST learn loop iteteration benchmark and comparrison data 
	# as learning progresses.
	$net->debug(4);
	
	# Create our model input
	my @map	=	(1,1,1,1,1,
				 8,8,1,8,8,
				 8,8,1,8,8,
				 8,8,1,8,8,
				 1,8,1,8,8,
				 1,8,1,8,8,
				 1,1,1,8,8);
				 
	# Create our desired output
	my @res	=	(1,1,1,1,8,
				 1,8,8,8,1,
				 1,8,8,8,1,
				 1,8,8,8,1,
				 1,8,8,8,1,
				 1,8,8,8,1,
				 1,1,1,1,8);
	
	# Display input using column formater from AI package.
	print "\nOriginal map:\n";
	AI::NeuralNet::BackProp::join_cols(\@map,5,'');
	
	# Display results map
	print "\nResult map:\n";
	AI::NeuralNet::BackProp::join_cols(\@res,5,'');
	
	print "\nLearning started...\n";
	
	print $net->learn(\@map,\@res,0.1);
	
	print "Learning done.\n";
		
	# Build a test map 
	my @tmp	=	(8,8,1,1,1,
				 1,1,1,8,8,
				 8,8,8,1,8,
				 8,8,8,1,8,
				 8,8,8,1,8,
				 8,8,8,8,8,
				 8,1,1,8,8);
	
	# Display test map
	print "\nTest map:\n";
	AI::NeuralNet::BackProp::join_cols(\@tmp,5,'');
	
	print "Running test...\n";
		                    
	# Run the actual test and get an array refrence to the network output
	my $map=$net->run(\@tmp);
	
	print "Test run complete.\n";
	
	# Display network results
	print "\nMapping results from $map:\n";
	AI::NeuralNet::BackProp::join_cols($map,5,'');
	
	# Calculate percentage diffrence, returning a string formated with "%.1f", represinting
	# the percent diffrence between the two array refences passed.
	# FYI: I have found with the above test map and original maps, that the most difference,
	# or 'noise' the network can handle is 40.0% before the network output map 'peaks' (all
	# outputs high.) Of course, I have also seen it peek at 37.5% and lower, too. Maximum 
	# noise I have acheived w/o peaking is 40.0%.
	print "Percentage difference between original and test map: ".AI::NeuralNet::BackProp::pdiff(\@map,\@tmp)."%\n";
	

=begin

File:   letters.pl
Author: Josiah Bryan, jdb@wcoil.com

This is an example of image recognition.
I have digitized 29 characters of the alphabet of the HP 28S
into a 5*7 matrix. This script runs the learn() method for
each letter, using each letters matrix as its own desired result
pattern. Then we present the network with a deformed J and see how
well it detects the pattern.

NOTE: THE LEARNING LOOP TAKES A _VERY_ LONG TIME. (Up to 1 hour I have seen.)

=cut

	use AI::NeuralNet::BackProp;

	# Create a new network with 2 layers and 35 neurons in each layer.
	my $net = new AI::NeuralNet::BackProp(2,35);
	
	# Debug level of 4 gives JUST learn loop iteteration benchmark and comparrison data 
	# as learning progresses.
	$net->debug(4);

	my @letters = [            # All prototype inputs        
        [
        2,1,1,1,2,             # Inputs are   
        1,2,2,2,1,             #  5*7 digitalized caracters 
        1,2,2,2,1,              
        1,1,1,1,1,
        1,2,2,2,1,             # This is the alphabet of the
        1,2,2,2,1,             # HP 28S                      
        1,2,2,2,1,
        ],[
        1,1,1,1,2,
        1,2,2,2,1,
        1,2,2,2,1,
        1,1,1,1,2,
        1,2,2,2,1,
        1,2,2,2,1,
        1,1,1,1,2,
        ],[
        2,1,1,1,2,
        1,2,2,2,1,
        1,2,2,2,2,
        1,2,2,2,2,
        1,2,2,2,2,
        1,2,2,2,1,
        2,1,1,1,2,
        ],[
        1,1,1,2,2,
        1,2,2,1,2,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,1,2,
        1,1,1,2,2,
        ],[
        1,1,1,1,1,
        1,2,2,2,2,
        1,2,2,2,2,
        1,1,1,1,2,
        1,2,2,2,2,
        1,2,2,2,2,
        1,1,1,1,1,
        ],[
        1,1,1,1,1,
        1,2,2,2,2,
        1,2,2,2,2,
        1,1,1,1,2,
        1,2,2,2,2,
        1,2,2,2,2,
        1,2,2,2,2,
		],[
        2,1,1,1,2,
        1,2,2,2,1,
        1,2,2,2,2,
        1,2,2,2,2,
        1,2,2,1,1,
        1,2,2,2,1,
        2,1,1,1,2,
		],[
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,1,1,1,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
		],[
        1,1,1,1,1,
        2,1,1,1,2,
        2,1,1,1,2,
        2,1,1,1,2,
        2,1,1,1,2,
        2,1,1,1,2,
        1,1,1,1,1,
		],[
        2,2,2,2,1,
        2,2,2,2,1,
        2,2,2,2,1,
        2,2,2,2,1,
        2,2,2,2,1,
        1,2,2,2,1,
        2,1,1,1,2,
		],[
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,1,2,
        1,1,1,2,2,
        1,2,2,1,2,
        1,2,2,2,1,
        1,2,2,2,1,
		],[
        1,2,2,2,2,
        1,2,2,2,2,
        1,2,2,2,2,
        1,2,2,2,2,
        1,2,2,2,2,
        1,2,2,2,2,
        1,1,1,1,1,
		],[
        1,2,2,2,1,
        1,1,2,1,1,
        1,2,1,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
		],[
        1,2,2,2,1,
        1,2,2,2,1,
        1,1,2,2,1,
        1,2,1,2,1,
        1,2,2,1,1,
        1,2,2,2,1,
        1,2,2,2,1,
		],[
        2,1,1,1,2,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        2,1,1,1,2,
		],[
        1,1,1,1,2,
        1,2,2,2,1,
        1,2,2,2,1,
        1,1,1,1,2,
        1,2,2,2,2,
        1,2,2,2,2,
        1,2,2,2,2,
		],[
        2,1,1,1,2,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,1,2,1,
        1,2,2,1,2,
        2,1,1,2,1,
		],[
        1,1,1,1,2,
        1,2,2,2,1,
        1,2,2,2,1,
        1,1,1,1,2,
        1,2,1,2,2,
        1,2,2,1,2,
        1,2,2,2,1,
		],[
        2,1,1,1,2,
        1,2,2,2,1,
        1,2,2,2,2,
        2,1,1,1,2,
        2,2,2,2,1,
        1,2,2,2,1,
        2,1,1,1,2,
		],[
        1,1,1,1,1,
        2,2,1,2,2,
        2,2,1,2,2,
        2,2,1,2,2,
        2,2,1,2,2,
        2,2,1,2,2,
        2,2,1,2,2,
		],[
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        2,1,1,1,2,
		],[
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        2,1,2,1,2,
        2,2,1,2,2,
		],[
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,1,2,1,
        1,2,1,2,1,
        1,1,2,1,1,
        1,2,2,2,1,
		],[
        1,2,2,2,1,
        1,2,2,2,1,
        2,1,2,1,2,
        2,2,1,2,2,
        2,1,2,1,2,
        1,2,2,2,1,
        1,2,2,2,1,
		],[
        1,2,2,2,1,
        1,2,2,2,1,
        2,1,2,1,2,
        2,2,1,2,2,
        2,2,1,2,2,
        2,2,1,2,2,
        2,2,1,2,2,
		],[
        1,1,1,1,1,
        2,2,2,2,1,
        2,2,2,1,2,
        2,2,1,2,2,
        2,1,2,2,2,
        1,2,2,2,2,
        1,1,1,1,1,
		],[
        2,2,1,2,2,
        2,1,1,1,2,
        2,1,2,1,2,
        1,1,2,1,1,
        1,1,1,1,1,
        1,1,2,1,1,
        1,2,2,2,1,
		],[
        1,2,2,2,1,
        2,1,2,2,1,
        2,2,1,1,2,
        2,2,1,1,2,
        2,2,1,2,2,
        2,1,2,2,2,
        1,2,2,2,2,
		],[
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,1,2,1,
        1,1,1,1,1,
        1,1,1,1,1,
        2,1,2,1,2,
        2,1,2,1,2,
        ],[
        1,2,2,2,1,
        1,2,2,2,1,
        1,2,2,2,1,
        1,1,2,1,1,
        2,1,2,1,2,
        2,1,1,1,2,
        2,2,1,2,2
        ]
     ];
	
	print "\nLearning started...\n";
	
	for(0..28) {
		print "\nLearning index $_, map:\n";
		$net->join_cols($letters[0][$_],5);
		$net->learn($letters[0][$_],$letters[0][$_],0.15);
	}
	
	print "Learning done.\n";
		
	# Build a test map 
	my @tmp	=	(2,2,2,1,1,
				 1,1,1,1,2,
				 2,2,2,1,2,
				 2,2,2,1,2,
				 2,2,2,1,2,
				 2,2,1,1,2,
				 2,1,1,2,2);
	
	# Display test map
	print "\nTest map:\n";
	$net->join_cols(\@tmp,5);
	
	print "Running test...\n";
		                    
	# Run the actual test and get an array refrence to the network output
	my $map=$net->run(\@tmp);
	
	print "Test run complete.\n";
	
	# Display network results
	print "\nMatched test pattern to pattern index ".$net->pattern()."\n";
	print "Mapping results from $map:\n";
	$net->join_cols($map,5);
	
	# Calculate percentage diffrence, returning a string formated with "%.1f", represinting
	# the percent diffrence between the two array refences passed.
	# FYI: I have found with the above test map and original maps, that the most difference,
	# or 'noise' the network can handle is 40.0% before the network output map 'peaks' (all
	# outputs high.) Of course, I have also seen it peek at 37.5% and lower, too. Maximum 
	# noise I have acheived w/o peaking is 40.0%.
	print "Percentage difference between original and test map: ".AI::NeuralNet::BackProp::pdiff($letters[0][$net->pattern()-1],\@tmp)."%\n";
	

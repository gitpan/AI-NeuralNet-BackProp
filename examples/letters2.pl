=begin

File:   letters2.pl
Author: Josiah Bryan, jdb@wcoil.com

This is an example of image recognition.
I have digitized 29 characters of the alphabet of the HP 28S
into a 5*7 matrix. This script runs the learn() method for
each letter, using each letters matrix as its own desired result
pattern. Then we present the network with a deformed J and see how
well it detects the pattern.

This is a modification of the original letters.pl script to only
use one output neuron and associate the output neuron with the number
of the pattern being learned.

A trained network is also included in letters2.net.

NOTE: THE LEARNING LOOP TAKES A _VERY_ LONG TIME. (Up to 1 hour I have seen.)

=cut

	use AI::NeuralNet::BackProp;

	# Create a new network with 2 layers and 35 neurons in each layer, with 1 output neuron
	my $net = new AI::NeuralNet::BackProp(2,35,1);
	
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
	
	if(!$net->load("letters2.net")) {
		print "\nLearning started...\n";
	    for my $letter (0..28) {
			print "\nLearning index $letter, map:\n";
			$net->join_cols($letters[0][$letter],5);
			print $net->learn($letters[0][$letter],[$letter],inc=>0.2);
		}
		print "Learning done.\n";
	}
			
	# Build a test map 
	my @tmp	=	(2,1,1,1,2,
				 1,2,2,2,1,
				 1,2,2,2,1,
				 1,1,1,1,1,
				 1,2,2,2,1,
				 1,2,2,2,1,
				 1,2,2,2,1);
	
	# Display test map
	print "\nTest map:\n";
	$net->join_cols(\@tmp,5);
	
	print "Running test...\n";
		                    
	# Run the actual test and get an array refrence to the network output
	my $map=$net->run(\@tmp);
	
	print "Test run complete.\n";
	
	# Display network results
	print "Letter index matched: ",(@{$map})[0],"\n";
	
	# Save learned network
	$net->save("letters2.net");
=begin

File:   finance.pl
Author: Josiah Bryan, jdb@wcoil.com

This demonstrates DOW Avg. predicting using the AI::NeuralNet::BackProp module.

=cut

	use AI::NeuralNet::BackProp;
	use Benchmark;

	# Create a new net with 5 layes, 9 inputs, and 1 output
	my $net = AI::NeuralNet::BackProp->new(3,9,1);
	
	# Disable debugging
	$net->debug(4);
	
	# Create datasets.
	#	Note that these are ficticious values shown for illustration purposes
	#	only.  In the example, CPI is a certain month's consumer price
	#	index, CPI-1 is the index one month before, CPI-3 is the the index 3
	#	months before, etc.

	my @data = ( 
		#	Mo  CPI  CPI-1 CPI-3 	Oil  Oil-1 Oil-3    Dow   Dow-1 Dow-3   Dow Ave (output)
		[	1, 	229, 220,  146, 	20.0, 21.9, 19.5, 	2645, 2652, 2597], 	[	2647  ],
		[	2, 	235, 226,  155, 	19.8, 20.0, 18.3, 	2633, 2645, 2585], 	[	2637  ],
		[	3, 	244, 235,  164, 	19.6, 19.8, 18.1, 	2627, 2633, 2579], 	[	2630  ],
		[	4, 	261, 244,  181, 	19.6, 19.6, 18.1, 	2611, 2627, 2563], 	[	2620  ],
		[	5, 	276, 261,  196, 	19.5, 19.6, 18.0, 	2630, 2611, 2582], 	[	2638  ],
		[	6, 	287, 276,  207, 	19.5, 19.5, 18.0, 	2637, 2630, 2589], 	[	2635  ],
		[	7, 	296, 287,  212, 	19.3, 19.5, 17.8, 	2640, 2637, 2592], 	[	2641  ] 		
	);
    
    
	# If we havnt saved the net already, do the learning
	if(!$net->load('finance.net')) {
		print "\nLearning started...\n";
		
		# Make it learn the whole dataset $top times
		my @list;
		my $top=5;
		for my $a (0..$top) {
			my $t1=new Benchmark;
			print "\n\nOuter Loop: $a\n";
			
			# Test fogetfullness
			my $f = learn_set(\@data,		inc		=>	0.1,	
											max		=>	500,
											error	=>	-1);
			
			# Print it 
			print "\n\nForgetfullness: $f%\n";

			# Save net to disk				
			$net->save('finance.net');

			my $t2=new Benchmark;
			my $td=timediff($t2,$t1);
			print "\nLoop $a took ",timestr($td),"\n";
		}
	}
                                                                          
	# Run a prediction using fake data
	#			Month	CPI  CPI-1 CPI-3 	Oil  Oil-1 Oil-3    Dow   Dow-1 Dow-3    
	my @set=(	10,		352, 309,  203, 	18.3, 18.7, 16.1, 	2592, 2641, 2651	  ); 
	
	# Dow Ave (output)	
	my $fb=$net->run(\@set)->[0];
	
	
	# Print output
	print "\nTest Factors: (",join(',',@set),")\n";
	print "DOW Prediction for Month #11: $fb\n";
	

	# This sub will take an array ref of a data set, which it expects in this format:
	#   my @data_set = (	[ ...inputs... ], [ ...outputs ... ],
	#				   				   ... rows ...
	#				   );
	#
	# This wil sub returns the percentage of 'forgetfullness' when the net learns all the
	# data in the set in order. Usage:
	#
	#
	#	 learn_set_rand(\@data,[ options ]);
	#
	# Options are options in hash form. They can be of any form that $net->learn takes.
	#
	# It returns a percentage string.
	#
	sub learn_set {
		#my $net=shift if(substr($_[0],0,4) eq 'AI::'); 
		my $data=shift;
		my %args = @_;
		my $len=$#{$data}/2-1;
		my $inc=$args{inc};
		my $max=$args{max};
	    my $error=$args{error};
		my ($fa,$fb);
		for my $x (0..$len) {
			print "\nLearning index $x...\n" if($AI::NeuralNet::BackProp::DEBUG); #, DOW index $data->[$x*2+1]->[0]\n";
			my $str =  $net->learn( $data->[$x*2],			# The list of data to input to the net
					  		  		$data->[$x*2+1], 		# The output desired
					    			inc=>$inc,				# The starting learning gradient
					    			max=>$max,				# The maximum num of loops allowed
					    			error=>$error);			# The maximum (%) error allowed
			print $str if($AI::NeuralNet::BackProp::DEBUG); 
		}
			
		
		return p($data->[1]->[0],$net->run($data->[0])->[0]);
	}
	
	# This sub will take an array ref of a data set, which it expects in this format:
	#   my @data_set = (	[ ...inputs... ], [ ...outputs ... ],
	#				   				   ... rows ...
	#				   );
	#
	# This wil sub returns the percentage of 'forgetfullness' when the net learns all the
	# data in the set in RANDOM order. Usage:
	#
	#	 learn_set_rand(\@data,[ options ]);
	#
	# Options are options in hash form. They can be of any form that $net->learn takes.
	#
	# It returns a percentage string.
	#
	sub learn_set_rand {
		#my $net=shift if(substr($_[0],0,4) eq 'AI::'); 
		my $data=shift;
		my %args = @_;
		my $len=$#{$data}/2-1;
		my $inc=$args{inc};
		my $max=$args{max};
	    my $error=$args{error};
		my ($fa,$fb);
		my @learned;
		while(1) {
			_GET_X:
			my $x=$net->intr(rand()*$len);
			goto _GET_X if($learned[$x]);
			$learned[$x]=1;
			print "\nLearning index $x...\n" if($AI::NeuralNet::BackProp::DEBUG); #, DOW index $data->[$x*2+1]->[0]\n";
			my $str =  $net->learn( $data->[$x*2],			# The list of data to input to the net
					  		  		$data->[$x*2+1], 		# The output desired
					    			inc=>$inc,				# The starting learning gradient
					    			max=>$max,				# The maximum num of loops allowed
					    			error=>$error);			# The maximum (%) error allowed
			print $str if($AI::NeuralNet::BackProp::DEBUG); 
		}
			
		
		return p($data->[1]->[0],$net->run($data->[0])->[0]);
	}

	# Returns $fa as a percentage of $fb
	sub p {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my ($fa,$fb)=(shift,shift);
		sprintf("%.3f",((($fb-$fa)*-1)/$fa)*100);
	}
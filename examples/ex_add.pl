=begin
    
    File:	examples/ex_add.pl
	Author: Josiah Bryan, <jdb@wcoil.com>
	Desc: 

		This demonstrates the ability of a neural net to generalize and predict what the correct
		result is for inputs that it has never seen before.
		
		This teaches a network to add 7 sets of numbers, then it asks the user for two numbers to
		add and it displays the results of the user's input.

=cut

	use AI::NeuralNet::BackProp;
	
	my $addition = new AI::NeuralNet::BackProp(2,2,1);
	
	if(!$addition->load('add.dat')) {
		$addition->learn_set([	
			[ 1,   1   ], [ 2    ] ,
			[ 1,   2   ], [ 3    ],
			[ 2,   2   ], [ 4    ],
			[ 20,  20  ], [ 40   ],
			[ 100, 100 ], [ 200  ],
			[ 150, 150 ], [ 300  ],
			[ 500, 500 ], [ 1000 ],
		]);
		$addition->save('add.dat');
	}

	print "Enter first number to add  : "; chomp(my $a = <>);
	print "Enter second number to add : "; chomp(my $b = <>);
	print "Result: ",$addition->run([$a,$b])->[0],"\n";
	
	
#!/usr/bin/perl	

# $Id: BackProp.pm,v 0.77 2000/08/12 01:05:27 josiah Exp $
#
# Copyright (c) 2000  Josiah Bryan  USA
#
# See AUTHOR section in pod text below for usage and distribution rights.   
# See UPDATES section in pod text below for info on what has changed in this release.
#

BEGIN {
	$AI::NeuralNet::BackProp::VERSION = "0.77";
}

#
# name:   AI::NeuralNet::BackProp
#
# author: Josiah Bryan 
# date:   Saturday August 12 2000
# desc:   A simple back-propagation, feed-foward neural network with
#		  learning implemented via a generalization of Dobbs rule and
#		  several principals of Hoppfield networks. 
# online: http://www.josiah.countystart.com/modules/AI/cgi-bin/rec.pl
#

package AI::NeuralNet::BackProp::neuron;
	
	use strict;
	
	# Dummy constructor
    sub new {
    	bless {}, shift
	}	
	
	# Rounds floats to ints
	sub intr  {int(sprintf("%.0f",shift))}
	
	# Receives input from other neurons. They must
	# be registered as a synapse of this neuron to effectively
	# input.
	sub input {
		my $self 	 =	shift;
		my $sid		 =	shift;
		my $value	 =	shift;
		
		# We simply weight the value sent by the neuron. The neuron identifies itself to us
		# using the code we gave it when it registered itself with us. The code is in $sid, 
		# (synapse ID) and we use that to track the weight of the connection.
		# This line simply multiplies the value by its weight and gets the integer from it.
		$self->{SYNAPSES}->{LIST}->[$sid]->{VALUE}	=	intr($value	*	$self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT});
		$self->{SYNAPSES}->{LIST}->[$sid]->{FIRED}	=	1;                                 
		$self->{SYNAPSES}->{LIST}->[$sid]->{INPUT}	=	$value;
		
		# Debugger
		AI::NeuralNet::BackProp::out1("\nRecieved input of $value, weighted to $self->{SYNAPSES}->{LIST}->[$sid]->{VALUE}, synapse weight is $self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT} (sid is $sid for $self).\n");
		AI::NeuralNet::BackProp::out1((($self->input_complete())?"All synapses have fired":"Not all synapses have fired"));
		AI::NeuralNet::BackProp::out1(" for $self.\n");
		
		# Check and see if all synapses have fired that are connected to this one.
		# If the have, then generate the output value for this synapse.
		$self->output() if($self->input_complete());
	}
	
	# Loops thru and outputs to every neuron that this
	# neuron is registered as synapse of.
	sub output {
		my $self	=	shift;
		my $size	=	$self->{OUTPUTS}->{SIZE} || 0;
		my $value	=	$self->get_output();
		for (0..$size-1) {
			AI::NeuralNet::BackProp::out1("Outputing to $self->{OUTPUTS}->{LIST}->[$_]->{PKG}, index $_, a value of $value with ID $self->{OUTPUTS}->{LIST}->[$_]->{ID}.\n");
			$self->{OUTPUTS}->{LIST}->[$_]->{PKG}->input($self->{OUTPUTS}->{LIST}->[$_]->{ID},$value);
		}
	}
	
	# Used internally by output().
	sub get_output {
		my $self		=	shift;
		my $size		=	$self->{SYNAPSES}->{SIZE} || 0;
		my $value		=	0;
		my $state		= 	0;
		my $switch		=	0;
		my (@map,@weight);
	
	    # We loop through all the syanpses connected to this one and add the weighted
	    # valyes together, saving in a debugging list.
		for (0..$size-1) {
			$value	+=	$self->{SYNAPSES}->{LIST}->[$_]->{VALUE};
			$self->{SYNAPSES}->{LIST}->[$_]->{FIRED} = 0;
			
			$map[$_]=$self->{SYNAPSES}->{LIST}->[$_]->{VALUE};
			$weight[$_]=$self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT};
		}
		                                              
		# Debugger
		AI::NeuralNet::BackProp::join_cols(\@map,5) if(($AI::NeuralNet::BackProp::DEBUG eq 3) || ($AI::NeuralNet::BackProp::DEBUG eq 2));
		AI::NeuralNet::BackProp::out2("Weights: ".join(" ",@weight)."\n");
		
		# Simply average the values and get the integer of the average.
		$state	=	intr($value/$size);
		
		# Debugger
		AI::NeuralNet::BackProp::out1("From get_output, value is $value, so state is $state.\n");
		
		# Possible future exapnsion for self excitation. Not currently used.
		$self->{LAST_VALUE}	=	$value;
		
		# Here we add a small ammount of randomness to the network.
		# This is to keep the network from getting stuck on a 0 value internally.
		return ($state + (rand()*$self->{ramdom}));
	}
	
	# Used by input() to check if all registered synapses have fired.
	sub input_complete {
		my $self		=	shift;
		my $size		=	$self->{SYNAPSES}->{SIZE} || 0;
		my $retvalue	=	1;
		
		# Very simple loop. Doesn't need explaning.
		for (0..$size-1) {
			$retvalue = 0 if(!$self->{SYNAPSES}->{LIST}->[$_]->{FIRED});
		}
		return $retvalue;
	}
	
	# Used to recursively adjust the weights of synapse input channeles
	# to give a desired value. Designed to be called via AI::NeuralNet::BackProp::NeuralNetwork::learn().
	sub weight	{                
		my $self		=	shift;
		my $ammount		=	shift;
		my $what		=	shift;
		my $size		=	$self->{SYNAPSES}->{SIZE} || 0;
		my $value;
		AI::NeuralNet::BackProp::out1("Weight: ammount is $ammount, what is $what with size at $size.\n");
		
		# Now this sub is the main cog in the learning wheel. It is called recursively on 
		# each neuron that has been bad (given incorrect output.)
		for (0..$size-1) {
			$value		=	$self->{SYNAPSES}->{LIST}->[$_]->{VALUE};
			#$ammount	*=  $self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT};
			
			# Here we just decide what to do with the value.
			# If its the same, then somebody slipped up in calling us, so do nithing.
			if($value eq $what) {
				next;
			
#### I included this formula from Steve Purikis on adjusting the weights for your exermentation.
#	 It seems to work fine, but the neurons do not seem to be able to hold as many multiple 
#	 patterns as using the two below else{} statements. You can experiment with it if you want, 
#    by simply removing the comment marks and commenting the two else{} blocks, below.
#
#			# Adjust weight based on formula translated to Perl by Steve Purkis as found
#			# in his AI::Perceptron module.
#			} else {
#				my $delta	=	$ammount * ($what - $value) * $self->{SYNAPSES}->{LIST}->[$_]->{INPUT};
#				$self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT}  +=  $delta;
#				$self->{SYNAPSES}->{LIST}->[$_]->{PKG}->weight($ammount,$what);
#				AI::NeuralNet::BackProp::out1("\$value:$value,\$what:$what,\$delta:$delta,\$ammount:$ammount,input:$self->{SYNAPSES}->{LIST}->[$_]->{INPUT},\$_:$_,weight:$self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT},synapse:$self).\n");
#			}
			

			# Otherwise, we need to make this connection a bit heavier because the value is
			# lower than the desired value. So, we increase the weight of this connection and
			# then let all connected synapses adjust weight accordinly as well.
			} elsif($value < $what) {                                     
				my $m = $ammount * $self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT};
				$self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT}  +=  $m;
			    $self->{SYNAPSES}->{LIST}->[$_]->{PKG}->weight($m,$what);
			    AI::NeuralNet::BackProp::out1("$value is less than $what (\$_ is $_, weight is $self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT}, synapse is $self).\n");
			
			# Ditto as above block, except we take some weight off.
			} else {	
				my $m = $ammount * $self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT};
				$self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT}  -=  $m;
				$self->{SYNAPSES}->{LIST}->[$_]->{PKG}->weight($m,$what);
				AI::NeuralNet::BackProp::out1("$value is greater than $what (\$_ is $_, weight is $self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT}, synapse is $self).\n");
			}

		}
	}
	
	# Registers some neuron as a synapse of this neuron.           
	# This is called exclusively by connect(), except for
	# in initalize_group() to connect the _map() package.
	sub register_synapse {
		my $self	=	shift;
		my $synapse	=	shift;
		my $sid		=	$self->{SYNAPSES}->{SIZE} || 0;
		$self->{SYNAPSES}->{LIST}->[$sid]->{PKG}		=	$synapse;
		$self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT}		=	1.00		if(!$self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT});
		$self->{SYNAPSES}->{LIST}->[$sid]->{FIRED}		=	0;       
		AI::NeuralNet::BackProp::out1("$self: Registering sid $sid with weight $self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT}, package $self->{SYNAPSES}->{LIST}->[$sid]->{PKG}.\n");
		$self->{SYNAPSES}->{SIZE} = ++$sid;
		return ($sid-1);
	}
	
	# Called via AI::NeuralNet::BackProp::NeuralNetwork::initialize_group() to 
	# form the neuron grids.
	# This just registers another synapes as a synapse to output to from this one, and
	# then we ask that synapse to let us register as an input connection and we
	# save the sid that the ouput synapse returns.
	sub connect {
		my $self	=	shift;
		my $to		=	shift;
		my $oid		=	$self->{OUTPUTS}->{SIZE} || 0;
		AI::NeuralNet::BackProp::out1("Connecting $self to $to at $oid...\n");
		$self->{OUTPUTS}->{LIST}->[$oid]->{PKG}	=	$to;
 		$self->{OUTPUTS}->{LIST}->[$oid]->{ID}	=	$to->register_synapse($self);
		$self->{OUTPUTS}->{SIZE} = ++$oid;
		return $self->{OUTPUTS}->{LIST}->[$oid]->{ID};
	}
1;
			 
package AI::NeuralNet::BackProp;
	
	use Benchmark;          
	require Exporter;
    
	use strict;
	
#### This is commented out because the load() and save() routines right now
#### don't work. If you want to try to get load() and store() working on your own, 
#### uncomment this next line where it says "use Storable;" and uncomment the 
#### "use Storable;" under the package declaration for AI::NeuralNet::BackProp::File.

	use Storable qw(freeze thaw);


	# Returns the number of elements in an array ref, undef on error
	sub _FETCHSIZE {
		my $a=$_[0];
		my ($b,$x);
		return undef if(substr($a,0,5) ne "ARRAY");
		foreach $b (@{$a}) { $x++ };
		return $x;
	}

	# Debugging subs
	$AI::NeuralNet::BackProp::DEBUG  = 0;
	sub whowasi { (caller(1))[3] . '()' }
	sub debug { shift; $AI::NeuralNet::BackProp::DEBUG = shift || 0; } 
	sub out1  { print  shift() if ($AI::NeuralNet::BackProp::DEBUG eq 1) }
	sub out2  { print  shift() if (($AI::NeuralNet::BackProp::DEBUG eq 2) || ($AI::NeuralNet::BackProp::DEBUG eq 1)) }
	sub out3  { print  shift() if ($AI::NeuralNet::BackProp::DEBUG) }
	sub out4  { print  shift() if ($AI::NeuralNet::BackProp::DEBUG eq 4) }
	
	# Rounds a floating-point to an integer with int() and sprintf()
	sub intr  {shift if(substr($_[0],0,4) eq 'AI::'); int(sprintf("%.0f",shift))}

	# Used to format array ref into columns
	# Usage: 
	#	join_cols(\@array,$row_length_in_elements,$high_state_character,$low_state_character);
	# Can also be called as method of your neural net.
	# If $high_state_character is null, prints actual numerical values of each element.
	sub join_cols {
		no strict 'refs';
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $map		=	shift;
		my $break   =	shift;
		my $a		=	shift;
		my $b		=	shift;
		my $x;
		foreach my $el (@{$map}) { 
			my $str = ((int($el))?$a:$b);
			$str=$el."\0" if(!$a);
			print $str;
			$x++;
			if($x>$break-1) {
				print "\n";
				$x=0;
			}
		}
		print "\n";
	}
	
	# Returns percentage difference between all elements of two
	# array refs of exact same length (in elements).
	# Now calculates actual difference in numerical value.
	sub pdiff {
		no strict 'refs';
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $a1	=	shift;
		my $a2	=	shift;
		my $a1s	=	AI::NeuralNet::BackProp::_FETCHSIZE($a1);
		my $a2s	=	AI::NeuralNet::BackProp::_FETCHSIZE($a2);
		my ($a,$b,$diff,$t);
		$diff=0;
		#return undef if($a1s ne $a2s);	# must be same length
		for my $x (0..$a1s) {
			$a = $a1->[$x];
			$b = $a2->[$x];
			if($a!=$b) {
				if($a<$b){$t=$a;$a=$b;$b=$t;}
				$a=1 if($a eq 0);
				$diff+=(($a-$b)/$a)*100;
			}
		}
		$a1s = 1 if(!$a1s);
		return sprintf("%.10f",($diff/$a1s));
	}
	
	# Returns $fa as a percentage of $fb
	sub p {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my ($fa,$fb)=(shift,shift);
		sprintf("%.3f",((($fb-$fa)*((($fb-$fa)<0)?-1:1))/$fa)*100);
	}
	
	# This sub will take an array ref of a data set, which it expects in this format:
	#   my @data_set = (	[ ...inputs... ], [ ...outputs ... ],
	#				   				   ... rows ...
	#				   );
	#
	# This wil sub returns the percentage of 'forgetfullness' when the net learns all the
	# data in the set in order. Usage:
	#
	#	 learn_set(\@data,[ options ]);
	#
	# Options are options in hash form. They can be of any form that $net->learn takes.
	#
	# It returns a percentage string.
	#
	sub learn_set {
		my $net=shift if(substr($_[0],0,4) eq 'AI::'); 
		my $data=shift;
		my %args = @_;
		my $len=$#{$data}/2-1;
		my $inc=$args{inc};
		my $max=$args{max};
	    my $error=$args{error};
	    my $p=$args{p} || 1;
	    my ($fa,$fb);
		for my $x (0..$len) {
			print "\nLearning index $x...\n" if($AI::NeuralNet::BackProp::DEBUG);
			my $str =  $net->learn( $data->[$x*2],			# The list of data to input to the net
					  		  		$data->[$x*2+1], 		# The output desired
					    			inc=>$inc,				# The starting learning gradient
					    			max=>$max,				# The maximum num of loops allowed
					    			error=>$error);			# The maximum (%) error allowed
			print $str if($AI::NeuralNet::BackProp::DEBUG); 
		}
			
		
		my $res;
		$p=0;
		if ($p) {
			$res=pdiff($data->[1]->[0],$net->run($data->[0]));
		} else {
			$res=$data->[1]->[0]-$net->run($data->[0])->[0];
		}
		return $res;
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
	# It returns a true value.
	#
	sub learn_set_rand {
		my $net=shift if(substr($_[0],0,4) eq 'AI::'); 
		my $data=shift;
		my %args = @_;
		my $len=$#{$data}/2-1;
		my $inc=$args{inc};
		my $max=$args{max};
	    my $error=$args{error};
	    my @learned;
		while(1) {
			_GET_X:
			my $x=$net->intr(rand()*$len);
			goto _GET_X if($learned[$x]);
			$learned[$x]=1;
			print "\nLearning index $x...\n" if($AI::NeuralNet::BackProp::DEBUG); 
			my $str =  $net->learn( $data->[$x*2],			# The list of data to input to the net
					  		  		$data->[$x*2+1], 		# The output desired
					    			inc=>$inc,				# The starting learning gradient
					    			max=>$max,				# The maximum num of loops allowed
					    			error=>$error);			# The maximum (%) error allowed
			print $str if($AI::NeuralNet::BackProp::DEBUG); 
		}
			
		
		return 1; 
	}

	# Returns the index of the element in array REF passed with the highest comparative value
	sub high {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $ref1	=	shift;
		
		my ($el,$len,$tmp);
		foreach $el (@{$ref1}) {
			$len++;
		}
		$tmp=0;
		for my $x (0..$len-1) {
			$tmp = $x if((@{$ref1})[$x] > (@{$ref1})[$tmp]);
		}
		return $tmp;
	}
	
	# Returns the index of the element in array REF passed with the lowest comparative value
	sub low {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $ref1	=	shift;
		
		my ($el,$len,$tmp);
		foreach $el (@{$ref1}) {
			$len++;
		}
		$tmp=0;
		for my $x (0..$len-1) {
			$tmp = $x if((@{$ref1})[$x] < (@{$ref1})[$tmp]);
		}
		return $tmp;
	}  
	
	# Returns a pcx object
	sub load_pcx {
		my $self	=	shift;
		return AI::NeuralNet::BackProp::PCX->new($self,shift);
	}	
	
	# Crunch a string of words into a map
	sub crunch {
		my $self	=	shift;
		my (@map,$ic);
		my @ws 		=	split(/[\s\t]/,shift);
		for my $a (0..$#ws) {
			$ic=$self->crunched($ws[$a]);
			if(!defined $ic) {
				$self->{_CRUNCHED}->{LIST}->[$self->{_CRUNCHED}->{_LENGTH}++]=$ws[$a];
				@map[$a]=$self->{_CRUNCHED}->{_LENGTH};
			} else {
				@map[$a]=$ic;
            }
		}
		return \@map;
	}
	
	# Finds if a word has been crunched.
	# Returns undef on failure, word index for success.
	sub crunched {
		my $self	=	shift;
		for my $a (0..$self->{_CRUNCHED}->{_LENGTH}-1) {
			return $a+1 if($self->{_CRUNCHED}->{LIST}->[$a] eq $_[0]);
		}
		return undef;
	}
	
	# Uncrunches a map (array ref) into an array of words (not an array ref) and returns array
	sub uncrunch {
		my $self	=	shift;
		my $map = shift;
		my ($c,$el,$x);
		foreach $el (@{$map}) {
			$c .= $self->{_CRUNCHED}->{LIST}->[$el-1].' ';
		}
		return $c;
	}
	
	# Sets/gets randomness facter in the network. Setting a value of 0 disables random factors.
	sub random {
		my $self	=	shift;
		my $rand	=	shift;
		return $self->{random}	if(!(defined $rand));
		$self->{random}	=	$rand;
	}
	
	# Sets/gets column width for printing lists in debug modes 1,3, and 4.
	sub col_width {
		my $self	=	shift;
		my $width	=	shift;
		return $self->{col_width}	if(!$width);
		$self->{col_width}	=	$width;
	}
	
	# Initialzes the base for a new neural network.
	# It is recomended that you call learn() before run()ing a pattern.
	# See documentation above for usage.
	sub new {
    	no strict;
    	my $type	=	shift;
		my %self	=	{};
		
		my $layers	=	shift || 2;
		my $size	=	shift || 1;
		my $out		=	shift || $size;
		
		# Error checking
		return undef if($out>$size);
		
		# Initalize amount of randomness allowed
		$self->{random} = 0.001;
		
		$self->{GROUPS}->{SIZE}			=	1;
		$self->{GROUPS}->{CURRENT}  	=	0;
		
		# Initalize groups incase somebody forgets to call learn()
		$self->{GROUPS}->{DATA}->[0]->{MAP}	= ();
		$self->{GROUPS}->{DATA}->[0]->{RES}	= ();
		
		AI::NeuralNet::BackProp::out2 "Creating $size neurons in each layer for $layers layer(s)...\n";
		
		# When this is called, they tell us howmany layers and neurons in each layer.
		# But really what we store is a long line of neurons that are only divided in theory
		# when connecting the outputs and inputs.
		my $div = $size;
		my $size = $layers * $size;
		
		AI::NeuralNet::BackProp::out2 "Blessing network into package...\n";
		
		bless $self, $type;
		
		AI::NeuralNet::BackProp::out2 "Creating RUN and MAP systems for network...\n";
		
		# Create a new runner and mapper for the network.
		$self->{RUN} = new AI::NeuralNet::BackProp::_run($self);
		$self->{MAP} = new AI::NeuralNet::BackProp::_map($self);
		
		$self->{SIZE}	=	$size;
		$self->{DIV}	=	$div;
		$self->{OUT}	=	$out;
		$self->{col_width}= 5;
		
		$self->initialize_group();	# Called to prevent a "cant call method X on undefined value" 
									# incase we forget to "learn()" a pattern.
		
		return $self;
	}	

	# Save entire network state to disk.
	sub save {
		my $self	=	shift;
		my $file	=	shift;
		my $size	=	$self->{SIZE};
		my $div		=	$self->{DIV};
		my $out		=	$self->{OUT};

	    my $db		=	AI::NeuralNet::BackProp::File->new($file);
	    
	    $db->select("root");
	    $db->set("size",		$size);
	    $db->set("div",			$div);
	    $db->set("out",			$out);
	    $db->set("rand",		$self->{random});
		$db->set("crunch",		$self->{_CRUNCHED}->{_LENGTH});
		
		for my $a (0..$self->{_CRUNCHED}->{_LENGTH}-1) {
			$db->set("c$a", $self->{_CRUNCHED}->{LIST}->[$a]);
		}
		
		my $w;
		for my $a (0..$self->{SIZE}-1) {
			$w="";
			for my $b (0..$self->{DIV}-1) {
				$w .= "$self->{NET}->[0]->[$a]->{SYNAPSES}->{LIST}->[$b]->{WEIGHT},";
			}
			chop($w);
			$db->set("n$a",$w);
		}
	
	    $db->writeout();
	    
	    undef $db;
	    
	    return $self;
	}

	# Load entire network state from disk.
	sub load {
		my $self	=	shift;
		my $file	=	shift;
	    
	    return undef if(!(-f $file));
	    
	    my $db		=	AI::NeuralNet::BackProp::File->new($file);
	    
	    $db->select("root");
	    $self->{SIZE} 		= $db->get("size");
	    $self->{DIV} 		= $db->get("div");
	    $self->{OUT} 		= $db->get("out");
	    $self->{random}		= $db->get("rand");

	   	$self->{_CRUNCHED}->{_LENGTH}	=	$db->get("crunch");
		
		for my $a (0..$self->{_CRUNCHED}->{_LENGTH}-1) {
			$self->{_CRUNCHED}->{LIST}->[$a] = $db->get("c$a"); 
		}
		
		$self->initialize_group();
	    
		my ($w,@l);
		for my $a (0..$self->{SIZE}-1) {
			$w=$db->get("n$a");
			@l=split(/\,/,$w);
			for my $b (0..$self->{DIV}-1) {
				$self->{NET}->[0]->[$a]->{SYNAPSES}->{LIST}->[$b]->{WEIGHT}=$l[$b];
			}
		}
	
	    undef $db;
	    
	    return $self;
	}

	# Dumps the complete weight matrix of the network to STDIO
	sub show() {
		my $self	=	shift;
		for my $a (0..$self->{SIZE}-1) {
			print "Neuron $a: ";
			for my $b (0..$self->{DIV}-1) {
				print $self->{NET}->[0]->[$a]->{SYNAPSES}->{LIST}->[$b]->{WEIGHT},"\t";
			}
			print "\n";
		}
	}
	
	# Used internally by new() and learn().
	# This is the sub block that actually creats
	# the connections between the synapse chains and
	# also connects the run packages and the map packages
	# to the appropiate ends of the neuron grids.
	sub initialize_group() {
		my $self	=	shift;
		my $size	=	$self->{SIZE};
		my $div		=	$self->{DIV};
		my $out		=	$self->{OUT};
		my $x		=	0; 
		my $y		=	0;
		
		AI::NeuralNet::BackProp::out2 "Initializing group $self->{GROUPS}->{CURRENT}...\n";
		
		# Reset map and run synapse counters.
		$self->{RUN}->{REGISTRATION} = $self->{MAP}->{REGISTRATION} = 0;
		
		AI::NeuralNet::BackProp::out2 "There will be $size neurons in this network group, with a divison value of $div.\n";
		
		# Create initial neuron packages in one long array for the entire group
		for($y=0; $y<$size; $y++) {
			#print "Initalizing neuron $y...     \r";
			$self->{NET}->[$self->{GROUPS}->{CURRENT}]->[$y]=new AI::NeuralNet::BackProp::neuron();
		}
		
		AI::NeuralNet::BackProp::out2 "Creating synapse grid...\n";
		
		my $z  = 0;    
		my $aa = 0;
		my ($n0,$n1,$n2);
		
		# Outer loop loops over every neuron in group, incrementing by the number
		# of neurons supposed to be in each layer
		
		for($y=0; $y<$size; $y+=$div) {
			if($y+$div>=$size) {
				last;
			}
			
			# Inner loop connects every neuron in this 'layer' to one input of every neuron in
			# the next 'layer'. Remeber, layers only exist in terms of where the connections
			# are divided. For example, if a person requested 2 layers and 3 neurons per layer,
			# then there would be 6 neurons in the {NET}->[] list, and $div would be set to
			# 3. So we would loop over and every 3 neurons we would connect each of those 3 
			# neurons to one input of every neuron in the next set of 3 neurons. Of course, this
			# is an example. 3 and 2 are set by the new() constructor.
			
			for ($z=0; $z<$div; $z++) {
				for ($aa=0; $aa<$div; $aa++) {      
					#print "Layer: $y, Neuron: $z, Synapse: $aa...    \r";
					$self->{NET}->[$self->{GROUPS}->{CURRENT}]->[$y+$z]->connect($self->{NET}->[$self->{GROUPS}->{CURRENT}]->[$y+$div+$aa]);
				}
				AI::NeuralNet::BackProp::out1 "\n";
			}
			AI::NeuralNet::BackProp::out1 "\n";             
		}
		
		AI::NeuralNet::BackProp::out2 "\nMapping I (_run package) connections to network...\n";
		
		# These next two loops connect the _run and _map packages (the IO interface) to 
		# the start and end 'layers', respectively. These are how we insert data into
		# the network and how we get data from the network. The _run and _map packages 
		# are connected to the neurons so that the neurons think that the IO packages are
		# just another neuron, sending data on. But the IO packs. are special packages designed
		# with the same methods as neurons, just meant for specific IO purposes. You will
		# never need to call any of the IO packs. directly. Instead, they are called whenever
		# you use the run(), map(), or learn() methods of your network.
        
        for($y=0; $y<$div; $y++) {
			$self->{_tmp_synapse} = $y;
			$self->{NET}->[$self->{GROUPS}->{CURRENT}]->[$y]->register_synapse($self->{RUN});
			$self->{NET}->[$self->{GROUPS}->{CURRENT}]->[$y]->connect($self->{RUN});
		}
		
		AI::NeuralNet::BackProp::out2 "Mapping O (_map package) connections to network...\n\n";
		
		for($y=$size-$div; $y<$size; $y++) {
			$self->{_tmp_synapse} = $y;
			$self->{NET}->[$self->{GROUPS}->{CURRENT}]->[$y]->connect($self->{MAP});
		}
		
		# And the group is done! 
	}
	

	# When called with an array refrence to a pattern, returns a refrence
	# to an array associated with that pattern. See usage in documentation.
	#
	# This compares the input map with the learn()ed input map of each group, and the 
	# group who's comparission comes out as the lowest percentage difference is 
	# then used to run the input map. 
	#
	sub run {
		my $self	 =	  shift;
		my $map		 =	  shift;
		my $gsize	 =	  $self->{GROUPS}->{SIZE};
		my ($t0,$t1,$td);
		$t0 		 =	new Benchmark;

		my $topi = 0;
		
		$self->{GROUPS}->{CURRENT}=$self->{LAST_GROUP}=$topi;
		$self->{RUN}->run($map);
		$t1 = new Benchmark;
	    $td = timediff($t1, $t0);
        $self->{LAST_TIME}="Input map compared to $gsize groups and came up with final result in ".timestr($td,'noc','5.3f').".\n";
        return $self->map();
	}


	# Disabled, included so we dont have code errors
	#
	sub pattern { 0 }
	    
	# Returns benchmark and loop's ran or learned
	# for last run(), or learn()
	# operation preformed.
	#
	sub benchmarked {
		my $self	=	shift;
		return $self->{LAST_TIME};
	}
	    
	# Used to retrieve map from last internal run operation.
	# This is used mainly by learn() and run(), as when you
	# call run(), it returns the 'best' match. This just returns
	# the _last_ result from the last neuron group ran.
	sub map {
		my $self	 =	  shift;
		$self->{MAP}->map();
	}
	
	# Used internally by learn()
	# This just simply stores the desired result map 
	# and the learned map in a new group list element
	# which is a Hash of Arrays in a Hash of Hashes.. :-)
	# Returns the index of the new group list element.
	sub add_group {
		my $self	=	shift;
		my $map		=	shift;
		my $res		=	shift;
		my $size	=	$self->{GROUPS}->{SIZE};
		$self->{GROUPS}->{DATA}->[$size]->{RES}	=	$res;
		$self->{GROUPS}->{DATA}->[$size]->{MAP}	=	$map;
		$self->{GROUPS}->{SIZE}	=	++$size;
		return $size-1;
	}
	
			
	# Forces network to learn pattern passed and give desired
	# results. See usage in POD.
	sub learn {
		my $self	=	shift;
		my $omap	=	shift;
		my $res		=	shift;
		my %args    =   @_;
		my $inc 	=	$args{inc} || 0.20;
		my $max     =   $args{max} || 1024;
		my $error   = 	$args{error}>-1 ? $args{error} : -1;
  		my $div		=	$self->{DIV};
		my $size	=	$self->{SIZE};
		my $out		=	$self->{OUT};
		my $divide  =	AI::NeuralNet::BackProp->intr($size/$out);
		my ($a,$b,$y,$flag,$map,$loop,$diff,$pattern,$value,$v1,$v2);
		my ($t0,$t1,$td);
		my ($it0,$it1,$itd);
		no strict 'refs';
		
		$self->{LAST_GROUP} = $self->{GROUPS}->{CURRENT} = 0;
		
		# Debug
		AI::NeuralNet::BackProp::out1 "Num output neurons: $out, Input neurons: $size, Division: $divide\n";
		
		# Start benchmark timer.
		$t0 	=	new Benchmark;
        $flag 	=	0; 
		$loop	=	0;   
		my $ldiff	=	0;
		my $dinc	=	0.0001;
		my $cdiff	=	0;
		$diff		=	100;
		$error 		= 	($error>-1)?$error:-1;
		
		# $flag only goes high when all neurons in output map compare exactly with
		# desired result map.
		#	
		while(!$flag && ($max ? $loop<$max : 1) && ($error>-1 ? $diff>$error : 1)) {
			$it0 	=	new Benchmark;
			
			# Debugger
			AI::NeuralNet::BackProp::out1 "Current group: ".$self->{GROUPS}->{CURRENT}."\n";
			
			# If the run package returns a undefined value, it usually means that
			# you tried to learn a map that contained a 0 value. See comments in _run
			# package for why this is bad.
			return undef if(!$self->{RUN}->run($omap));
			
			# Retrieve last mapping  and initialize a few variables.
			$map	=	$self->map();
			$y		=	$size-$div;
			$flag	=	1;
			
			# Compare the result map we just ran with the desired result map.
			$diff 	=	pdiff($map,$res);
			
			# We de-increment the loop ammount to prevent infinite learning loops.
			# In old versions of this module, if you used too high of an initial input
			# $inc, then the network would keep jumping back and forth over your desired 
			# results because the increment was too high...it would try to push close to
			# the desired result, only to fly over the other edge too far, therby trying
			# to come back, over shooting again. 
			# This simply adjusts the learning gradient proportionally to the ammount of
			# convergance left as the difference decreases.
           	$inc   -= ($dinc*$diff);
			$inc   = 0.0000000001 if($inc < 0.0000000001);
			
			# This prevents it from seeming to get stuck in one location
			# by attempting to boost the values out of the hole they seem to be in.
			if($diff eq $ldiff) {
				$cdiff++;
				$inc += ($dinc*$diff)+($dinc*$cdiff*10);
			} else {
				$cdiff=0;
			}
			
			# This catches a max error argument and handles it
			if(!($error>-1 ? $diff>$error : 1)) {
				$flag=1;
				last;
			}
			
			$ldiff = $diff;
			
			# Debugging
			AI::NeuralNet::BackProp::out4 "Difference: $diff\%\t Increment: $inc\tMax Error: $error\%\n";
			AI::NeuralNet::BackProp::out1 "Current group: ".$self->{GROUPS}->{CURRENT}."\n";
			AI::NeuralNet::BackProp::out1 "\n\nMapping results from $map:\n";
			
			# This loop compares each element of the output map with the desired result map.
			# If they don't match exactly, we call weight() on the offending output neuron 
			# and tell it what it should be aiming for, and then the offending neuron will
			# try to adjust the weights of its synapses to get closer to the desired output.
			# See comments in the weight() method of AI::NeuralNet::BackProp for how this works.
			
			for(0..$div-1) {
				$a = ((@{$map})[$_]);
				$b = ((@{$res})[$_]);
				
				AI::NeuralNet::BackProp::out1 "\nmap[$_] is $a\n";
				AI::NeuralNet::BackProp::out1 "res[$_] is $b\n";
				
				if($a==$b) {
					AI::NeuralNet::BackProp::out1 "Rewarding $self->{NET}->[$self->{GROUPS}->{CURRENT}]->[$y] at $y ($_ with $a) by $inc.\n";
				} else {
					AI::NeuralNet::BackProp::out1 "Punishing $self->{NET}->[$self->{GROUPS}->{CURRENT}]->[$y] at $y ($_ with $a) by $inc.\n";
					$self->{NET}->[$self->{GROUPS}->{CURRENT}]->[$y]->weight($inc,$b);
					$flag	=	0;
				}
				$y++;
			}

# A different type of learning loop that seems to take a very long time and very 
# forgetful, so I have disabled it. I include it here for any of you that are brave 
# of heart and feel dareing. 			
if (0 eq 1) {
			for my $i (0..$out-1) {
				$value=0;
				$v1 = $map->[$i];
				$v2 = $res->[$i];
				
				AI::NeuralNet::BackProp::out1 "\nmap[$i] is $v1\n";
				AI::NeuralNet::BackProp::out1 "res[$i] is $v2\n";
					
				for my $a (0..$divide-1) {
					$value += $self->{OUTPUT}->[($i*$divide)+$a]->{VALUE};
					
					if($v1==$v2) {
						AI::NeuralNet::BackProp::out1 "Rewarding $self->{NET}->[$self->{GROUPS}->{CURRENT}]->[($i*$divide)+$a] at ",(($i*$divide)+$a)," ($i with $v1) by $inc.\n";
					} else {
						AI::NeuralNet::BackProp::out1 "Punishing $self->{NET}->[$self->{GROUPS}->{CURRENT}]->[($i*$divide)+$a] at ",(($i*$divide)+$a)," ($i with $v1) by $inc.\n";
						$self->{NET}->[$self->{GROUPS}->{CURRENT}]->[($i*$divide)+$a]->weight($inc,$v2);
						$flag	=	0;
					}
				}
			}
}
			
			# This counter is just used in the benchmarking operations.
			$loop++;
			
			AI::NeuralNet::BackProp::out1 "\n\n";
			
			# Benchmark this loop.
			$it1 = new Benchmark;
	    	$itd = timediff($it1, $it0);
			AI::NeuralNet::BackProp::out4 "Learning itetration $loop complete, timed at".timestr($itd,'noc','5.3f')."\n";
		
			# Map the results from this loop.
			AI::NeuralNet::BackProp::out2 "Map: \n";
			AI::NeuralNet::BackProp::join_cols($map,$self->{col_width}) if ($AI::NeuralNet::BackProp::DEBUG);
		}
		
		# Compile benchmarking info for entire learn() process and return it, save it, and
		# display it.
		$t1 = new Benchmark;
	    $td = timediff($t1, $t0);
        my $str = "Learning took $loop loops and ".timestr($td,'noc','5.3f');
        AI::NeuralNet::BackProp::out2 $str;
		$self->{LAST_TIME}=$str;
        return $str;
	}		
		
1;

# Internal input class. Not to be used directly.
package AI::NeuralNet::BackProp::_run;
	
	use strict;
	
	# Dummy constructor.
	sub new {
		bless { PARENT => $_[1] }, $_[0]
	}
	
	# This is so we comply with the neuron interface.
	sub weight {}
	sub input  {}
	
	# Again, compliance with neuron interface.
	sub register_synapse {
		my $self	=	shift;		
		my $sid		=	$self->{REGISTRATION} || 0;
		$self->{REGISTRATION}	=	++$sid;
		$self->{RMAP}->{$sid-1}	= 	$self->{PARENT}->{_tmp_synapse};
		return $sid-1;
	}
	
	# Here is the real meat of this package.
	# run() does one thing: It fires values
	# into the first layer of the network.
	sub run {
		my $self	=	shift;
		my $map		=	shift;
		my $x		=	0;
		return undef if(substr($map,0,5) ne "ARRAY");
		foreach my $el (@{$map}) {
			AI::NeuralNet::BackProp::out1 "\n\nGroup ".$self->{PARENT}->{GROUPS}->{CURRENT}.": Fireing $el with sid $x into $self->{PARENT}->{NET}->[$self->{PARENT}->{GROUPS}->{CURRENT}]->[$x] at $x...\n";
			$self->{PARENT}->{NET}->[$self->{PARENT}->{GROUPS}->{CURRENT}]->[$x]->input(0,$el);
			$x++;
		};
		return $x;
	}
	
	
1;

# Internal output class. Not to be used directly.
package AI::NeuralNet::BackProp::_map;
	
	use strict;
	
	# Dummy constructor.
	sub new {
		bless { PARENT => $_[1] }, $_[0]
	}
	
	# Compliance with neuron interface
	sub weight {}
	
	# Compliance with neuron interface
	sub register_synapse {
		my $self	=	shift;		
		my $sid		=	$self->{REGISTRATION} || 0;
		$self->{REGISTRATION}	=	++$sid;
		$self->{RMAP}->{$sid-1} = 	$self->{PARENT}->{_tmp_synapse};
		return $sid-1;
	}
	
	# This acts just like a regular neuron by receiving
	# values from input synapes. Yet, unlike a regularr
	# neuron, it doesnt weight the values, just stores
	# them to be retrieved by a call to map().
	sub input  {
		no strict 'refs';             
		my $self	=	shift;
		my $sid		=	shift;
		my $value	=	shift;
		my $size	=	$self->{PARENT}->{DIV};
		my $flag	=	1;
		$self->{OUTPUT}->[$sid]->{VALUE}	=	$self->{PARENT}->intr($value);
		$self->{OUTPUT}->[$sid]->{FIRED}	=	1;
		
		AI::NeuralNet::BackProp::out1 "Received value $self->{OUTPUT}->[$sid]->{VALUE} and sid $sid, self $self.\n";
	}
	
	# Here we simply collect the value of every neuron connected to this
	# one from the layer below us and return an array ref to the final map..
	sub map {
		my $self	=	shift;
		my $size	=	$self->{PARENT}->{DIV};
		my $out		=	$self->{PARENT}->{OUT};
		my $divide  =	AI::NeuralNet::BackProp->intr($size/$out);
		my @map = ();
		my $value;
		AI::NeuralNet::BackProp::out1 "Num output neurons: $out, Input neurons: $size, Division: $divide\n";
		for(0..$out-1) {
			$value=0;
			for my $a (0..$divide-1) {
				$value += $self->{OUTPUT}->[($_*$divide)+$a]->{VALUE};
				AI::NeuralNet::BackProp::out1 "\$a is $a, index is ".(($_*$divide)+$a).", value is $self->{OUTPUT}->[($_*$divide)+$a]->{VALUE}\n";
			}
			$map[$_]	=	AI::NeuralNet::BackProp->intr($value/$divide);
			AI::NeuralNet::BackProp::out1 "Map position $_ is $map[$_] in @{[\@map]} with self set to $self.\n";
			$self->{OUTPUT}->[$_]->{FIRED}	=	0;
		}
		return \@map;
	}
1;
			      
# load_pcx() wrapper package
package AI::NeuralNet::BackProp::PCX;

	# Called by load_pcx in AI::NeuralNet::BackProp;
	sub new {
		my $type	=	shift;
		my $self	=	{ 
			parent  => $_[0],
			file    => $_[1]
		};
		my (@a,@b)=load_pcx($_[1]);
		$self->{image}=\@a;
		$self->{palette}=\@b;
		bless \%{$self}, $type;
	}

	# Returns a rectangular block defined by an array ref in the form of
	# 		[$x1,$y1,$x2,$y2]
	# Return value is an array ref
	sub get_block {
		my $self	=	shift;
		my $ref		=	shift;
		my ($x1,$y1,$x2,$y2)	=	@{$ref};
		my @block	=	();
		my $count	=	0;
		for my $x ($x1..$x2-1) {
			for my $y ($y1..$y2-1) {
				$block[$count++]	=	$self->get($x,$y);
			}
		}
		return \@block;
	}
			
	# Returns pixel at $x,$y
	sub get {
		my $self	=	shift;
		my ($x,$y)  =	(shift,shift);
		return $self->{image}->[$y*320+$x];
	}
	
	# Returns array of (r,g,b) value from palette index passed
	sub rgb {
		my $self	=	shift;
		my $color	=	shift;
		return ($self->{palette}->[$color]->{red},$self->{palette}->[$color]->{green},$self->{palette}->[$color]->{blue});
	}
		
	# Returns mean of (rgb) value of palette index passed
	sub avg {
		my $self	=	shift;
		my $color	=	shift;
		return $self->{parent}->intr(($self->{palette}->[$color]->{red}+$self->{palette}->[$color]->{green}+$self->{palette}->[$color]->{blue})/3);
	}
	
	# Loads and decompresses a PCX-format 320x200, 8-bit image file and returns 
	# two arrays, first is a 64000-byte long array, each element contains a palette
	# index, and the second array is a 255-byte long array, each element is a hash
	# ref with the keys 'red', 'green', and 'blue', each key contains the respective color
	# component for that color index in the palette.
	sub load_pcx {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		
		# open the file
		open(FILE, "$_[0]");
		binmode(FILE);
		
		my $tmp;
		my @image;
		my @palette;
		my $data;
		
		# Read header
		read(FILE,$tmp,128);
		
		# load the data and decompress into buffer
		my $count=0;
		
		while($count<320*200) {
		     # get the first piece of data
		     read(FILE,$data,1);
	         $data=ord($data);
	         
		     # is this a rle?
		     if ($data>=192 && $data<=255) {
		        # how many bytes in run?
		        my $num_bytes = $data-192;
		
		        # get the actual $data for the run
		        read(FILE, $data, 1);
				$data=ord($data);
		        # replicate $data in buffer num_bytes times
		        while($num_bytes-->0) {
	            	$image[$count++] = $data;
		        } # end while
		     } else {
		        # actual $data, just copy it into buffer at next location
		        $image[$count++] = $data;
		     } # end else not rle
		}
		
		# move to end of file then back up 768 bytes i.e. to begining of palette
		seek(FILE,-768,2);
		
		# load the pallete into the palette
		for my $index (0..255) {
		    # get the red component
		    read(FILE,$tmp,1);
		    $palette[$index]->{red}   = ($tmp>>2);
		
		    # get the green component
		    read(FILE,$tmp,1);
			$palette[$index]->{green} = ($tmp>>2);
		
		    # get the blue component
		    read(FILE,$tmp,1);
			$palette[$index]->{blue}  = ($tmp>>2);
		
		}
		
		close(FILE);
		
		return @image,@palette;
	}



	
	

#-------------------------------
# AI::NeuralNet::BackProp::File
#-------------------------------
#
#	Simple data storage and retrival suitable
#   for both large- and small- scale databases.
#	Files stored with Storable and uses an OO API.
#					
# --------
# Version:	0.55
# Author:	Josiah Bryan
# History:	0.03b: Mar  7, 2000: Conversion from lib.pl to jdata.pl, OO code created.
# History:	0.04b: Mar 12, 2000: 2d table routines created
# History:	0.42b: Mar 21, 2000: Compiled j collection into jLIB
# History:  0.45a: Jul  7, 2000: Modified to use Storable, created Makefile.PL
# History:  0.55a: Jul 11, 2000: Re-wrote internal storage to make better use of refrences
# -----------------------------------------------------------------------------

#########################################
package AI::NeuralNet::BackProp::File;
			#
			# Package:
			#	AI::NeuralNet::BackProp::File
			# Name:	
			# 	jDATAbase version 0.55b   
			#----------------------------
			#
			# Notes on db format:
			#	Refrencing and Linking
			#		A refrence is a key with a value of \Table
			#		A link is a key with a value of *Table
			#		A refrence is hard, including all fields of refrenced
			#			table into owner table of refrence
			#		A refrence is automatically searched for a field
			#			if the get_field function cant find the key in the
			#			current table
			#		A refrence can be selected from in the owner table 
			#			or from anywheres including root
			#		A link is soft, not automatically searched, and
			#			must be selected from the owner table or with correct
			#			link path name
			#		Fields of a link are not included.
			#	
			#		Supports autorefrencing. I.e. When a new table is created, 
			#			a link is automatically placed in the current table, 
			#			thereby making the current table the owner of the new table.
			#		You can make a table be instead automatically _refrenced_ into
			#		the current table. This is autorefrencing.
			#		To enable autorefrencing:
			#			 autoref([PKG],[1/0]); 
			# 			 alternate syntax: $yourdatabase->autoref([1/0/-1]);
			#				A value of 1 turns on automatic refrencing, a value of 0 restores
			#				the default of automatic linking. A value of -1 completly
			#				disables any refrencing or linking, instead creating a 
			#				stand alone table upone call of add_table.
			#		
			#		Supports autowrite. I.e. When any change is made to the database
			#			information (such as deletion, adding, setting), the class
			#			will automatically write itself out to its diskname given
			#			at class creation.
			#		To enable autowrite:
			#			autowrite([PKG],[1/0]);
			#			alternate syntax: $yourdatabase->autowrite([1/0]); 
			#				Value of 1 enables autowrite, value of 0 disables autowrite
			#				Default value is 0
			#		It is recomended that you leave autowrite off if you are 
			#			creating an application with a need for speed, such
			#			as a game or other app. Autowrite is useful for data-critical
			#			applications such as accounting, servers, and the like.
			#
			#		Supports autocreate. I.e. When you attempt to set a key and the
			#			db driver cannot find it in any of the available tables, 
			#			autocreate will create a new key by the key name that you 
			#			are attempting to set and it will give it the new value that
			#			you are trying to set.
			#		To enable autocreate:
			#			autocreate([PKG],[1/0]);
			#			alternate syntax: $yourdatabase->autocreate([1/0]);
			#				Value of 1 enables autocreate, value of 0 disables autocreate
			#				Default value is 1
			#					
			#
			# --------
			# Version:	0.55b
			# Author:	Josiah Bryan
			# History:	0.03b:Mar 7, 0:Conversion from lib.pl to jdata.pl, OO code created.
			# History:	0.04b:Mar 12, 0:2d table routines created
			# History:	0.42b:Mar 21, 0:Compiled j collection into jLIB
			# History:  0.45a:Jul 7, 0:Modified to use Storable, created Makefile.PL
			# History:  0.55a:Jul 11, 0:Re-wrote internal storage to make better use of refrences
			# -----------------------------------------------------------------------------

## Inherit our configuration variables
my $DB_FILE_ROOT = '';
# Lock detection of OS, enables locking on all but DOS/Windows3.1/95/98/NT/OS2
sub testlock { return $^O =~ /{dos|os2|MSWin32}/ }
my $lock  = &testlock;
    

# Debugging subs
my $DEBUG = 0;
sub whowasi { (caller(1))[3] . '()' }
sub debug { $DEBUG = @_ ? shift : 1 }
sub out { print  shift()." \n\t - line ".(caller(0))[2]."\n" if $DEBUG }


# Call in libraries and helpful stuff
use strict;  


#### This is commented out because the load() and save() routines right now
#### don't work, so no other routines need this package. If you want to try
#### to get load() and store() working on your own, uncomment this next line
#### where it says "use Storable;" and uncomment the "use Storable;" under
#### the package declaration for AI::NeuralNet::BackProp. Note:
#### This package, AI::NeuralNet::BackProp::File, works completly fine. What
#### is 'broken' are the routines load() and save() themselves. This file
#### interface 'works'.

use Storable;


#########################################
			#
			# Constructor
			#
			# Loads databse file $_[0] into class
			#
sub new {
	my $type = shift;
	my $self = {};
	my ($db,@lines,$currentTable,$fieldCounter,$line,$key,$value,$convert_flag);
	$convert_flag=0;
	
	$db = $_[0];
	my $sep = $_[1];
	$sep = '=' if (!$sep);
	
	no strict 'refs';
	
	$self->{'_data'}{'_config'}{'_currentFieldTable'} = 0;
	$self->{'_data'}{'_config'}{'_prevTblList'}{'_size'}=0;
	$self->{'_data'}{'_config'}{'filename'} = $db;
	$self->{'_data'}{'_config'}{'_auto_refrence'} = -1;
	$self->{'_data'}{'_config'}{'_auto_select'} = -1;
	$self->{'_data'}{'_config'}{'_auto_write'}=0;
	$self->{'_data'}{'_config'}{'_auto_create'}=1;

	
	# did they pass a name? no? then just create the root and exit sub
	if (!$db) {
		out "Loading $DB_FILE_ROOT$db, AI::NeuralNet::BackProp::File::new::noname...";
	
	# they passed a file name, but it doesnt exist. Create a new file, exit sub.
	} elsif (! (-f "$DB_FILE_ROOT$db")) {
   		out "Loading $DB_FILE_ROOT$db, AI::NeuralNet::BackProp::File::new::new...";
   		open (DB, ">$DB_FILE_ROOT$db");
   		close DB;
	
	# we have a valid file, load into class 
	} else {
		out "Loading $DB_FILE_ROOT$db, AI::NeuralNet::BackProp::File::new::exist...";

		open(DB, "$DB_FILE_ROOT$db");
		flock(DB, 2) if ($lock);
		$line=<DB>;
		flock(DB, 8) if ($lock);
		close(DB);
		
		if (substr($line,0,6) eq "#-----") {
			$convert_flag=1;
		
			open(DB, "$DB_FILE_ROOT$db");
			flock(DB, 2) if ($lock);
			@lines=<DB>;
			flock(DB, 8) if ($lock);
			close(DB);
			
			my $currentTable="";
			$fieldCounter=0; 
			
			foreach $line (@lines) {
				next if ((substr($line,0,1) eq "\#") or (!$line));
				
				$line =~ s/\n//g;
				($key, $value) = split($sep, $line);
				$value =~ s/\n//g;
				$value =~ s/\r//g;
				$key =~ s/\n//g;
				$key = unescape($key);
				$value = unescape($value);
				out "Testing [$value]...";
				if ($value eq "Table") {
					my $i=_FETCHSIZE($self->{'_data'}{'_tables'}{'_index'});
					$self->{'_data'}{'_tables'}{'_index'}[$i]=$key;
					$currentTable = $key;
				} elsif ($value eq "EndTable") {
					out "End of Table: $currentTable\tField Counter: $fieldCounter\t";
				} else {	
					my $i=_FETCHSIZE($self->{'_data'}{'_tables'}{$currentTable}{'_field_list'});
					$self->{'_data'}{'_tables'}{$currentTable}{'_field_list'}[$i][0]=$key;
					$self->{'_data'}{'_tables'}{$currentTable}{'_field_list'}[$i][1]=$value;
					$self->{'_data'}{'_tables'}{$currentTable}{'_field_hash'}{$key}=$value;
				}	
							
				out "Current Table: $currentTable\tField Counter: $fieldCounter\tKey: $key\tValue: $value...";
			}
		
			$self->{'_data'}{'_config'}{'filename'} = $db;
			$self->{'_data'}{'_config'}{'_auto_refrence'} = -1;
			$self->{'_data'}{'_config'}{'_auto_select'} = 1;
			$self->{'_data'}{'_config'}{'_currentFieldTable'} = "";
		} else {
			$convert_flag=2;
			if(-s "$DB_FILE_ROOT$db") {
				my $ref = retrieve("$DB_FILE_ROOT$db");
		 	
				$self->{'_data'} = $ref;
				$self->{'_data'}{'_config'}{'filename'} = $db;
				$self->{'_data'}{'_config'}{'_auto_refrence'} = -1;
				$self->{'_data'}{'_config'}{'_auto_select'} = 1;
				$self->{'_data'}{'_config'}{'_currentFieldTable'} = "";
			}
		}	
	}
	
	# bless me into the class
	bless $self;
	
	# try to add table incase this db doesnt have a root
	$self->add_table("root");
	
	# attempt to select common base table to save on errors
	$self->{'_data'}{'_config'}{'_currentFieldTable'} = "root";
	
	# disable refrencing
	$self->{'_data'}{'_config'}{'_auto_refrence'} = 0;
	
	# Debug
	$self->dump_db() if ($DEBUG);
	
	# Auto-convert to Storable file if we loaded an older version file
	$self->writeout if($convert_flag eq 1);
	
	return $self;
}


#########################################
			#
			# Write the databse to disk
			#
sub DESTROY {
	writeout(@_) if($_[0]->{'_data'}{'_config'}{'_auto_destroy'});
}

#########################################
			#
			# Write the databse to disk
			#
			# Params:
			#    $filename as ARG0, optional
			#	 	If writeout does not recieve a filename
			#		as a param, it will write out to the file
			#		it loaded from as stored in the class 
			#
sub writeout {
	my $self = shift;
	my ($x,$y,$tableName,$tableSize,$db,$name,$value,$sep);
	my $filename = $_[0];
	
	$db = $self->{'_data'}{'_config'}{'filename'} if (!$filename);
	$db = $filename if ($filename);
	
	$db = $DB_FILE_ROOT.$db;
	
	store $self->{'_data'}, $db;
    
	return 1;
}	


#########################################
			#
			# Dump the database to screen
			#
sub dump_db {
	my $self = shift;
	my ($x,$y,$tableName,$tableSize,$name,$value,$oldTable);
	print "\nDATABASE DUMP\n";
	print "Filename: \t$self->{'_data'}{'_config'}{'filename'}\n";
	print "Num Tables: \t".(_FETCHSIZE($self->{'_data'}{'_tables'}{'_index'}))."\n";
	 
	print "DUMP:\n";
	
	$oldTable=$self->get_table();
	
	# start with base
	for ($x=0; $x<_FETCHSIZE($self->{'_data'}{'_tables'}{'_index'}); $x++) {
		
		$tableName = $self->{'_data'}{'_tables'}{'_index'}[$x];
		$tableSize = $self->get_table_size($tableName);
		
		$self->select($tableName);

		print "Table Name:\t[$tableName]\tTable Size:\t[$tableSize]\n";
		 
		for ($y=0; $y<$tableSize; $y++) {
		
			$name  = $self->get_name($y); #$self->{'_data'}{'_tables'}{$tableName}{'_field_list'}[$y][0];
			$value = $self->get($name);   #$self->{'_data'}{'_tables'}{$tableName}{'_field_hash'}{$name};
			
			print "\t\tField:\t[$name]\tValue:\t[$value]\t[$y]\n";
		}	
	}
	
	$self->select($oldTable);
}	

#########################################
			#
			# Hex encoding/decoding routines
			# Required for decoding of old (depreciated)
			# jDATA pre-v.42 format files that used URI escaping
			#
my %es;
for (0..255) { $es{chr($_)} = sprintf("%%%02X", $_);  }
sub unescape { my $a=$_[0]; $a =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg; while($a=~/\+/) { $a =~ s/\+/ /; } return $a }
sub escape   { my $a=$_[0]; $a =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/$es{$1}/g;   return $a }

#########################################
			#
			# Tests if character in $_[0] is a number
			#
			# Return 1 to indicate number, undef for non-number
			#
sub isnum {
	my $self = shift;
	my ($chr) = @_;
	return 0 if ($_[0] eq '.');
	return 0 if ($_[0] eq '?');
	return 0 if ($_[0] eq '+');
	return 0 if ($_[0] eq '*');
	return 0 if ($_[0] eq '{');
	return 0 if ($_[0] eq '}');
	return 0 if ($_[0] eq '(');
	return 0 if ($_[0] eq ')');
	my $numList = "0123456789";
	my $flag = 0;
	$flag = 1 if("0123456789"=~/$_[0]/i);
	return $flag;
}

#########################################
			#
			# Gets current table
			#
sub get_table {
	my $self = shift;
	my $tbl = $self->{'_data'}{'_config'}{'_currentFieldTable'};
	return ($tbl);
}	

#########################################
			#
			# Returns the key name of an index from the current table
			# Params: Index in $_[0]
			#
			# Return key name
			#
sub get_name {
	my $self = shift;
	my $idx =  $_[0];
	my $tbl =  $self->{'_data'}{'_config'}{'_currentFieldTable'};
	#print "current table:[$tbl]\nidx:[$idx]\n";
	return ($self->{'_data'}{'_tables'}{$tbl}{'_field_list'}[$idx][0]);
}	
	
#########################################
			#
			# Find index of key in current table
			#
sub get_index {
	my $self = shift;
	my $key  = shift;
	my $tbl =  $self->{'_data'}{'_config'}{'_currentFieldTable'};
	my $x;
    for($x=0;$x<$self->get_table_size($tbl);$x++) {
		return $x if($self->get_name($x) eq $key);
	}
	return undef;
}


#########################################
			#
			# Sets current table to new table in current table
			# Params:
			#        $_[0]: table key name or index from current table to select
			#
sub select {
	select_table(@_);
}	

#########################################
			#
			# Sets current table to new table in current table
			# Params:
			#        $_[0]: table key name or index from current table to select
			#
sub select_table {
    my $self = shift;
	my $table =  $_[0];
	my $tbl = $self->{'_data'}{'_config'}{'_currentFieldTable'};
	my ($size,$flag,$value_ptr)=(0,0,0);
	$value_ptr=$self->get($table);
	out "selecting $table from $tbl...";
	
	undef $flag;
	if($table eq "root") {
		$self->{'_data'}{'_config'}{'_currentFieldTable'} = $table;
		out "selecting ROOT...";
	} elsif ($self->{'_data'}{'_tables'}{$table}) {
		$self->{'_data'}{'_config'}{'_currentFieldTable'} = $table;
		$flag=$table;
		out "selecting absolute table $table...";
	} else { #if (($value_ptr eq "*Table") || ($value_ptr eq "\Table")) {
		$table = $tbl."\:\:".$table;
		if (exists $self->{'_data'}{'_tables'}{$table}) {
			$self->{'_data'}{'_config'}{'_currentFieldTable'} = $table;
			$flag=$table;
			out "selecting relative table $table...";
		} else {
			out "selector failed for $table (vptr:$value_ptr)...";
		}
	}
	
	return ($flag);	
}	

#########################################
			#
			# Returns a key value from current table
			#
sub get {
	get_field(@_);
}
	
#########################################
			#
			# Returns a key value from current table
			#
sub get_field {
	my $self = shift;
	my $raw =  $_[0];
	my $tbl =  $self->{'_data'}{'_config'}{'_currentFieldTable'};
	my ($key,$value,$x,$name);
	if ($self->isnum($raw)) {
		$key = $self->get_name($raw);
	} else {
		$key = $raw;
	}	
			
	# attempt to load value from current table
	if (exists  $self->{'_data'}{'_tables'}{$tbl}{'_field_hash'}{$key}) { 
		$value= $self->{'_data'}{'_tables'}{$tbl}{'_field_hash'}{$key};
		#out "$key exists in $tbl with value $value...";
	} else {
		undef $value;
		#out "$key does not exist in $tbl...";
	}	
	

	return ($value);
}	

#########################################
			#
			# Add a key=value pair to current table
			#
sub add {
	add_field(@_);
}	

#########################################
			#
			# Add a key=value pair to current table
			# Only adds new key to field_list if key
			# doesnt exist in field_hash.
			# Always sets key to value in field_hash.
			#
sub add_field {
	my $self = shift;
	my $key =  $_[0];
	my $value =  $_[1];
	my $tbl =  $self->{'_data'}{'_config'}{'_currentFieldTable'};
	
	out "adding $key, $value in $tbl...";
	
	# Add a new field to field_list if key doesnt exist in field_hash
	if (!defined $self->get_index($key)) {
		my $i=$self->get_table_size($tbl);
		$self->{'_data'}{'_tables'}{$tbl}{'_field_list'}[$i][0]=$key;
		out "nonexistent, adding at index $i, key $key...";
	}
	
	# Update values of key in field_hash and field_list even if key exists in field_hash
	$self->{'_data'}{'_tables'}{$tbl}{'_field_list'}[$self->get_index($key)][1]=$value;
	$self->{'_data'}{'_tables'}{$tbl}{'_field_hash'}{$key}=$value;
	
	$self->writeout if($self->{'_data'}{'_config'}{'_auto_write'});
	return ($value);
}	

#########################################
			#
			# Change the value of $_[0] to $_[1]
			#
sub set {
	set_field(@_);
}	

#########################################
			#
			# Change the value of $_[0] to $_[1]
			#
sub set_field {
	my $self = shift;
	my $raw =  $_[0];
	my $newValue =  $_[1];
	my $tbl =  $self->{'_data'}{'_config'}{'_currentFieldTable'};
	my ($key,$value,$x,$name);
			
	if ($self->isnum($raw)) {
		$key = $self->get_name($raw);
	} else {
		$key = $raw;
	}	
			
	out "attempting $key, raw $raw, value $newValue in $tbl... ";
				
	# attempt to load value from current table
	
	if(exists $self->{'_data'}{'_tables'}{$tbl}{'_field_hash'}{$key}) {
		$self->{'_data'}{'_tables'}{$tbl}{'_field_hash'}{$key}=$value;
		$self->{'_data'}{'_tables'}{$tbl}{'_field_list'}[$self->get_index($key)][1]=$value;
		out "exists test for $key in $tbl successful (index ".$self->get_index($key).")...";
	} else {
		out "exists test for $key in $tbl failed...";
	}
	
	out "value is undef..." if(!defined $value);
	
	# if we couldnt find the key at all create a new key in the current table if autocreate is 1
	$value=$self->add_field($key,$newValue) if($self->{'_data'}{'_config'}{'_auto_create'} and (!defined $value));
	
	# check for autowrite
	$self->writeout if($self->{'_data'}{'_config'}{'_auto_write'});
	
	# Grab the value that was on the stack if no error
	$value = $newValue if(defined $value);
	
	out "return: $value...";
	
	return ($value);
}	

#########################################
			#
			# Deletion function stubs provided
			# for backwards compatability.
			# Usage of these depreciated,
			# use del instead (or rm or remove)
			#
sub kill_tbl 		{ del(@_) }	
sub delete_table 	{ del(@_) }	
sub kill_table 		{ del(@_) }
sub kill 			{ del(@_) }
sub kill_field 		{ del(@_) }

########################################
			#
			# Aliases for the del method, below
			#
sub rm 				{ del(@_) }
sub remove 			{ del(@_) }	
 

########################################
			#
			# Attempt to delete item passed
			# Test if it is a table name or key name in current table
			#
sub del {
	my $self = shift;
	my $item = shift;
	my $tbl  = $self->{'_data'}{'_config'}{'_currentFieldTable'};
	if (exists $self->{'_data'}{'_tables'}{$item}) {
		my $x;
		for($x=0;$x<_FETCHSIZE($self->{'_data'}{'_tables'}{'_index'});$x++) {
			if($self->{'_data'}{'_tables'}{'_index'}[$x] eq $item) {
				#delete $self->{'_data'}{'_tables'}{'_index'}[$x];
				
				my @tmp=@{$self->{'_data'}{'_tables'}{'_index'}};
				my $i=0;
				$self->{'_data'}{'_tables'}{'_index'}=[];
				for(0..$#tmp){
					$self->{'_data'}{'_tables'}{'_index'}[$i++]=$tmp[$_] if($_ ne $x);
				}
			}
		}
		delete $self->{'_data'}{'_tables'}{$item};
		my @list=split(/\:\:/,$item);
		my $parent=join("\:\:",$list[0..$#list]);
		my $kid=$list[-1];
		my $_save=$self->get_table();
		out "parent $parent, kid $kid, save $_save...";
		$self->select($parent);
		$self->del($kid);
		$self->select($_save);
		$self->select($parent) if($_save eq $item);
	} else {
		my ($x,$i);
		$x=$self->get_index($item);
		out "deleting $item in $tbl, index $i...";
		return undef if(!$self->{'_data'}{'_tables'}{$tbl}{'_field_list'});
		my @tmp=@{$self->{'_data'}{'_tables'}{$tbl}{'_field_list'}};
		my $i=0;
		$self->{'_data'}{'_tables'}{$tbl}{'_field_list'}=[];
		for(0..$#tmp){
			if($_ ne $x) {
				$self->{'_data'}{'_tables'}{$tbl}{'_field_list'}[$i]=$tmp[$_];
				$i++;
			}
		}
		delete $self->{'_data'}{'_tables'}{$item};
	}
	$self->writeout if($self->{'_data'}{'_config'}{'_auto_write'});
}

sub conct {
	my @a=$_[0];
	my @b=$_[1];
	my @c;
	my $x;
	for($x=0;$x<$#a;$x++){$c[$x]=$a[$x]}
	for($x=0;$x<$#b;$x++){$c[$x-$#a]=$b[$x]}
	return @c;
}
	
#########################################
			#
			# Returns number of fields in current table
			#
sub get_table_size {
	my $self = shift;
	my $tbl =  $_[0];
	$tbl = $self->{'_data'}{'_config'}{'_currentFieldTable'} if (!$_[0]);
	return (_FETCHSIZE($self->{'_data'}{'_tables'}{$tbl}{'_field_list'})); 
}	

#########################################
			#
			# Add a table to current table, linking it to the current table
			#
sub add_tbl {
	add_table(@_);
}	

#########################################
			#
			# Add a table to current table, linking it to the current table
			#
sub add_table {
	my $self = shift;
	my $key =  $_[0];
	my $tbl =  $self->{'_data'}{'_config'}{'_currentFieldTable'};
	my $i;
    
	$self->add_field($key,"*Table") if ($self->{'_data'}{'_config'}{'_auto_refrence'} eq 0);
	$self->add_field($key,"\\Table") if ($self->{'_data'}{'_config'}{'_auto_refrence'} eq 1);
	
	$key = $tbl."::".$key if ($self->{'_data'}{'_config'}{'_auto_refrence'} eq 0);
	
	if (!exists $self->{'_data'}{'_tables'}{$key}) {
		$i=_FETCHSIZE($self->{'_data'}{'_tables'}{'_index'});
		$self->{'_data'}{'_tables'}{'_index'}[$i]=$key;
		$self->{'_data'}{'_tables'}{$key}={};
	}
	
	$self->select_table($key) if ($self->{'_data'}{'_config'}{'_auto_select'});
	$self->writeout if($self->{'_data'}{'_config'}{'_auto_write'});
	
	return ($key);
}

#########################################
			#
			# Returns (index) size of ARRAY ref in $_[0]
			# Used heavily internally
			#
sub _FETCHSIZE {
	my $a=$_[0];
	my ($b,$x);
	return undef if(substr($a,0,5) ne "ARRAY");
	foreach $b (@{$a}) { $x++ };
	return $x;
}

#########################################
			#
			# Set autorefrence flag. Default: 0
			#
sub autoref {
	my $self = shift;
	$self->{'_data'}{'_config'}{'_auto_refrence'}=$_[0];
}	

#########################################
			#
			# Set autowrite flag. Default: 0
			#
sub autowrite {
	my $self = shift;
	$self->{'_data'}{'_config'}{'_auto_write'}=$_[0];
}	

#########################################
			#
			# Set autowrite flag. Default: 1
			#
sub autowrite {
	my $self = shift;
	$self->{'_data'}{'_config'}{'_auto_create'}=$_[0];
}	

#########################################
			#
			# Set/Get diskname of datbase
			#
sub file {
	my ($self,$file)=(shift,shift);
	$self->{'_data'}{'_config'}{'filename'}=$file if ($file);
	$file=$self->{'_data'}{'_config'}{'filename'};
	return($file); 
}	

#########################################
			#
			# Compatibility alias
			#
sub diskname { file(@_) }

#########################################
			#
			# Simulated-2d (row and col) table functions
			#
sub rel_set_primary {
	my $self = shift;
	my ($p,$i) = @_;
	#$self->{'_relational'}
	$self->add_field("_primary_key",$p);
	$self->add_field("_current_primary",$p);
}

sub rel_set_colmap {
	my $self = shift;
	my ($colmap) = @_;
	$self->add_field("_colmap",$colmap);
}	

sub rel_add_row {
	my $self = shift;
	my ($parent,$name) = (shift,shift);
	$self->select_table($parent);
	if ($name) {
		out "Adding [$name] to [$parent]...";
		$name=$self->add_table($name) 
	} else {
		my ($p,$i,$k);
		$p=$self->get_field("_current_primary");
		out "got $p...";
		if (!defined $p) {
			$p = 0;
			$self->set_field("_current_primary",$p);
			out "undefined $p, setting $p...";
		}	
		$name=$p+1;
		out "Adding [$name],[$p] to [$parent]...";
		$self->set_field("_current_primary",$p+1);
		$name=$self->add_table($name);	
	}	
	$self->select_table($name);
	return ($name);
}			
	
sub rel_get_table_size {
	my $self = shift;
	my ($parent) = @_;
	$self->select_table($parent);
	return($self->get_field("_current_primary"));
}			
	
sub rel_get_row_size {
	my $self = shift;
	my ($name) = @_;
	$self->select_table($name);
	return($self->get_table_size($name));
}			

sub rel_set_col {
	my $self = shift;
	my ($col,$value) = @_;
	$value=$self->set_field($col,$value);
	return ($value);
}			

sub rel_get_col {
	my $self = shift;
	my ($col,$value) = @_;
	$value=$self->get_field($col,$value);
	return ($value);
}			
	
sub rel_set_row {
	my $self = shift;
	my ($row) = @_;
	my $value=$self->select_table($row);
	return ($value);
}			

sub rel_get_row {
	my $self = shift;
	my ($parent,$index) = @_;
	return ("$parent\:\:$index");
}			

sub rel_num_links {  
	my $self = shift;
	my ($table) = @_;
	my ($size,$links,$x,$value);
	$links=0;
	$size=$self->get_table_size($table);
	for ($x=0; $x<$size; $x++) {
		$value = $self->get($x);
		$links++ if ($value eq "*Table");
	}
	return ($links);
}		
	
1;

sub example {
	my ($p3,$parent,$row1,$row2,$row3);
	
	my $test = new AI::NeuralNet::BackProp::File("reltest.db");
	$test->select_table("root");
	$parent="root::relation1";
	$test->add_table("relation1");
	$test->select_table($parent);
	$test->rel_set_primary(0,1);
	#$test->rel_set_colmap("test1,test2,test3,test4");
	$row1=$test->rel_add_row($parent);
	$test->rel_set_col("test1","This is a test, #1.");
	$test->rel_set_col("test2","This is a test, #2.");
	$test->rel_set_col("test3","This is a test, #3.");
	$row2=$test->rel_add_row($parent);
	$test->rel_set_col("test1","This is a NOT test, #1.");
	$test->rel_set_col("test2","This is a NOT test, #2.");
	$test->rel_set_col("test3","This is a NOT test, #3.");
	$row3=$test->rel_add_row($parent);
	$test->rel_set_col("test1","This might be a test, #1.");
	$test->rel_set_col("test2","This might be a test, #2.");
	$test->rel_set_col("test3","This might be a test, #3.");
	$test->rel_set_row($row1);
	$p3=$test->rel_get_col("test1");
	printf "row($row1),col(test1): $p3\n";
	$p3=$test->rel_get_col("test2");      
	printf "row($row1),col(test2): $p3\n";
	$p3=$test->rel_get_col("test3");
	printf "row($row1),col(test3): $p3\n";
	$test->rel_set_row($row2);
	$p3=$test->rel_get_col("test1");
	printf "row($row2),col(test1): $p3\n";
	$p3=$test->rel_get_col("test2");      
	printf "row($row2),col(test2): $p3\n";
	$p3=$test->rel_get_col("test3");
	printf "row($row2),col(test3): $p3\n";
	$test->rel_set_row($row3);
	$p3=$test->rel_get_col("test1");
	printf "row($row3),col(test1): $p3\n";
	$p3=$test->rel_get_col("test2");      
	printf "row($row3),col(test2): $p3\n";
	$p3=$test->rel_get_col("test3");
	printf "row($row3),col(test3): $p3\n";
	
	
	$test->writeout();
}

1; # satisfy require




__END__





=head1 NAME

AI::NeuralNet::BackProp - A simple back-prop neural net that uses Delta's and Hebbs' rule.

=head1 SYNOPSIS

use AI::NeuralNet::BackProp;
	
	# Create a new network with 1 layer, 5 inputs, and 5 outputs.
	my $net = new AI::NeuralNet::BackProp(1,5,5);
	
	# Add a small amount of randomness to the network
	$net->random(0.001);

	# Demonstrate a simple learn() call
	my @inputs = ( 0,0,1,1,1 );
	my @ouputs = ( 1,0,1,0,1 );
	
	print $net->learn(\@inputs, \@outputs),"\n";

	# Create a data set to learn
	my @set = (
		[ 2,2,3,4,1 ], [ 1,1,1,1,1 ],
		[ 1,1,1,1,1 ], [ 0,0,0,0,0 ],
		[ 1,1,1,0,0 ], [ 0,0,0,1,1 ]	
	);
	
	# Demo learn_set()
	my $f = $net->learn_set(\@set);
	print "Forgetfulness: $f unit\n";
	
	# Crunch a bunch of strings and return array refs
	my $phrase1 = $net->crunch("I love neural networks!");
	my $phrase2 = $net->crunch("Jay Lenno is wierd.");
	my $phrase3 = $net->crunch("The rain in spain...");
	my $phrase4 = $net->crunch("Tired of word crunching yet?");

	# Make a data set from the array refs
	my @phrases = (
		$phrase1, $phrase2,
		$phrase3, $phrase4
	);

	# Learn the data set	
	$net->learn_set(\@phrases);
	
	# Run a test phrase through the network
	my $test_phrase = $net->crunch("I love neural networking!");
	my $result = $net->run($test_phrase);
	
	# Get this, it prints "Jay Leno is  networking!" ...  LOL!
	print $net->uncrunch($result),"\n";



=head1 UPDATES

This is version 0.77, a complete internal upgrade from version 0.42. A new feature
is the introduction of a randomness factor in the network, optional to disable. The 
restriction on 0s are removed, so you can run any network you like. See NOTES on using 0s with 
randomness disabled, below. Included is an improved learn() function, and a much more accurate 
internal fixed-point system for learning. Also included is automated learning of input sets. See
learn_set() and learn_rand_set() 



=head1 DESCRIPTION

AI::NeuralNet::BackProp is the flagship package for this file.
It implements a nerual network similar to a feed-foward,
back-propagtion network; learning via a mix of a generalization
of the Delta rule and a disection of Hebbs rule. The actual 
neruons of the network are implemented via the AI::NeuralNet::BackProp::neuron package.
	
You constuct a new network via the new constructor:
	
	my $net = new AI::NeuralNet::BackProp(2,3,1);
		

The new() constructor accepts two arguments and one optional argument, $layers, $size, 
and $outputs is optional (in this example, $layers is 2, $size is 3, and $outputs is 1).

$layers specifies the number of layers, including the input
and the output layer, to use in each neural grouping. A new
neural grouping is created for each pattern learned. Layers
is typically set to 2. Each layer has $size neurons in it.
Each neuron's output is connected to one input of every neuron
in the layer below it. 
	
This diagram illustrates a simple network, created with a call
to "new AI::NeuralNet::BackProp(2,2)" (2 layers, 2 neurons/layer).
	                             	
     input
     /  \
    O    O
    |\  /|
    | \/ |
    | /\ |
    |/  \|
    O    O
     \  /
    mapper

In this diagram, each neuron is connected to one input of every
neuron in the layer below it, but there are not connections
between neurons in the same layer. Weights of the connection
are controlled by the neuron it is connected to, not the connecting
neuron. (E.g. the connecting neuron has no idea how much weight
its output has when it sends it, it just sends its output and the
weighting is taken care of by the receiving neuron.) This is the 
method used to connect cells in every network built by this package.

Input is fed into the network via a call like this:

	use AI;
	my $net = new AI::NeuralNet::BackProp(2,2);
	
	my @map = (0,1);
	
	my $result = $net->run(\@map);
	

Now, this call would probably not give what you want, because
the network hasn't "learned" any patterns yet. But this
illustrates the call. Run expects an array refrence, and 
run gets mad if you don't give it what it wants. So be nice. 

Run returns a refrence with $size elements (Remember $size? $size
is what you passed as the second argument to the network
constructor.) This array contains the results of the mapping. If
you ran the example exactly as shown above, $result would contain
(1,1) as its elements. 

To make the network learn a new pattern, you simply call the learn
method with a sample input and the desired result, both array
refrences of $size length. Example:

	use AI;
	my $net = new AI::NeuralNet::BackProp(2,2);
	
	my @map = (0,1);
	my @res = (1,0);
	
	$net->learn(\@map,\@res);
	
	my $result = $net->run(\@map);

Now $result will conain (1,0), effectivly flipping the input pattern
around. Obviously, the larger $size is, the longer it will take
to learn a pattern. Learn() returns a string in the form of

	Learning took X loops and X wallclock seconds (X.XXX usr + X.XXX sys = X.XXX CPU).

With the X's replaced by time or loop values for that loop call. So,
to view the learning stats for every learn call, you can just:
	
	print $net->learn(\@map,\@res);
	

If you call "$net->debug(4)" with $net being the 
refrence returned by the new() constructor, you will get benchmarking 
information for the learn function, as well as plenty of other information output. 
See notes on debug() , in METHODS, below. 

If you do call $net->debug(1), it is a good 
idea to point STDIO of your script to a file, as a lot of information is output. I often
use this command line:

	$ perl some_script.pl > .out

Then I can simply go and use emacs or any other text editor and read the output at my leisure,
rather than have to wait or use some 'more' as it comes by on the screen.

This system was originally created to be a type of content-addressable-memory
system. As such, it implements "groups" for storing patterns and
maps. After the network has learned the patterns you want, then you
can call run with a pattern it has never seen before, and it will
decide which of the stored patterns best fit the new pattern, returning
the results the same as the above examples (as an array ref from $net->run()).

=head2 METHODS

=over 4

=item new AI::NeuralNet::BackProp($layers, $size [, $outputs])

Returns a newly created neural network from an C<AI::NeuralNet::BackProp>
object. Each group of this network will have C<$layers> number layers in it
and each layer will have C<$size> number of neurons in that layer.

There is an optional parameter of $outputs, which specifies the number
of output neurons to provide. If $outputs is not specified, $outputs
defaults to equal $size. $outputs may not exceed $size. If $outputs
exceeds $size, the new() constructor will return undef.

Before you can really do anything useful with your new neural network
object, you need to teach it some patterns. See the learn() method, below.

=item $net->learn($input_map_ref, $desired_result_ref [, options ]);

This will 'teach' a network to associate an new input map with a desired resuly.
It will return a string containg benchmarking information. You can retrieve the
pattern index that the network stored the new input map in after learn() is complete
with the pattern() method, below.

The first two arguments must be array refs, and they may be of different lengths.

Options should be written on hash form. There are three options:
	 
	 inc	=>	$learning_gradient
	 max	=>	$maximum_iterations
	 error	=>	$maximum_allowable_percentage_of_error
	 

$learning_gradient is an optional value used to adjust the weights of the internal
connections. If $learning_gradient is ommitted, it defaults to 0.20.
 
$maximum_iterations is the maximum numbers of iteration the loop should do.
It defaults to 1024.  Set it to 0 if you never want the loop to quit before
the pattern is perfectly learned.

$maximum_allowable_percentage_of_error is the maximum allowable error to have. If 
this is set, then learn() will return when the perecentage difference between the
actual results and desired results falls below $maximum_allowable_percentage_of_error.
If you do not include 'error', or $maximum_allowable_percentage_of_error is set to -1,
then learn() will not return until it gets an exact match for the desired result OR it
reaches $maximum_iterations.


=item $net->learn_set(\@set, [ options ]);

This takes the same options as learn() and allows you to specify a set to learn, rather
than individual patterns. learn_set() will return an integer specifying the amount of forgetfulness
when all the patterns are learned. If the learn_set()-specific option 'p' is set true, as in 
'p => 1' in the hash of options, then it will return a percentage represting the amount of forgetfullness,
rather than an integer. 

NOTE: I have disabled percentage returns, so it will always return a integer, for now. I disabled
it because I found there is a problem with the array refs and percentages when I was writing 
the new synopsis, so for now it returns intergers, no matter what the 'p' option is.

Example:

	# Data from 1989 (as far as I know..this is taken from example data on BrainMaker)
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
	
	# Learn the set
	my $f = learn_set(\@data, 
					  inc	=>	0.1,	
					  max	=>	500,
					  p		=>	1
					 );
			
	# Print it 
	print "Forgetfullness: $f%";

    
This is a snippet from the example script examples/finance.pl, which demonstrates DOW average
prediction for the next month. A more simple set defenition would be as such:

	my @data = (
		[ 0,1 ], [ 1 ],
		[ 1,0 ], [ 0 ]
	);
	
	$net->learn_set(\@data);
	
Same effect as above, but not the same data (obviously).

=item $net->learn_set_rand(\@set, [ options ]);

This takes the same options as learn() and allows you to specify a set to learn, rather
than individual patterns. 

learn_set_rand() differs from learn_set() in that it learns the patterns in a random order,
each pattern once, rather than in the order that they are in the array. This returns a true
value (1) instead of a forgetfullnes factor.

Example:

	my @data = (
		[ 0,1 ], [ 1 ],
		[ 1,0 ], [ 0 ]
	);
	
	$net->learn_set_rand(\@data);
	


=item $net->run($input_map_ref);

This method will apply the given array ref at the input layer of the neural network.

It will return undef on an error. An error is caused by one of two events.

The first is the possibility that the argument passed is not an array ref. If it
is not an array ref, it returns silently a value of undef.

UPDATED: You can now run maps with a 0 value. Beware though, it may not learn() a 0 value 
in the input map if you have randomness disabled. See NOTES on using a 0 value with randomness
disabled.


=item $net->benchmarked();

This returns a benchmark info string for the last learn() or the last run() call, 
whichever occured later. It is easily printed as a string,
as following:

	print $net->benchmarked() . "\n";





=item $net->debug($level)

Toggles debugging off if called with $level = 0 or no arguments. There are four levels
of debugging.

Level 0 ($level = 0) : Default, no debugging information printed, except for the 'Cannot run
0 value.' error message. Other than that one message, all printing is left to calling script.

Level 1 ($level = 1) : This causes ALL debugging information for the network to be dumped
as the network runs. In this mode, it is a good idea to pipe your STDIO to a file, especially
for large programs.

Level 2 ($level = 2) : A slightly-less verbose form of debugging, not as many internal 
data dumps.

Level 3 ($level = 3) : JUST prints weight mapping as weights change.

Level 4 ($level = 4) : JUST prints the benchmark info for EACH learn loop iteteration, not just
learning as a whole. Also prints the percentage difference for each loop between current network
results and desired results, as well as learning gradient ('incremenet').   

Level 4 is useful for seeing if you need to give a smaller learning incrememnt to learn() .
I used level 4 debugging quite often in creating the letters.pl example script and the small_1.pl
example script.

Toggles debuging off when called with no arguments. 



=item $net->save($filename);

This will save the complete state of the network to disk, including all weights and any
words crunched with crunch() . 



=item $net->load($filename);

This will load from disk any network saved by save() and completly restore the internal
state at the point it was save() was called at.




=item $net->join_cols($array_ref,$row_length_in_elements,$high_state_character,$low_state_character);

This is more of a utility function than any real necessary function of the package.
Instead of joining all the elements of the array together in one long string, like join() ,
it prints the elements of $array_ref to STDIO, adding a newline (\n) after every $row_length_in_elements
number of elements has passed. Additionally, if you include a $high_state_character and a $low_state_character,
it will print the $high_state_character (can be more than one character) for every element that
has a true value, and the $low_state_character for every element that has a false value. 
If you do not supply a $high_state_character, or the $high_state_character is a null or empty or 
undefined string, it join_cols() will just print the numerical value of each element seperated
by a null character (\0). join_cols() defaults to the latter behaviour.



=item $net->pdiff($array_ref_A, $array_ref_B);

This function is used VERY heavily internally to calculate the difference in percent
between elements of the two array refs passed. It returns a %.02f (sprintf-format) 
percent sting.


=item $net->p($a,$b);

Returns a floating point number which represents $a as a percentage of $b.



=item $net->intr($float);

Rounds a floating-point number rounded to an integer using sprintf() and int() , Provides
better rounding than just calling int() on the float. Also used very heavily internally.



=item $net->high($array_ref);

Returns the index of the element in array REF passed with the highest comparative value.



=item $net->low($array_ref);

Returns the index of the element in array REF passed with the lowest comparative value.



=item $net->show();

This will dump a simple listing of all the weights of all the connections of every neuron
in the network to STDIO.




=item $net->crunch($string);

UPDATE: Now you can use a variabled instead of using qw(). Strings will be split internally.
Do not use qw() to pass strings to crunch.

This splits a string passed with /[\s\t]/ into an array ref containing unique indexes
to the words. The words are stored in an intenal array and preserved across load() and save()
calls. This is designed to be used to generate unique maps sutible for passing to learn() and 
run() directly. It returns an array ref.

The words are not duplicated internally. For example:

	$net->crunch("How are you?");

Will probably return an array ref containing 1,2,3. A subsequent call of:

    $net->crunch("How is Jane?");

Will probably return an array ref containing 1,4,5. Notice, the first element stayed
the same. That is because it already stored the word "How". So, each word is stored
only once internally and the returned array ref reflects that.


=item $net->uncrunch($array_ref);

Uncrunches a map (array ref) into an array of words (not an array ref) and returns array.
This is ment to be used as a counterpart to the crunch() method, above, possibly to uncrunch()
the output of a run() call. Consider the below code (also in ./examples/ex1.pl):
                           
	use AI::NeuralNet::BackProp;
	my $net = AI::NeuralNet::BackProp->new(2,3);
	
	for (0..3) {
		$net->learn($net->crunch("I love chips."),  $net->crunch(qw(That's Junk Food!"));
		$net->learn($net->crunch("I love apples."), $net->crunch("Good, Healthy Food."));
		$net->learn($net->crunch("I love pop."),    $net->crunch("That's Junk Food!"));
		$net->learn($net->crunch("I love oranges."),$net->crunch("Good, Healthy Food."));
	}
	
	my $response = $net->run($net->crunch("I love corn."));
	
	print join(' ',$net->uncrunch($response));


On my system, this responds with, "Good, Healthy Food." If you try to run crunch() with
"I love pop.", though, you will probably get "Food! apples. apples." (At least it returns
that on my system.) As you can see, the associations are not yet perfect, but it can make
for some interesting demos!



=item $net->crunched($word);

This will return undef if the word is not in the internal crunch list, or it will return the
index of the word if it exists in the crunch list. 


=item $net->col_width($width);

This is useful for formating the debugging output of Level 4 if you are learning simple 
bitmaps. This will set the debugger to automatically insert a line break after that many
elements in the map output when dumping the currently run map during a learn loop.

It will return the current width when called with a 0 or undef value.


=item $net->random($rand);

This will set the randomness factor from the network. Default is 0.001. When called 
with no arguments, or an undef value, it will return current randomness value. When
called with a 0 value, it will disable randomness in the network. See NOTES on learning 
a 0 value in the input map with randomness disabled.



=item $net->load_pcx($filename);

Oh heres a treat... this routine will load a PCX-format file (yah, I know ... ancient format ... but
it is the only one I could find specs for to write it in Perl. If anyone can get specs for
any other formats, or could write a loader for them, I would be very grateful!) Anyways, a PCX-format
file that is exactly 320x200 with 8 bits per pixel, with pure Perl. It returns a blessed refrence to 
a AI::NeuralNet::BackProp::PCX object, which supports the following routinges/members. See example 
files pcx.pl and pcx2.pl in the ./examples/ directory.



=item $pcx->{image}

This is an array refrence to the entire image. The array containes exactly 64000 elements, each
element contains a number corresponding into an index of the palette array, details below.



=item $pcx->{palette}

This is an array ref to an AoH (array of hashes). Each element has the following three keys:
	
	$pcx->{palette}->[0]->{red};
	$pcx->{palette}->[0]->{green};
	$pcx->{palette}->[0]->{blue};

Each is in the range of 0..63, corresponding to their named color component.



=item $pcx->get_block($array_ref);

Returns a rectangular block defined by an array ref in the form of:
	
	[$left,$top,$right,$bottom]

These must be in the range of 0..319 for $left and $right, and the range of 0..199 for
$top and $bottom. The block is returned as an array ref with horizontal lines in sequental order.
I.e. to get a pixel from [2,5] in the block, and $left-$right was 20, then the element in 
the array ref containing the contents of coordinates [2,5] would be found by [5*20+2] ($y*$width+$x).
    
	print (@{$pcx->get_block(0,0,20,50)})[5*20+2];

This would print the contents of the element at block coords [2,5].



=item $pcx->get($x,$y);

Returns the value of pixel at image coordinates $x,$y.
$x must be in the range of 0..319 and $y must be in the range of 0..199.



=item $pcx->rgb($index);

Returns a 3-element array (not array ref) with each element corresponding to the red, green, or
blue color components, respecitvely.



=item $pcx->avg($index);	

Returns the mean value of the red, green, and blue values at the palette index in $index.
	


=head1 NOTES

=item Learning 0s With Randomness Disabled

You can now use 0 values in any input maps. This is a good improvement over versions 0.40
and 0.42, where no 0s were allowed because the learning would never finish learning completly
with a 0 in the input. 

Yet with the allowance of 0s, it requires one of two factors to learn correctly. Either you
must enable randomness with $net->random(0.0001) (Other valuse work, see random() ), or you 
must set an error-minum with the 'error => 5' option (you can use some other error value as well). 

When randomness is enabled (that is, when you call random() with a value other than 0), it interjects
a bit of randomness into the output of every neuron in the network, except for the input and output
neurons. The randomness is interjected with rand()*$rand, where $rand is the value that was
passed to random() call. This assures the network that it will never have a pure 0 internally. It is
bad to have a pure 0 internally because the weights cannot change a 0 when multiplied by a 0, the
product stays a 0. Yet when a weight is multiplied by 0.00001, eventually with enough weight, it will
be able to learn. With a 0 value instead of 0.00001 or whatever, then it would never be able
to add enough weight to get anything other than a 0. 

The second option to allow for 0s is to enable a maximum error with the 'error' option in
learn() , learn_set() , and learn_set_rand() . This allows the network to not worry about
learning an output perfectly. 

For accuracy reasons, it is recomended that you work with 0s using the random() method.

If anyone has any thoughts/arguments/suggestions for using 0s in the network, let me know
at jdb@wcoil.com. 




=head1 OTHER INCLUDED PACKAGES

=item AI::NeuralNet::BackProp::File

C<AI::NeuralNet::BackProp::File> implements a simple 'relational'-style
database system. It is used internally by C<AI::NeuralNet::BackProp> for 
storage and retrival of network states. It can also be used independently
of C<AI::NeuralNet::BackProp>. PODs are not yet included for this package, I hope
to include documentation for this package in future releases.

C<AI::NeuralNet::BackProp::File> depends on C<Storable>, version 0.611 for low-
level disk access. This dependency is noted in Makefile.PL, and should be handled
automatically when you installe this C<AI::NeuralNet::BackProp>.


=item AI::NeuralNet::BackProp::neuron

AI::NeuralNet::BackProp::neuron is the worker package for AI::NeuralNet::BackProp.
It implements the actual neurons of the nerual network.
AI::NeuralNet::BackProp::neuron is not designed to be created directly, as
it is used internally by AI::NeuralNet::BackProp.

=item AI::NeuralNet::BackProp::_run

=item AI::NeuralNet::BackProp::_map

These two packages, _run and _map are used to insert data into
the network and used to get data from the network. The _run and _map packages 
are connected to the neurons so that the neurons think that the IO packages are
just another neuron, sending data on. But the IO packs. are special packages designed
with the same methods as neurons, just meant for specific IO purposes. You will
never need to call any of the IO packs. directly. Instead, they are called whenever
you use the run() or learn() methods of your network.
        



=head1 BUGS

This is the beta release of C<AI::NeuralNet::BackProp>, and that holding true, I am sure 
there are probably bugs in here which I just have not found yet. If you find bugs in this module, I would 
appreciate it greatly if you could report them to me at F<E<lt>jdb@wcoil.comE<gt>>,
or, even better, try to patch them yourself and figure out why the bug is being buggy, and
send me the patched code, again at F<E<lt>jdb@wcoil.comE<gt>>. 



=head1 AUTHOR

Josiah Bryan F<E<lt>jdb@wcoil.comE<gt>>

Copyright (c) 2000 Josiah Bryan. All rights reserved. This program is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself.

The C<AI::NeuralNet::BackProp> and related modules are free software. THEY COME WITHOUT WARRANTY OF ANY KIND.
                                                             
=head1 THANX

Below is a list of people that have helped, made suggestions, patches, etc. No particular order.

		Tobias Bronx, F<E<lt>tobiasb@odin.funcom.comE<gt>> 
		Pat Trainor, F<E<lt>ptrainor@title14.comE<gt>>
		Steve Purkis, F<E<lt>spurkis@epn.nuE<gt>>
		Rodin Porrata, F<E<lt>rodin@ursa.llnl.govE<gt>>

Tobias was a great help with the initial releases, and helped with learning options and a great
many helpful suggestions. Rodin has gave me some great ideas for the new internals. Steve is
the author of AI::Perceptron, and gave some good suggestions for weighting the neurons. Pat 
has been a great help for running the module through the works. Pat is the author of the new Inter 
game, a in-depth strategy game. He is using a group of neural networks internally which provides
a good test bed for coming up with new ideas for the network. Thankyou for all of your help, everybody.


=head1 DOWNLOAD

You can always download the latest copy of AI::NeuralNet::BackProp
from http://www.josiah.countystart.com/modules/AI/cgi-bin/rec.pl

=cut

#!/usr/bin/perl	

# $Id: BackProp.pm,v 0.40 2000/07/21 15:12:41 josiah Exp $
#
# Copyright (c) 2000  Josiah Bryan  USA
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#

BEGIN {
	$AI::NeuralNet::BackProp::VERSION = ".40";
}

#
# name:   AI::NeuralNet::BackProp
#
# author: Josiah Bryan 
# date:   Friday July 21 2000
# desc:   A simple back-propagation, feed-foward neural network with
#		  learning implemented via a generalization of Debbs rule and
#		  several principals of Hoppfield networks. 
# online: http://www.josiah.countystart.com/modules/AI/cgi-bin/rec.pl
#

	use strict;
	use Carp; 

package AI::NeuralNet::BackProp::neuron;

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
		
		# Umm..gee..i dunno..what does this next line do? duh huh... :-)
		return $state;
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
			
			# Here we just decide what to do with the value.
			# If its the same, then somebody slipped up in calling us, so do nithing.
			if($value eq $what) {
				next;
			
			# Otherwise, we need to make this connection a bit heavier because the value is
			# lower than the desired value. So, we increase the weight of this connection and
			# then let all connected synapses adjust weight accordinly as well.
			} elsif($value < $what) {                                     
				$self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT}  +=  $ammount;
			    $self->{SYNAPSES}->{LIST}->[$_]->{PKG}->weight($ammount,$what);
			    AI::NeuralNet::BackProp::out1("$value is less than $what (\$_ is $_, weight is $self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT}, synapse is $self).\n");
			
			# Ditto as above block, except we take some weight off.
			} else {
			    $self->{SYNAPSES}->{LIST}->[$_]->{WEIGHT}  -=  $ammount;
				$self->{SYNAPSES}->{LIST}->[$_]->{PKG}->weight($ammount,$what);
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
		$self->{SYNAPSES}->{LIST}->[$sid]->{WEIGHT}		=	1.00+$AI::NeuralNet::BackProp::neuron::THRESHOLD+.01;
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
	
	
#### This is commented out because the load() and save() routines right now
#### don't work. If you want to try to get load() and store() working on your own, 
#### uncomment this next line where it says "use Storable;" and uncomment the 
#### "use Storable;" under the package declaration for AI::NeuralNet::BackProp::File.

	###### use Storable qw(freeze thaw);


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
			$str=int($el)."\0" if(!$a);
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
		shift if(substr($_[0],0,4) eq 'AI::'); 
		my $a1	=	shift;
		my $a2	=	shift;
		my $a1s	=	AI::NeuralNet::BackProp::_FETCHSIZE($a1);
		my $a2s	=	AI::NeuralNet::BackProp::_FETCHSIZE($a2);
		my ($a,$b,$diff,$t);
		$diff=0;
		return undef if($a1s ne $a2s);	# must be same length
		for(0..$a1s) {
			$a = ((@{$a1})[$_]);
			$b = ((@{$a2})[$_]);
			if($a!=$b) {
				if($a<$b){$t=$a;$a=$b;$b=$t;}
				$a=1 if($a eq 0);
				$diff+=(($a-$b)/$a)*100;
			}
		}
		return sprintf("%.1f",($diff/$a1s));
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
	    my $gsize	=	$self->{GROUPS}->{SIZE};
	    
	    print "Saving to $file...\n";
	    
	    my $db		=	AI::NeuralNet::BackProp::File->new($file);
	    
	    $db->select("root");
	    $db->set("size",$size);
	    $db->set("div",$div);
	    $db->set("gsize",$gsize);
	    $db->set("net",freeze($self->{NET}));
	    $db->set("groups",freeze($self->{GROUPS}));
	    
	    #my ($x,$group,$y,$z,$neuron);
		#for($x=1;$x<$gsize;$x++) {
		#	$db->select("root");
		#	$group = $db->add_table("group$x");
		#	$db->select($group);
		#	
		#	$db->set("map",join(',',@{$self->{GROUPS}->{DATA}->[$x]->{MAP}}));
		#	$db->set("res",join(',',@{$self->{GROUPS}->{DATA}->[$x]->{RES}}));
		#	
			#for($y=0;$y<$div;$y++) {
			#	$db->select($group);
			#	$db->set("neuron$y",freeze($self->{NET}->[$x]->[$y]->{SYNAPSES}->{LIST}));
			#}				
		#}    
		
		$db->writeout();
	}
		
	# Save entire network state to disk.
	sub save {
		my $self	=	shift;
		my $file	=	shift;
		my $size	=	$self->{SIZE};
		my $div		=	$self->{DIV};
	    my $gsize	=	$self->{GROUPS}->{SIZE};
	    
	    print "Saving to $file...\n";
	    
	    my $db		=	AI::NeuralNet::BackProp::File->new($file);
	    
	    $db->select("root");
	    $db->set("size",	$size);
	    $db->set("div",		$div);
	    $db->set("net",		freeze($self->{NET}));
	    $db->set("groups",	freeze($self->{GROUPS}));
	    
	    #my ($x,$group,$y,$z,$neuron);
		#for($x=1;$x<$gsize;$x++) {
		#	$db->select("root");
		#	$group = $db->add_table("group$x");
		#	$db->select($group);
		#	
		#	$db->set("map",join(',',@{$self->{GROUPS}->{DATA}->[$x]->{MAP}}));
		#	$db->set("res",join(',',@{$self->{GROUPS}->{DATA}->[$x]->{RES}}));
		#	
			#for($y=0;$y<$div;$y++) {
			#	$db->select($group);
			#	$db->set("neuron$y",freeze($self->{NET}->[$x]->[$y]->{SYNAPSES}->{LIST}));
			#}				
		#}    
		
		$db->writeout();
	}

	# Load entire network state from disk.
	sub load {
		my $self	=	shift;
		my $file	=	shift;
	    
	    print "Loading from $file...\n";
	    
	    my $db		=	AI::NeuralNet::BackProp::File->new($file);
	    
	    $db->select("root");
	    $self->{SIZE} 	= $db->set("size");
	    $self->{DIV} 	= $db->get("div");
	    $self->{NET} 	= $db->get("net");
	    $self->{GROUPS} = $db->get("groups");
	    
	    undef $db;
	    
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
		my $x		=	0; 
		my $y		=	0;
		
		AI::NeuralNet::BackProp::out2 "Initializing group $self->{GROUPS}->{CURRENT}...\n";
		
		# Reset map and run synapse counters.
		$self->{RUN}->{REGISTRATION} = $self->{MAP}->{REGISTRATION} = 0;
		
		AI::NeuralNet::BackProp::out2 "There will be $size neurons in this network group, with a divison value of $div.\n";
		
		# Create initial neuron packages in one long array for the entire group
		for($y=0; $y<$size; $y++) {
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
			$self->{NET}->[$self->{GROUPS}->{CURRENT}]->[$y]->register_synapse($self->{MAP});
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
	# to an array associated with that pattern. See usage in documentatio above.
	#
	# This slow_run() is different from the run() below, in that, the run() below
	# compares the input map with the learn()ed input map of each group, and the 
	# group who's comparission comes out as the lowest percentage difference is 
	# then used to run the input map. 
	# 
	# This slow_run() runs the input map through every neuron group and then compares
	# the result map() with the learn()ed result map, and the result map that has the
	# lowest comparrison percentage is returned as the output map. Some may argue
	# that this could be more accurate. I don't know. I plan to run some more tests
	# on the two methods, but right now I don't have the time. If anyone does 
	# come up with any results, or even a better way to sort the outputs, let me know
	# please (jdb@wcoil.com).
	#
	sub slow_run {
		my $self	 =	  shift;
		my $map		 =	  shift;
		my $gsize	 =	  $self->{GROUPS}->{SIZE};
		my $div 	 =	  $self->{DIV};
		my ($res,$omap,$x,$y);
		my (@score,@reses);
		my ($t0,$t1,$td);
		$t0 		 =	new Benchmark;
        for(1..$gsize-1) {  
			$self->{GROUPS}->{CURRENT} = $_;
			AI::NeuralNet::BackProp::out1 "Running group $self->{GROUPS}->{CURRENT}...\n";
			$self->{RUN}->run($map);
			$reses[$_]	=	$self->map();
			AI::NeuralNet::BackProp::out1 "Result for group $_: ".join(':',@{$reses[$_]})."\n";
			$score[$_]	=	pdiff($reses[$_],$self->{GROUPS}->{DATA}->[$_]->{RES});
			AI::NeuralNet::BackProp::out1 "Difference score for group $_: $score[$_]\n";
		}
		my $topi=1;
		for(1..$gsize-1) {
			$topi=$_ if($score[$_]<$score[$topi]);
		}
		$self->{LAST_GROUP}=$topi;   
		$t1 = new Benchmark;
	    $td = timediff($t1, $t0);
        $self->{LAST_TIME}="Input map ran through $gsize neuron groups and came up with final result in ".timestr($td,'noc','5.3f').".\n";
        return $reses[$topi];
	}


	# When called with an array refrence to a pattern, returns a refrence
	# to an array associated with that pattern. See usage in documentatio above.
	#
	# This compares the input map with the learn()ed input map of each group, and the 
	# group who's comparission comes out as the lowest percentage difference is 
	# then used to run the input map. 
	#
	# See comparrison with slow_run(), above.
	#
	sub run {
		my $self	 =	  shift;
		my $map		 =	  shift;
		my $gsize	 =	  $self->{GROUPS}->{SIZE};
		my ($t0,$t1,$td);
		$t0 		 =	new Benchmark;
        my (@score);
		for(1..$gsize-1) {  
			$score[$_] = pdiff($map,$self->{GROUPS}->{DATA}->[$_]->{MAP});
			AI::NeuralNet::BackProp::out1 "Difference score for group $_: $score[$_]\n";
		}
		my $topi=1;
		for(1..$gsize-1) {
			$topi=$_ if($score[$_]<$score[$topi]);
		}
		$self->{GROUPS}->{CURRENT}=$self->{LAST_GROUP}=$topi;
		$self->{RUN}->run($map);
		$t1 = new Benchmark;
	    $td = timediff($t1, $t0);
        $self->{LAST_TIME}="Input map compared to $gsize groups and came up with final result in ".timestr($td,'noc','5.3f').".\n";
        return $self->map();
	}


	# Retrieves index of last group matched or the last
	# pattern learned. 
	# 
	# See POD documentation for usages.
	#
	sub pattern {
		my $self	=	shift;
		return $self->{LAST_GROUP};
	}
	    
	# Returns benchmark and loop's ran or learned
	# for last run(), slow_run(), or learn()
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
	
	# Authors rambling injected...
	#
	# Hmm.. this could be something. I just realized:
	# With 'slow_run()', it compares the _outputs_
	# (result of each group running input map) with
	# the desired result (output) map of each group. 
	# Run() only compares the input map with the learn()ed
	# input map. 
	#
	# With run(), that means that the first group that matches
	# closest with learn()ed maps will be run, even if you
	# have learned the same map with different desired results.
	#
	# With slow_run(), you could conceivably learn one input
	# map with multiple desired results, and then slow_run() will
	# match the result from the input map against all desired results,
	# and return the one that matches closest.
	#
	# Intersting idea. For now, I don't see much of a need for 
	# multiple desired asociations with same input map. 
	#
	# Please let me know if anyone sees any other pros or cons
	# to this issue, and what you think should be done. 
	#
	# Email: jdb@wcoil.com
	#
	
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
		my $inc		=	shift || 0.20;
		my $div		=	$self->{DIV};
		my $size	=	$self->{SIZE};
		my ($a,$b,$y,$flag,$map,$loop,$diff,$pattern);
		my ($t0,$t1,$td);
		my ($it0,$it1,$itd);
		no strict 'refs';
		
		# Add a new group to network and save handle to it so it can
		# be retrieved using pattern() method.
		$self->{LAST_GROUP} = $self->{GROUPS}->{CURRENT} = $self->add_group($omap,$res);
		
		# Create neurons in group and link all packages together as needed.
		$self->initialize_group();
		
		# Start benchmark timer.
		$t0 	=	new Benchmark;
        $flag 	=	0; 
		$loop	=	0;
		
		# $flag only goes high when all neurons in output map compare exactly with
		# desired result map.
		#	
		while(!$flag) {
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
			$diff 	=	intr(pdiff($map,$res));
			
			# We de-increment the loop ammount to prevent infinite learning loops.
			# In old versions of this module, if you used too high of an initial input
			# $inc, then the network would keep jumping back and forth over your desired 
			# results because the increment was too high...it would try to push close to
			# the desired result, only to fly over the other edge too far, therby trying
			# to come back, over shooting again. What we do here is if the two maps
			# have a difference percentage greater than 30, we slowly de-increment the learning
			# ammount by .01, and if we hit 0 and we are still over 30, we go back up to a solid
			# 1 as the learning ammount.
			
			$inc -= .001 if($diff>30);
			$inc  = .3   if($inc<.0000000001);
			
			# Debugging
			AI::NeuralNet::BackProp::out4 "Difference: $diff\%\t Increment: $inc\n";
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
			
			# This counter is just used in the benchmarking operations.
			$loop++;
			
			AI::NeuralNet::BackProp::out1 "\n\n";
			
			# Benchmark this loop.
			$it1 = new Benchmark;
	    	$itd = timediff($it1, $it0);
			AI::NeuralNet::BackProp::out4 "Learning itetration $loop complete, timed at".timestr($itd,'noc','5.3f')."\n";
			# Map the results from this loop.
			AI::NeuralNet::BackProp::out2 "Map: \n";
			AI::NeuralNet::BackProp::join_cols($map,5) if ($AI::NeuralNet::BackProp::DEBUG);
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
	# Notice, we don't allow maps that have
	# any element with an undefined value. This
	# is because I have found in testing that
	# an undefined value can never be weighted.
	# We all know that 12958710924 times 0 is still
	# 0, right? The network can't handle that, though.
	# It will still try to apply as much weight
	# as it can to a 0 value, but the weighting will
	# always come back 0, and therefore, never be able
	# to match the desired result output, thereby
	# creating an infinite learn() loop cycle. Soooo...
	# to prevent the infinite looping, we simply
	# don't allow 0 values to be run. You can always
	# shift all values of your map up one number to
	# account for this if need be, and then subtract
	# one number from every element of the output to shift 
	# it down again. Let me know if anyone comes up
	# with a better way to do this.
	
	sub run {
		my $self	=	shift;
		my $map		=	shift;
		my $x		=	0;
		return undef if(substr($map,0,5) ne "ARRAY");
		foreach my $el (@{$map}) {
			if(!$el) {
				print "Cannot run a 0 value.\n";
				return undef;
			}
		}
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
		$self->{OUTPUT}->[$sid]->{VALUE}	=	$value;
		$self->{OUTPUT}->[$sid]->{FIRED}	=	1;
		
		AI::NeuralNet::BackProp::out1 "Received value $value and sid $sid...\n";
	}
	
	# Here we simply collect the value of every neuron connected to this
	# one from the layer below us and return an array ref to the final map..
	sub map {
		my $self	=	shift;
		my $size	=	$self->{PARENT}->{DIV};
		my @map = ();
		for(0..$size-1) {
			$map[$_]	=	$self->{OUTPUT}->[$_]->{VALUE};
			AI::NeuralNet::BackProp::out1 "Map position $_ is $map[$_] in @{[\@map]} with self set to $self.\n";
			$self->{OUTPUT}->[$_]->{FIRED}	=	0;
		}
		return \@map;
	}
1;
			      

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
# History:	0.03b:Mar 7, 0:Conversion from lib.pl to jdata.pl, OO code created.
# History:	0.04b:Mar 12, 0:2d table routines created
# History:	0.42b:Mar 21, 0:Compiled j collection into jLIB
# History:  0.45a:Jul 7, 0:Modified to use Storable, created Makefile.PL
# History:  0.55a:Jul 11, 0:Re-wrote internal storage to make better use of refrences
# -----------------------------------------------------------------------------

#########################################
package AI::NeuralNet::BackProp::File;
			#
			#	Package
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

#########	use Storable;


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


=head1 NAME

AI::NeuralNet::BackProp - A simple back-prop neural net that uses Delta's and Hebbs' rule.

=head1 SYNOPSIS

	use AI::NeuralNet::BackProp;
	
	# Create a new neural net with 2 layers and 3 neurons per layer
	my $net = new AI::NeuralNet::BackProp(2,3);
	
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
	



=head1 DESCRIPTION

AI::NeuralNet::BackProp is the flagship package for this file.
It implements a nerual network similar to a feed-foward,
back-propagtion network; learning via a mix of a generalization
of the Delta rule and a disection of Hebbs rule. The actual 
neruons of the network are implemented via the AI::NeuralNet::BackProp::neuron package.
	
You constuct a new network via the new constructor:
	
	my $net = new AI::NeuralNet::BackProp(2,3);
		

The new() constructor accepts two arguments, $layers and $size (in this example, $layers 
is 2 and $size is 3).

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
	
	$net->learn(\@map,\@res [, $inc]);
	
	my $result = $net->run(\@map);

$inc is an optinal learning speed increment. Good values are around 0.20
and 0.30. You can experiement with $inc to achieve faster learning speeds.
Some values of $inc work better for different maps. If $inc is ommitted,
it will default to 0.30 for $inc internally.

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

=item new AI::NeuralNet::BackProp($layers, $size)

Returns a newly created neural network from an C<AI::NeuralNet::BackProp>
object. Each group of this network will have C<$layers> number layers in it
and each layer will have C<$size> number of neurons in that layer.

Before you can really do anything useful with your new neural network
object, you need to teach it some patterns. See the learn() method, below.

=item $net->learn($input_map_ref, $desired_result_ref [, $learning_gradient ]);

This will 'teach' a network to associate an new input map with a desired resuly.
It will return a string containg benchmarking information. You can retrieve the
pattern index that the network stored the new input map in after learn() is complete
with the pattern() method, below.

The first two arguments must be array refs, and must be of the same length. 

$learning_gradient is an optional value used to adjust the weights of the internal
connections. If $learning_gradient is ommitted, it defaults to 0.30.

=item $net->run($input_map_ref);

This compares the input map with the learn()ed input map of each group, and the 
group who's comparission comes out as the lowest percentage difference is 
then used to run the input map. 

It will return undef on an error. An error is caused by one of two events.

The first is the possibility that the argument passed is not an array ref. If it
is not an array ref, it returns silently a value of undef.

The other condition that could cause an error is the fact that your map contained an 
element with an undefined value. We don't allow this because it has been in testing that
an undefined value can never be weighted. We all know that 12958710924 times 0 is still
0, right? The network can't handle that, though. It will still try to apply as much weight
as it can to a 0 value, but the weighting will  always come back 0, and therefore, never be able
to match the desired result output, thereby creating an infinite learn() loop cycle. Soooo...
to prevent the infinite looping, we simply don't allow 0 values to be run. You can always
shift all values of your map up one number to account for this if need be, and then subtract
one number from every element of the output to shift it down again. Let me know if anyone 
comes up with a better way to do this.

run() will store the pattern index of the group as created by learn(), so it can be 
retrieved with the pattern() method, below.

See notes on comparison between run() and slow_run() in NOTES section, below.	


=item $net->slow_run($input_map_ref);

When called with an array refrence to a pattern, returns a refrence
to an array associated with that pattern. See usage in documentatio above.

This slow_run() is different from run(), above, in that, the run() above
compares the input map with the learn()ed input map of each group, and the 
group who's comparission comes out as the lowest percentage difference is 
then used to run the input map. 

This slow_run() runs the input map through every neuron group and then compares
the result map() with the learn()ed result map, and the result map that has the
lowest comparrison percentage is returned as the output map. Some may argue
that this could be more accurate. I don't know. I plan to run some more tests
on the two methods, but right now I don't have the time. If anyone does 
come up with any results, or even a better way to sort the outputs, let me know
please (jdb@wcoil.com).

slow_run() will store the pattern index of the group as created by learn(), so it can be 
retrieved with the pattern() method, below.

See notes on comparison between run() and slow_run() in NOTES section, below.	


=item $net->pattern();

This will return the pattern index of the last map learned, or the pattern index of the
last map matched, whichever occured most recently. 

This is useful if you don't care about the mapping output, but just what it mapped.
For example, in the letters.pl example under the ./examples/ directory in the installation
tree that you should have gotten when you downloaded this pacakge, this method is used
to determine which letter was matched, rather than what the output is. See letters.pl
for example usage.


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



=item $net->intr($float);

Rounds a floating-point number passed to an integer using sprintf() and int() , Provides
better rounding than just calling int() on the float. Also used very heavily internally.







=head1 OTHER INCLUDED PACKAGES

=item AI::NeuralNet::BackProp::File

C<AI::NeuralNet::BackProp::File> implements a simple 'relational'-style
database system. It is used internally by C<AI::NeuralNet::BackProp> for 
storage and retrival of network states. It can also be used independently
of C<AI::NeuralNet::BackProp>. PODs are not yet included for this package, I hope
to include documentation for this package in future releases.

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
        

=head1 NOTES

=head2 run() and slow_run() compared

Authors thoughts...

Hmm.. this could be something. I just realized:
With slow_run() , it compares the _outputs_
(result of each group running input map) with
the desired result (output) map of each group. 
run() only compares the input map with the learn() ed
input map. 

With run() , that means that the first group that matches
closest with learn() ed maps will be run, even if you
have learned the same map with different desired results.

With slow_run() , you could conceivably learn one input
map with multiple desired results, and then slow_run() will
match the result from the input map against all desired results,
and return the one that matches closest.

Intersting idea. For now, I don't see much of a need for 
multiple desired asociations with same input map. 

Please let me know if anyone sees any other pros or cons
to this issue, and what you think should be done. 


=head2 load() and save()

These are two methods I have not documented, as they don't 
work (correctly) yet. They rely on the Storable package, not
included, and the AI::NeuralNet::BackProp::File pacakge, 
included here. 

The AI::NeuralNet::BackProp::File package works fine, the
problem lies in the load() and save() routines themselves. 
It seems the freeze() and thaw() functions aren't handling
the refrences very well. 

I included these functions in this beta release in case anyone
felt dareing enough to try to get them working themselves. If you
do, I<please> send me a copy of the code! :-)



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

The C<AI::NeuralNet::BackProp> and related modules are free software. THEY COMES WITHOUT WARRANTY OF ANY KIND.

=head1 DOWNLOAD

You can always download the latest copy of AI::NeuralNet::BackProp
from http://www.josiah.countystart.com/modules/AI/cgi-bin/rec.pl

=cut
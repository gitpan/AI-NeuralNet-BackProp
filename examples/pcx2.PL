=begin

File:   pcx2.pl
Author: Josiah Bryan, jdb@wcoil.com

BEWARE, after 6 HOURS this never finished learning!

This works completly, at least in theory. It seems that
the network has trouble with the high numbers in the
test image, all were in the 240-255 range. This also
demonstrates use of the {col_width} parameter, the various
pcx functions, as well as high() and low().

=cut
	
	
	use AI::NeuralNet::BackProp;
	
	# Set block sizes
	my ($bx,$by)=(10,10);
	
	print "Creating Neural Net...";
	my $net=AI::NeuralNet::BackProp->new(2,$bx*$by);
	$net->{col_width} = $bx;
	print "Done!\n";
	
	print "Loading bitmap...";
	my $img = $net->load_pcx("josiah.pcx");             
	print "Done!\n";
	
	print "Comparing blocks...\n";
	my $white = $img->get_block([0,0,$bx,$by]);
	
	my ($x,$y,$tmp,@scores,$s,@blocks,$b);
	for ($x=0;$x<320;$x+=$bx) {
		for ($y=0;$y<200;$y+=$by) {
			$blocks[$b++]=$img->get_block([$x,$y,$x+$bx,$y+$by]);
			$score[$s++]=$net->pdiff($white,$blocks[$b-1]);
			print "Block at [$x,$y], index [$s] scored ".$score[$s-1]."%\n";
		}
	}
	print "Done!";
	
	print "High score:\n";
	join_cols($blocks[$net->high(\@score)],$bx); 
	print "Low score:\n";
	join_cols($blocks[$net->low(\@score)],$bx); 
	
	$net->debug(4);
	
	print "Learning high block...\n";
	print $net->learn($blocks[$net->high(\@score)],$blocks[$net->high(\@score)]);
	
	$net->save("pcx2.net");
	
	print "Learning low block...\n";
	$net->learn($blocks[$net->low(\@score)],$blocks[$net->low(\@score)]);
	
	print "Testing random block...\n";
	
	join_cols($net->run($blocks[rand()*$b]),$bx);
	
	print "Bencmark for run: ", $net->bencmarked(), "\n";
	
	$net->save("pcx2.net");
	
		sub join_cols {
			no strict 'refs';
			shift if(substr($_[0],0,4) eq 'AI::'); 
			my $map		=	shift;
			my $break   =	shift;
			my $x;
			my @els = (' ','.',',',':',';','%','#');
			foreach my $el (@{$map}) { 
				$str=$el/255*6;
				print $els[$str];
				$x++;
				if($x>$break-1) {
					print "\n";
					$x=0;
				}
			}
			print "\n";
		}
		
		                                         
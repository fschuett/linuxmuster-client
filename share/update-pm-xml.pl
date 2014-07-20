#!/usr/bin/perl -w
# Frank Schütte 2012
# Update pam_mount.conf.xml with the template from linuxmuster-client,
# but don't overwrite additional volumes.
#
use strict;
use warnings;

use XML::Simple;
use Data::Dumper;
use feature 'say';

sub del_double {
    my %all = ();
    @all{@_}=1;
    return (keys %all);
}

my $num_args = $#ARGV + 1;
if ( $num_args != 2 ) {
    print "\nUsage: update-xml.pl template target\n";
    exit 1;
}

my $template = XMLin(
    $ARGV[0],
    ForceContent => 1,
    KeyAttr => {'volume' => 'path'},
);

my $target = XMLin(
    $ARGV[1],
    ForceContent => 1,
    KeyAttr => { 'volume' => 'path'},
);

my %mntoptions;

while( my ($k,$v) = each(%$template)){
    if($k eq "mntoptions"){
	if(ref($v) ne 'ARRAY'){
	    $v = [ $v ];
	}
	foreach my $list (@$v){
	    while( my ($kk,$vv) = each(%$list)){
		foreach(split(/,/,$vv)){
		    push(@{$mntoptions{$kk}},$_);
		}
	    }
	}
    }
}

while( my ($k,$v) = each(%$target)){
    if($k eq "mntoptions"){
	if(ref($v) ne 'ARRAY'){
	    $v = [ $v ];
	}
	foreach my $list (@$v){
	    while( my ($kk,$vv) = each(%$list)){
		foreach(split(/,/,$vv)){
		    push(@{$mntoptions{$kk}},$_);
		}
	    }
	}
    }
}


if(%mntoptions){
    $target->{'mntoptions'} = ();
    
    while( my ($k,$v) = each(%mntoptions)){
	@$v = del_double(@$v);
	@$v = sort(@$v);
	$target->{'mntoptions'}->{$k} = join(',', @$v);
    }
}

while( my ($k,$v) = each(%$template)){
    if($k eq "volume"){
	while( my ($kk,$vv) = each(%$v)){
	    $target->{$k}->{$kk} = $vv;
	}
    }
    elsif($k eq "mntoptions"){
    }
    else {
	$target->{$k} = $v;
    }
}

XMLout(
    $target,
    XMLDecl => '<?xml version="1.0" encoding="UTF-8"?>',
    RootName => 'pam_mount',
    NoEscape => 1,
    KeyAttr => { 'volume' => 'path'},
    OutputFile => $ARGV[1],
);

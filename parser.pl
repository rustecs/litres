#!/usr/bin/perl

use strict;
use XML::LibXML;

my $path = $ARGV[0];

unless ( $path ) { usage('No parametres gotted') }

unless ( -f $path ) { usage("File '$path' does not exists") }

my $dom;
eval { $dom = XML::LibXML->load_xml( location => $path ) };

if ( $@ ) { usage("Looks like xml is broken: $@") }

my $root = $dom->getDocumentElement();

my $txt = fwd($root);

$txt =~s/[\n\r]//g;
my $to_out = { l_with_s => length $txt };

$txt =~ s/\s//g;
$$to_out{ l_without_s} = length $txt;

found_err($to_out);

put_out($to_out);


sub put_out
{
 my $o = shift;
 print <<POUT;
 Symbols at xml without spaces: $$o{l_without_s}
 Symbols at xml with spaces:    $$o{l_with_s}
 Links count at text:           $$o{lk_cnt}
 Broken links at text:          $$o{lk_wrong}
POUT
}


sub found_err
{
 my $o = shift;
 my $sc = get_section($dom);
 my ($lk_cnt, $lk) = get_links($dom);

 my $wlc = 0;
 foreach my $k ( keys %{$lk}) 
 {
  $wlc++ unless ( exists $$sc{$k} )
 }
 $$o{lk_cnt} = $lk_cnt;
 $$o{lk_wrong} = $wlc;
}

sub get_links
{ 
 my $n = shift;
 my $out = {};
 my $cnt = 0;
 foreach my $sn(  $n->findnodes('//*[@l:href]') )
 {
  if ( $sn->nodeName eq 'a') 
  {
   $cnt++;
   $$out{ $sn->getAttribute('l:href') } = 1; 
  }
 }
 return $cnt, $out
}


sub get_section
{
 my $n = shift;
 my $out = {};
 foreach my $sn(  $n->findnodes('//*[@id]') )
 {
  if ( $sn->nodeName eq 'section') 
  {
   $$out{ '#'.$sn->getAttribute('id') } = 1; 
  }
 }
 return $out 
}


sub fwd
{
 my $n = shift;
 my $out = '';
 foreach my $sn ( $n->getChildNodes() )
 {
  next if ( $sn->nodeName() eq 'binary'); #not a text
  if ( $sn->nodeName eq '#text' ) 
   { $out.= $sn->to_literal }
  else
   { $out.= fwd($sn) }
 }
 return $out
}


sub usage
{
 my $s = shift;

 print <<OUT;
Error: $s

Usage:
$0 path_to_xml_file

OUT

 exit
}




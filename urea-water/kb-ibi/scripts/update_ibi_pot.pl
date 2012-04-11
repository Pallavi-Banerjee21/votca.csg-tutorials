#! /usr/bin/perl -w
#
# Copyright 2009-2011 The VOTCA Development Team (http://www.votca.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

use strict;
( my $progname = $0 ) =~ s#^.*/##;

if (defined($ARGV[0])&&("$ARGV[0]" eq "--help")){
  print <<EOF;
$progname, version %version%
This script calcs dU out of two rdfs with the rules of inverse boltzmann

In addition, it does some magic tricks:
- do not update if one of the two rdf is undefined

Usage: $progname new_rdf target_rdf cur_pot outfile
EOF
  exit 0;
}

die "4 parameters are nessary\n" if ($#ARGV<3);

use CsgFunctions;

my $pref=csg_get_property("cg.inverse.kBT");

my $aim_rdf_file="$ARGV[0]";
my @r_aim;
my @rdf_aim;
my @flags_aim;
(readin_table($aim_rdf_file,@r_aim,@rdf_aim,@flags_aim)) || die "$progname: error at readin_table\n";

my $cur_rdf_file="$ARGV[1]";
my @r_cur;
my @rdf_cur;
my @flags_cur;
(readin_table($cur_rdf_file,@r_cur,@rdf_cur,@flags_cur)) || die "$progname: error at readin_table\n";

my $cur_pot_file="$ARGV[2]";
my @pot_r_cur;
my @pot_cur;
my @pot_flags_cur;
(readin_table($cur_pot_file,@pot_r_cur,@pot_cur,@pot_flags_cur)) || die "$progname: error at readin_table\n";

#should never happen due to resample, but better check
die "Different grids \n" if (($r_aim[1]-$r_aim[0])!=($r_cur[1]-$r_cur[0]));
die "Different start point \n" if (($r_aim[0]-$r_cur[0]) > 0.0);

my $outfile="$ARGV[3]";
my @dpot;
my @flag;
my $value=0.0;
my $j;
my @intdist;
my $dpot_int;
my $avg_int;
my $kbibi_ramp="no";
my $int_start;
my $int_stop;
my $ramp_factor;
if ($ARGV[4] eq "--with-ramp") {
   $kbibi_ramp="yes";
   $int_start="$ARGV[5]";
   $int_stop="$ARGV[6]";
   $ramp_factor="$ARGV[7]";
   $intdist[0]=0;
   $avg_int=0;
   $j=0;

   for (my $i=1;$i<=$#r_aim;$i++){
     $intdist[$i]=$intdist[$i-1]+($rdf_cur[$i]-$rdf_aim[$i])*$r_aim[$i]*$r_aim[$i];
   }

   for (my $i=0;$i<=$#r_aim;$i++){
     if (($r_aim[$i]>$int_start) && ($r_aim[$i]<$int_stop)) {
        $avg_int=$avg_int+$intdist[$i];
        $j=$j+1;
     } 
   }
   $avg_int=$avg_int/$j;
   }

for (my $i=0;$i<=$#r_aim;$i++){  
  if (($rdf_aim[$i] > 1e-10) && ($rdf_cur[$i] > 1e-10)) {
    if ("$kbibi_ramp" eq "yes"){
    $dpot[$i]=($avg_int*$ramp_factor*(1.0-($r_aim[$i]/$int_stop)))*$pref;
    }
    else {
    $dpot[$i]=log($rdf_cur[$i]/$rdf_aim[$i])*$pref;
    }
    $flag[$i]="i";
  } else {
    $dpot[$i]=$value;
    $flag[$i]="o";
  }
  if($pot_flags_cur[$i] =~ /[u]/) {
    $dpot[$i]=$value;
    $flag[$i]="o";
  }
  else {
    $value=$dpot[$i];
  }
}

saveto_table($outfile,@r_aim,@dpot,@flag) || die "$progname: error at save table\n";


#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <app_launch_trace_path>"
  exit 1
fi

TRACE_PATH="$1"
TMP_XML="$(mktemp -t dailyos-dyld-XXXXXX.xml)"

xcrun xctrace export \
  --input "$TRACE_PATH" \
  --xpath '/trace-toc/run[@number="1"]/data/table[@schema="dyld-activity-interval"]' \
  --output "$TMP_XML" >/dev/null

perl -0777 -ne '
my %act;
while(/<dyld-activity id="(\d+)" fmt="([^"]+)">/g){$act{$1}=$2;}
my %sum;
while(/<row>(.*?)<\/row>/sg){
  my $r=$1;
  my ($dur)=($r=~/<duration[^>]*fmt="[^"]+">(\d+)<\/duration>/);
  next unless defined $dur;
  my ($lvl)=($r=~/<containment-level[^>]*fmt="([^"]+)"/);
  next if defined($lvl) && $lvl eq "1";

  my $activity="";
  if($r=~/<dyld-activity id="(\d+)"(?: fmt="([^"]+)")?/){
    $activity=$2 // $act{$1} // "";
  } elsif($r=~/<dyld-activity ref="(\d+)"\/>/){
    $activity=$act{$1} // "";
  }
  $sum{$activity}+=$dur if $activity ne "";
}

for my $k (sort {$sum{$b}<=>$sum{$a}} keys %sum){
  printf "%s\t%.3f ms\n",$k,$sum{$k}/1_000_000;
}
' "$TMP_XML"

rm -f "$TMP_XML"

#!/usr/bin/env perl
use strict;
use warnings;
use HTML::TreeBuilder;
binmode STDOUT, ":utf8"; # spit utf8 to terminal
use utf8; # allow for utf8 inside the code.
# use Data::ICal;
# use Data::ICal::Entry::Event;
# use diagnostics;
# use feature "switch";

# require 5.004;
# use POSIX qw(locale_h);
# use locale;
# use Date::ICal;
use DateTime;

my $file;

## Parse arguments
# while(shift) will not work (scope problem ?)
# while($_ = shift) will usually work, except if the value was one to
# be interpreted as false (e.g. 0)
while (defined($_ = shift)) {
  if (!defined($file)) {
    $file = $_;
    unless (-f $file) { show_help_and_exit(); }
  } else {
    print STDERR "Unrecognized option or constraint.\n";
    show_help_and_exit();
  }
}
## Arguments parsed.

my $tree = HTML::TreeBuilder->new;
$tree->parse_file($file);

my $subtree = ($tree->find("table"))[2]; # La table HTML qui contient toutes les dates.

foreach my $tr ($subtree->find("tr")) {
  my @td = $tr->find("td");
  my $date = shift @td;
  $date = $date->as_text();
  next unless $date =~ /\d\d\/\d\d\/\d\d\d\d/;
  foreach (map { $_->as_text() } $td[0]->find("li")) {
    my $timestamp;
    if (/(\d{2}h(\d{2})?)/ and not /ANNULEE/) { 
      if ($2) { $timestamp = date2timestamp($date, $1) }
      else { $timestamp = date2timestamp($date, $1) }
    }
    else { $timestamp = date2timestamp($date) }
    printf "** %s\n", $_;
    printf "%s\n", $timestamp;
  }
}

$tree->delete();

sub date2timestamp {
  my ($date, $time) = @_;
  my $format;
  my (@date, @time);

  if ($time) {
    $format = "<%Y-%m-%d %a. %H:%M>";
  }
  else {
    $time = "12h00"; # noon 
    $format = "<%Y-%m-%d %a.>";
  }

  @date = split(/\//,$date);
  @time = split(/h/,$time);

  my $dt = DateTime->new(
			 year       => $date[2],
			 month      => $date[1],
			 day        => $date[0],
			 hour       => $time[0],
			 minute     => ($time[1] or 0),
			 second     => 0,
			 time_zone  => 'local',
			);
  return $dt->strftime($format);
}

sub show_help_and_exit {
  printf STDERR << "EOF";
$0 analyzes the HTML soup from
https://www.ulb.ac.be/ulb/greffe/agenda/academique.html
and spits an org-mode tree with timestamps.

It is given a filename as its sole argument.
EOF
  exit
}

# Local Variables:
# mode: cperl
# End:

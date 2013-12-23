#!/bin/perl

use LWP::Simple;
$iddolSite = "http://www.doi.idaho.gov/insurance/IndividualList.aspx?Name=&nopages=YES";

### MAIN PROCEDURE ###

$mainList = getHTML($iddolSite);
@lic = getLicenseList($mainList);
#collectData($lic[0]);

### SUBROUTINES ###

sub getHTML
{
	my ($url) = @_;
	my $content = get $url;
	die "Couldn't get $url" unless defined $content;	
	return $content;
}

sub getLicenseList
{
	my ($listData) = @_;
	my @licenseList = ($listData =~ /lic_no=(\d+)/gc);
+	return @licenseList;
}

#sub collectData
#{
#	my ($agentLic) = @_;
#	my $agentURL = "http://www.doi.idaho.gov/insurance/AgentDetail.aspx?lic_no=$agentLic";
#	my $agentData = getHTML($agentLic);
#	
#}
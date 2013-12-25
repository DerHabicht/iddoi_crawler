#!/bin/perl

### Global Declarations ###
use LWP::Simple;

$iddolSiteURL = "http://www.doi.idaho.gov/insurance/IndividualList.aspx?Name=&nopages=YES";
$csvFile = "Name, Address, Business Phone, License Number, NPN, Issued, Expires, Status, Type, Business Lines\n";

### Main Routine ###

$iddolSiteContent = getHTML($iddolSiteURL);	# Get the main IDDOL page.
@lic = getLicenseList($iddolSiteContent);	# Extract license ids.
collectData($lic[0]);						# Extract the first line (DEBUG ONLY)
writeFile();								# Make the .csv file.

### SUBROUTINES ###

### getHTML Subroutine
#	Takes an HTTP url scalar as an argument
#	Returns the content of the webpage at that url.
sub getHTML
{
	my ($url) = @_;
	my $content = get $url;
	die "Couldn't get $url" unless defined $content;	
	return $content;
}

### getLicenseList Subroutine
#	Takes, as an argument, the raw HTML of the IDDOL license search page.
#	Returns an array containing a list of agent license numbers. 
sub getLicenseList
{
	my ($listData) = @_;
	my @licenseList = ($listData =~ /lic_no=(\d+)/gc);
+	return @licenseList;
}

### collectData
#	Takes a scalar agrument containing an agent's license number.
#	Retrieves that agent's information page from the IDDOL site,
#	then extracts and records the agent's information.
sub collectData
{
	my ($license) = @_;
	my $agentURL = "http://www.doi.idaho.gov/insurance/AgentDetail.aspx?lic_no=$license";
	my $agentData = getHTML($agentURL);
	
	# Extract personal agent information.
	
	$agentData =~ 	m{
					\s*<B>Name:</B>.*\n				# Agent's name
					.*\n
					\s*<.*>(.*),\s(.*)<.*>.*\n		# $1 and $2
					
					.*\n .*\n .*\n .*\n .*\n .*\n .*\n .*\n .*\n .*\n .*\n
					
					\s*<B>Address:</B>.*\n			# Agent's address
					.*\n
					\s*<.*>(.*)<br>(.*)<.*>.*\n		# $3 and $4
					
					.*\n
					
					\s*<B>NPN:</B>.*\n				# Agent's NPN
					.*\n
					\s*<.*>(.*)<.*>.*\n				# $5
					
					.*\n .*\n .*\n
					
					\s*<.*>(.*),\s(.*)<.*>.*\n		# $6 and $7: The rest
												  	# of the agent's address.
					
					.*\n
					
					\s*<B>Issued:</B>.*\n			# Agent's license issue
					.*\n
					\s*<.*>(.*)<.*>.*\n				# $8
					
					.*\n .*\n .*\n .*\n .*\n
					
					\s*<B>Expires:</B>.*\n			# License expiry
					.*\n
					\s*<.*>(.*)<.*>.*\n				# $9
					
					.*\n .*\n .*\n
					
					\s*<B>Business\sPhone:</B>.*\n	# Phone number
					\s*<.*>(.*)<.*>.*\n				# $10
					
					.*\n
					
					\s*<B>License\sStatus:</B>.*<B>License\sType:</B>.*\n
					.*\n
					\s*<.*>(.*)<.*>(.*)<.*>			# License status and type:
					}x;								# $11 and $12
	
	# Keep extracted information.
	my $name = "$2 $1";
	my $address = "\"$3, $4, $6, $7\"";
	my $npn = $5;
	my $issued = $8;
	my $expires = $9;
	my $phone = $10;
	my $status = $11;
	my $type = $12;
	
	# Get lines of business
	
	@linesOfBusiness = (
		$agentData =~	m{
						\s*<TR>.*\n
						\s*<td>(.*)</td>.*\n
						.*\n
						.*\n
						.*\n
						.*\n
						\s*</TR>.*\n
						}xgc
	);
		
	# Concat the lines of business together.
	
	my $lines = "";
	foreach $businessLine (@linesOfBusiness)
	{
		$lines = "$lines$businessLine, ";
	}
	
	# Add to the CSV file with column order:
	# Name, Address, Business Phone, License Number, NPN, Issued, Expires, Status, Type, Business Lines
	$csvFile = "$csvFile$name, $address, $phone, $license, $npn, $issued, $expires, $status, $type, $lines\n";
	
	print $csvFile;
}

sub writeFile
{
	open AGENTFILE, ">/home/the-hawk/iddoi_crawler/idagents.csv";
	print AGENTFILE $csvFile;
	close AGENTFILE;
}
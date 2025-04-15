#!/usr/bin/perl
use strict;
use warnings;
use lib qw(../lib);
use C4::Circulation;
use Koha::Script;
use C4::Context;
use Getopt::Long;

my ($help, $verbose, $biblionumber, $patron_id);
my $renewals = 0;

GetOptions(
    'h|help'             => \$help,
    'v|verbose'          => \$verbose,
    'biblionumber=i'     => \$biblionumber,
    'renewals=i'           => \$renewals,
    'patron_id=i'        => \$patron_id,
);

my $usage = << 'ENDUSAGE';

    Adds checkouts to all items in a specified biblio.
    Also adds renewals if specified.

    This script has the following parameters :
    -h --help         This help.
    -v --verbose      Verbose output.
    --biblionumber    The biblionumber to add checkouts to.
    --renewals        The number of renewals to add.
    --patron_id       The patron ID to use for checking out items.

    Example:
    perl add_checkouts_and_renewals.pl --biblionumber 123 --renewals 2 --patron_id 1

ENDUSAGE

if ($help) {
    print $usage;
    exit;
}

if (!$biblionumber) {
    print $usage;
    print "\nDefine biblionumber!\n";
    exit 1;
}
my $patron;
if ($patron_id) {
    $patron = Koha::Patrons->find( $patron_id );
    if (!$patron) {
        print "Patron not found!\n";
        exit 1;
    }
}

print "Adding checkouts and renewals for biblionumber $biblionumber.\n";
print "Waiting...\n";
# Connect to the database
my $dbh = C4::Context->dbh;

# Prepare and execute the query to select items from the specified biblio
my $sth = $dbh->prepare("SELECT * FROM items WHERE biblionumber = ?");
$sth->execute($biblionumber);

# Fetch all items
my $items = $sth->fetchall_arrayref({});
$sth->finish;

# Set the user environment
my $THE_library = $patron->library;
C4::Context->set_userenv(
    $patron->borrowernumber,  # number,
    $patron->userid,          # userid,
    $patron->cardnumber,      # cardnumber
    $patron->firstname,       # firstname
    $patron->surname,         # surname
    $THE_library->branchcode, # branch
    $THE_library->branchname, # branchname
    $patron->flags,           # flags,
    $patron->email,           # emailaddress
);
# Iterate over each item
foreach my $item (@$items) {
    # Check if the item is already checked out
    $sth = $dbh->prepare("SELECT * FROM issues WHERE itemnumber = ?");
    $sth->execute($item->{itemnumber});
    my $issue = $sth->fetchrow_hashref;
    $sth->finish;

    # Fetch a random borrower
    $sth = $dbh->prepare("SELECT * FROM borrowers ORDER BY RAND() LIMIT 1");
    $sth->execute();
    my $borrower = $sth->fetchrow_hashref;
    warn $borrower;
    $sth->finish;

    if ($issue) {
        # Add a return for the item
        print "Adding return for item " . $item->{itemnumber} . ".\n" if $verbose;
        C4::Circulation::AddReturn( $item->{barcode}, $item->{holdingbranch} );
    }
    # Add a checkout for the item
    my $patron = Koha::Patrons->find( $borrower->{borrowernumber} );
    my $due_date = DateTime->now->add( days => 14 );
    C4::Circulation::AddIssue( $patron, $item->{barcode} );
    print "Item " . $item->{itemnumber} . " checked out to borrower " . $borrower->{cardnumber} . ".\n" if $verbose;

    if ($renewals) {
        for (1..$renewals) {
            # Add a renewal for the item
            print "Adding renewal for item " . $item->{itemnumber} . ".\n" if $verbose;
            C4::Circulation::AddRenewal({
                borrowernumber   => $borrower->{borrowernumber},
                itemnumber       => $item->{itemnumber},
                branch           => $borrower->{branchcode},
            });
        }
    }


    # Sleep for a short duration to avoid overwhelming the system
    sleep(0.1);
}

print "Checkouts and renewals completed for all items in biblionumber $biblionumber.\n";

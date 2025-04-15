#!/usr/bin/perl

use strict;
use warnings;
use C4::Context;
use C4::Members;
use Koha::Patrons;
use Koha::Patron::Relationships;

# Configuration
my $guarantor_borrowernumber = 5; # Replace with your guarantor's borrowernumber
my $relationship = 'father'; # The relationship type

# Connect to the database
my $dbh = C4::Context->dbh();

# Add guarantees for borrowernumbers 1-53
for my $guarantee_id (54..700) {
    # Skip if guarantee is the same as guarantor
    if ($guarantee_id == $guarantor_borrowernumber) {
        print "Skipping guarantor #$guarantor_borrowernumber as guarantee (can't be both)\n";
        next;
    }
    
    # Check if patron exists
    my $guarantee = Koha::Patrons->find($guarantee_id);
    my $guarantor = Koha::Patrons->find($guarantor_borrowernumber);
    
    unless ($guarantee && $guarantor) {
        print "Error: One of the patrons doesn't exist (Guarantor: $guarantor_borrowernumber, Guarantee: $guarantee_id)\n";
        next;
    }
    
    # Check if relationship already exists
    my $existing = Koha::Patron::Relationships->search({
        guarantor_id => $guarantor_borrowernumber,
        guarantee_id => $guarantee_id
    })->count();
    
    if ($existing) {
        print "Relationship already exists for guarantee #$guarantee_id, skipping.\n";
        next;
    }
    
    # Create relationship
    eval {
        Koha::Patron::Relationship->new({
            guarantor_id => $guarantor_borrowernumber,
            guarantee_id => $guarantee_id,
            relationship => $relationship
        })->store();
        print "Added relationship: Guarantor $guarantor_borrowernumber -> Guarantee $guarantee_id\n";
    };
    if ($@) {
        print "Error adding relationship for guarantee #$guarantee_id: $@\n";
    }
}

print "Processing complete.\n";

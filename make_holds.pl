#! /usr/bin/perl
use t::lib::TestBuilder;
use Koha::Libraries;
use Koha::Holds;
use Koha::Patrons;
use Koha::DateUtils qw( dt_from_string );

my $libraries = Koha::Libraries->search();
my $builder = t::lib::TestBuilder->new(); 
#my @statuses = ('ASKED', 'CHECKED', 'ACCEPTED', 'REJECTED', 'ORDERED', 'AVAILABLE');

while( my $library = $libraries->next) {
my $several = 10;
    for( my $i = 0; $i < $several; $i++ ){
        my $holder = Koha::Patrons->find( int(rand(50))+1 );
        my $biblio = Koha::Biblios->find( int(rand(436)) );
        next unless $biblio;
        my $item = $biblio->items->search({},{ order_by => \["rand()"] })->next;
        my $itemnumber = $item ? $item->itemnumber : undef;
        $builder->build_object({
            class => "Koha::Holds",
            value => {
                borrowernumber => $holder->borrowernumber,
                biblionumber => $biblio->biblionumber,
                reservedate => '2024-07-24',
                branchcode  => 'CPL',
                desk_id => undef,
                cancellationdate => undef,
                cancellation_reason => undef,
                timestamp => '2024-07-24 16:59:42', 
                priority => 0,
                found => undef, 
                itemnumber => $itemnumber,
                waitingdate => '2024-07-24',
                expirationdate => '2024-07-30',
                suspend => 0,
                suspend_until=>undef,
                item_level_hold => $itemnumber ? 1 : 0,
                itemtype => undef,
                patron_expiration_date => undef,
                lowestPriority => 0,
            }
        });
    }   
}

1;

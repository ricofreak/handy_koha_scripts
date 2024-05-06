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
my $several = int( rand(100) );
    for( my $i = 0; $i < $several; $i++ ){
        my $holder = Koha::Patrons->find( int(rand(50))+1 );
#my $biblio = Koha::Biblios->find( int(rand(432))+1 );
        my $biblio = Koha::Biblios->find( 144 );
        next unless $biblio;
        my $item = $biblio->items->search({},{ order_by => \["rand()"] })->next;
        my $itemnumber = $item ? $item->itemnumber : undef;
        $builder->build_object({
            class => "Koha::Holds",
            value => {
                borrowernumber => $holder->borrowernumber,
                biblionumber => $biblio->biblionumber,
                reservedate => dt_from_string(),
                branchcode  => 'MPL',
                desk_id => undef,
                cancellationdate => undef,
                cancellation_reason => undef,
                timestamp => dt_from_string, 
                priority => 0,
                found => '', 
                itemnumber => $itemnumber,
                waitingdate => '2024-04-06',
                expirationdate => '2024-05-06',
                suspend => 0,
                suspend_until=>undef,
                item_level_hold => $itemnumber ? 1 : 0,
                itemtype => undef,
                patron_expiration_date => '2024-03-30',
                lowestPriority => 0,
            }
        });
    }   
}

1;

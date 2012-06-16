package Plagger::Plugin::CustomFeed::Scraper;
use strict;
use warnings;
use base qw( Plagger::Plugin );
use lib qw(/home/toshi/perl/lib);
use Scrape2Feed;
use feature 'say';

sub register {
	my($self, $context) = @_;
	$context->register_hook(
		$self,
		'subscription.load' => \&load,
	);
}

sub load {
	my($self, $context) = @_;
	my $feed = Plagger::Feed->new;
	$feed->aggregator(sub { $self->aggregate($context) });
	$context->subscription->add($feed);
}

sub get_contents {
	my($self, $context) = @_;

	my $setting = $self->conf->{setting};
	my $start_page =  $self->conf->{start_page} || 1;
	my $last_page = $self->conf->{last_page} || 1;
	my $url = $self->conf->{url} || undef;

	my $scrape = Scrape2Feed->new({'site_name' => $setting });
	$scrape->url($url) if (defined($url));

	$context->log( info => "get contents via Scrape2Feed.pm");
	my $contents = $scrape->get_contents($start_page, $last_page);
	return $contents;
}


sub aggregate {
	my ($self, $context ) = @_;

	my $feed = Plagger::Feed->new;

	my $contents = $self->get_contents($self,$context);

	foreach my $value (@$contents){
		if (defined($value->{site_title})){
			$feed->title($value->{site_title});
			$feed->link($value->{url});
			$feed->id('Scrape2Feed.pm');
			$feed->type('CustomFeed'); 
			last;
		}else{
			next;
		}
	}


	foreach my $value (@$contents){
		foreach my $value2 (@{$value->{container}}){
			my $entry = Plagger::Entry->new;
			$entry->title($value2->{entry_title}),
			$entry->link($value2->{entry_permalink}),
			$entry->body($value2->{entry_content}),
			$entry->date($value2->{entry_date}),
			$feed->add_entry($entry);
		}
	}
	$context->update->add($feed);
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Scraperr

=head1 SYNOPSIS

  - module: CustomFeed::Scraper
    config:
     setting: NAME OF THE SITE INFOMATION
     start_page: 1
     last_paget: 3
     url: undef or specify scraping page of the site

	YOU NEED MAKE A SITE INFOMATION ON SETTING FILE IN THE CONFIG PIT DIRECTORY
	SEE ALSO 

	https://github.com/azwad/Scrape2Feed/blob/master/site_settings.yaml


=head1 AUTHOR

Toshi Azwad

=cut

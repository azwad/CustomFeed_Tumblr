package Plagger::Plugin::CustomFeed::Tumblr;
use strict;
use warnings;
use base qw( Plagger::Plugin );
use lib qw(/home/toshi/perl/lib);
use TumblrDashboard;
#use YAML;
use Encode;
#use utf8;
#use feature qw( say );
#use DateTime::Format::Epoch;

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

sub get_dashboard {
    my($self, $context, $args) = @_;

		my $pit_account = $self->conf->{pit_account};
		my $td = TumblrDashboard->new($pit_account);
		my $offset = $self->conf->{offset};
	  my $num 	 = $self->conf->{num};
		my $type	 = $self->conf->{type};

		my %opt = (
				'start' => $offset,
				'num'		=> $num,
				'type'	=> $type,
				'filter'=> 'none',
				'likes' => '0',
		);

		$td->set_option(%opt);
		return my $res = $td->get_hash;		
}

sub aggregate {
    my ($self, $context ) = @_;

    my $feed = Plagger::Feed->new;
		$feed->link('http://tumblr.com');
    $feed->type('Tumblr.Dashboard');
    $feed->title("Tumblr Dashboard"); 
    $feed->id('Tumblr:Dahboard'); 

		my $res = $self->get_dashboard;

		my $dbname = 'tumblr_deduped_check';
		my %deduped;
		dbmopen(%deduped, $dbname, 0644);
		my $deduped =\%deduped;

		while (my ($post, $values) = each %$res) {
			my $entry = Plagger::Entry->new;

			if (exists $deduped{$post}){
				print "match an old post\n";
				next;
			}else {
				my @urls =();
				while (my ($number, $url) = each %$deduped){
					push(@urls,$url);
				}

				my $date = $values->{date};
				my $publish_type = $values->{type};
				$_ =  $values->{'quote-source'} || $values->{'link-description'} 
							|| $values->{'photo-caption'};
				s/<a href="(http.+?)".*>(.+?)<\/a>/$1,$2/ ;
				my $title = $2;
				my $link =  $1 || $values->{'photo-link-url'} || $values->{'url'};

				if (  grep{ my $var = $_;
							$var =~ /^$link/ || $link =~ /^$var/ } @urls ){
					next;
				}else{
					my $text = $values->{'quote-text'} || $values->{'link-text'}
										 || $values->{'regular-body'};
					$text =~ s/<.*?>//g;
					$deduped{$post} = $link;

					decode_utf8($title);
					decode_utf8($text);

		  		$entry->title($title);
			    $entry->link($link);
			    $entry->body($text);
			    $entry->date($date);
					$feed->add_entry($entry);
     	  }
			}
		}
	$context->update->add($feed);
}
1;

__END__

=head1 NAME

Plagger::Plugin::CusiomFeed::Tumblr

=head1 SYNOPSIS

  - module: CustomFeed::Tumblr
    config:
     put_account: YOUR PIT ACCOUNT
     offset: 0
     type: 'quote'
     num: 100

=head1 AUTHOR

Toshi Azwad

=cut

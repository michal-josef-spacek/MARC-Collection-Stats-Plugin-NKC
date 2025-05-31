package MARC::Collection::Stats::Plugin::NKC::LargestPublishersSince;

use base qw(MARC::Collection::Stats::Abstract);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use English;
use Error::Pure qw(err);
use Error::Pure::Utils qw(clean);
use List::Util 1.33 qw(any);
use MARC::Field008;
use MARC::Leader 0.04;
use MARC::Leader::Utils qw(material_type);
use NKC::MARC::Cleanups qw(clean_publisher_name);

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	my ($object_params_ar, $other_params_ar) = split_params([
		'largests_publishers_count', 'year_from'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Count of largest publishers.
	$self->{'largests_publishers_count'} = 10;

	# Year from.
	$self->{'year_from'} = 2000;

	# Process parameters.
	set_params($self, @{$object_params_ar});

	return $self;
}

sub name {
	my $self = shift;

	return 'largest_publishers_since';
}

sub process {
	my ($self, $marc_record) = @_;

	my $process = 0;

	my $leader_string = $marc_record->leader;
	my $leader = MARC::Leader->new(
		'verbose' => $self->{'verbose'},
	)->parse($leader_string);
	my $material_type = eval {
		material_type($leader);
	};
	if ($EVAL_ERROR) {
		$self->{'struct'}->{'stats'}->{'not_material'}++;
		clean();
	} else {
		my $field_008_string = $marc_record->field('008')->as_string;
		my $field_008 = eval {
			MARC::Field008->new(
				'leader' => $leader,
				'verbose' => $self->{'verbose'},
			)->parse($field_008_string);
		};
		if ($EVAL_ERROR) {
			my $cnb = $marc_record->field('015')->subfield('a');
			if ($self->{'debug'}) {
				print "CNB id '$cnb' has not valid 008 field.\n";
			}
			$self->{'struct'}->{'stats'}->{'not_valid_008'}++;
			clean();
		} else {
			if ($field_008->date1 =~ m/[u\|\ ]/ms) {
				$self->{'struct'}->{'stats'}->{'not_comparable_008_date'}++;
			} elsif ($field_008->date1 < $self->{'year_from'}) {
				$self->{'struct'}->{'stats'}->{'not_since'}++;
			} else {
				if ($material_type eq 'book') {
					my @keys;
					$self->_process_publisher($marc_record, \@keys, '260');
					$self->_process_publisher($marc_record, \@keys, '264');
					foreach my $key (@keys) {
						$self->{'struct'}->{'stats'}->{'helper'}->{$key}++;
					}
				} else {
					$self->{'struct'}->{'stats'}->{'not_book'}++;
				}
			}
		}
	}

	return;
}

sub postprocess {
	my $self = shift;

	my $num = 0;
	foreach my $key (reverse sort { $self->{'struct'}->{'stats'}->{'helper'}->{$a}
		<=> $self->{'struct'}->{'stats'}->{'helper'}->{$b} }
		keys %{$self->{'struct'}->{'stats'}->{'helper'}}) {

		$num++;
		if ($num > $self->{'largests_publishers_count'}) {
			last;
		}

		$self->{'struct'}->{'stats'}->{'largest_book_publishers'}->{$key}
			= $self->{'struct'}->{'stats'}->{'helper'}->{$key};
	}

	delete $self->{'struct'}->{'stats'}->{'helper'};

	return;
}

sub _init {
	my $self = shift;

	$self->{'struct'}->{'module_name'} = __PACKAGE__;
	$self->{'struct'}->{'module_version'} = $VERSION;

	$self->{'struct'}->{'parameters'}->{'year_from'} = $self->{'year_from'};
	$self->{'struct'}->{'parameters'}->{'largests_publishers_count'} = $self->{'largests_publishers_count'};

	$self->{'struct'}->{'stats'}->{'largest_book_publishers'} = {};
	$self->{'struct'}->{'stats'}->{'helper'} = {};

	return;
}

sub _process_publisher {
	my ($self, $marc_record, $keys_ar, $field_num) = @_;

	my @fields = $marc_record->field($field_num);
	foreach my $field (@fields) {
		my $field_b = $field->subfield('b');
		my $field_b_cleaned = clean_publisher_name($field_b);
		if (defined $field_b_cleaned) {
			push @{$keys_ar}, $field_b_cleaned;
		}
	}

	return;
}

1;

__END__

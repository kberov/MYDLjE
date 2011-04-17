package MYDLjE::M::Content;
use MYDLjE::Base 'MYDLjE::M';
require MYDLjE::Unidecode;
require Time::HiRes;

has TABLE => 'my_content';

has COLUMNS => sub {
  [ qw(
      id user_id pid alias title tags featured
      sorting data_type data_format time_created tstamp
      body invisible language group_id protected bad
      )
  ];
};

sub FIELDS_VALIDATION {
  return {
    id      => {required => 0, constraints => [{regexp => qr/^\d+$/x},]},
    user_id => {required => 1, constraints => [{regexp => qr/^\d+$/x},]},
    alias   => {
      required    => 1,
      constraints => [{regexp => qr/^[\-_a-z0-9]{2,255}$/x},]
    },
    data_type => {
      required => 1,
      constraints =>
        [{regexp => qr/(page|question|answer|book|note|article|chapter)/x},]
    },
    data_format => {
      required    => 1,
      constraints => [{regexp => qr/(textile|text|html|markdown,template)/x},]
    },
    language => {required => 1, constraints => [{regexp => qr/[a-z]{2}/x},]}

  };
}

#Make some attributes which are appropriate to any data_type content
sub id {
  if ($_[1]) {
    $_[0]->{data}{id} = $_[0]->validate_field(id => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{id};
}

sub user_id {
  if ($_[1]) {
    $_[0]->{data}{user_id} = $_[0]->validate_field(user_id => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{user_id};
}


sub alias {
  my ($self, $value) = @_;
  if ($value) {
    $self->{data}{alias} = $self->validate_field(alias => $value);

    #make it chainable
    return $self;
  }

  unless ($self->{data}{alias}) {
    $self->{data}{alias} = lc(
      $self->title
      ? MYDLjE::Unidecode::unidecode($self->title)
      : Mojo::Util::md5_sum(Time::HiRes::time())
    );
    $self->{data}{alias} =~ s/\W$//x;
  }
  return $self->{data}{alias};
}

sub title {
  if ($_[1]) {
    $_[0]->{data}{title} = $_[0]->validate_field(title => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{title};
}

sub tags {
  if ($_[1]) {
    $_[0]->{data}{tags} = $_[0]->validate_field(tags => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{tags};
}

sub featured {
  if ($_[1]) {
    $_[0]->{data}{featured} = $_[0]->validate_field(featured => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{featured};
}

sub sorting {
  if ($_[1]) {
    $_[0]->{data}{sorting} = $_[0]->validate_field(sorting => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{sorting};
}

sub data_type {
  my ($self, $value) = @_;
  if ($value) {
    $self->{data}{data_type} = $self->validate_field(data_type => $value);

    #make it chainable
    return $self;
  }
  unless ($self->{data}{data_type}) {
    my $type = lc(ref($self));
    $type =~ /(\w+)$/x and $self->{data}{data_type} = $1;
  }
  return $self->{data}{data_type};
}

sub data_format {
  if ($_[1]) {
    $_[0]->{data}{data_format} = $_[0]->validate_field(data_format => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{data_format};
}

sub time_created {
  if ($_[1]) {
    $_[0]->{data}{time_created} =
      $_[0]->validate_field(time_created => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{time_created};
}

sub tstamp {
  if ($_[1]) {
    $_[0]->{data}{tstamp} = $_[0]->validate_field(tstamp => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{tstamp};
}

sub body {
  if ($_[1]) {
    $_[0]->{data}{body} = $_[0]->validate_field(body => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{body};
}

sub invisible {
  if ($_[1]) {
    $_[0]->{data}{invisible} = $_[0]->validate_field(invisible => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{invisible};
}

sub language {
  if ($_[1]) {
    $_[0]->{data}{language} = $_[0]->validate_field(language => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{language};
}

sub groups {
  if ($_[1]) {
    $_[0]->{data}{groups} = $_[0]->validate_field(groups => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{groups};
}

sub protected {
  if ($_[1]) {
    $_[0]->{data}{protected} = $_[0]->validate_field(protected => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{protected};
}

sub bad {
  if ($_[1]) {
    $_[0]->{data}{bad} = $_[0]->validate_field(bad => $_[1]);

    #make it chainable
    return $_[0];
  }
  return $_[0]->{data}{bad};
}

1;

__END__

=head1 NAME

MYDLjE::M::Content - Base class for all semantic content data_types

=head1 DESCRIPTION



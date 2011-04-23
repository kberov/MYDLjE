package MYDLjE::M::Content;
use MYDLjE::Base 'MYDLjE::M';
require MYDLjE::Unidecode;
require Time::HiRes;

has TABLE => 'my_content';

has COLUMNS => sub {
  [ qw(
      id alias pid user_id sorting data_type data_format
      time_created tstamp title description keywords tags
      body invisible language group_id protected
      featured accepted bad
      )
  ];
};
my $id_constraints = {constraints => [{regexp => qr/^\d+$/x},]};

sub _no_markup_inflate {
  my $filed = shift;
  my $value = $filed->value || '';

  #remove everything strange
  $value =~ s/[^\p{IsAlnum}\,\s\-\!\.\?\(\);]//gxi;
  $value = substr($value, 0, 255) if length($value) > 255;
  return $value;
}

sub _tags_inflate {
  my $filed = shift;
  my $value = $filed->value || '';
  $value =~ s/[^\p{IsAlnum}\,\s]//gxi;
  my @words = split /[\,\s]/xi, $value;
  $value = join ", ", @words;
  return $value;
}


sub FIELDS_VALIDATION {
  return {
    id      => {required => 0, %$id_constraints},
    pid     => {required => 0, %$id_constraints},
    user_id => {required => 1, %$id_constraints},
    sorting => {required => 0, %$id_constraints},
    alias   => {
      required    => 1,
      constraints => [{regexp => qr/^[\-_a-zA-Z0-9]{3,255}$/x},]
    },
    title       => {required => 0, inflate => \&_no_markup_inflate},
    tags        => {required => 0, inflate => \&_tags_inflate},
    keywords    => {required => 0, inflate => \&_tags_inflate},
    description => {required => 0, inflate => \&_no_markup_inflate},

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

#Make some attributes which are appropriate to any data_type of content

sub alias {
  my ($self, $value) = @_;
  if ($value) {
    $self->{data}{alias} = $self->validate_field(alias => $value);
    return $self;
  }

  unless ($self->{data}{alias}) {
    $self->{data}{alias} = lc(
      $self->title
      ? MYDLjE::Unidecode::unidecode($self->title)
      : Mojo::Util::md5_sum(Time::HiRes::time())
    );
    $self->{data}{alias} =~ s/\W+$//x;
    $self->{data}{alias} =~ s/^\W+//x;
  }
  return $self->{data}{alias};
}

sub data_type {
  my ($self, $value) = @_;
  if ($value) {
    $self->{data}{data_type} = $self->validate_field(data_type => $value);

    return $self;
  }
  unless ($self->{data}{data_type}) {
    my $type = lc(ref($self));
    $type =~ /(\w+)$/x and $self->{data}{data_type} = $1;
  }
  return $self->{data}{data_type};
}

sub tstamp {
  my ($self) = @_;
  return $self->{data}{tstamp} ||= time;    #setting getting
}

sub id {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{id} = $self->validate_field(id => $value);
    return $self;
  }
  return $self->{data}{id};                 #getting
}

sub user_id {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{user_id} = $self->validate_field(user_id => $value);
    return $self;
  }
  return $self->{data}{user_id};            #getting
}

sub group_id {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{group_id} = $self->validate_field(group_id => $value);
    return $self;
  }
  return $self->{data}{group_id};           #getting
}

sub pid {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{pid} = $self->validate_field(pid => $value);
    return $self;
  }
  return $self->{data}{pid};                #getting
}

sub title {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{title} = $self->validate_field(title => $value);
    return $self;
  }
  return $self->{data}{title};              #getting
}

sub tags {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{tags} = $self->validate_field(tags => $value);
    return $self;
  }
  return $self->{data}{tags};               #getting
}

sub keywords { goto &tags; }

sub featured {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{featured} = 1;
    return $self;
  }
  return $self->{data}{featured} if defined $self->{data}{featured};  #getting
  return $self->{data}{featured} = 0;                                 #default
}

sub sorting {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{sorting} = $self->validate_field(sorting => $value);
    return $self;
  }
  return $self->{data}{sorting};                                      #getting
}

sub data_format {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{data_format} = $self->validate_field(data_format => $value);
    return $self;
  }
  return $self->{data}{data_format};                                  #getting
}

sub time_created {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    if   ($value =~ /(\d{10,})/x) { $self->{data}{time_created} = $1 }
    else                          { $self->{data}{time_created} = time; }
    return $self;
  }
  return $self->{data}{time_created} ||= time;                        #getting
}

sub body {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{body} = $self->validate_field(body => $value);
    return $self;
  }
  return $self->{data}{body};                                         #getting
}

sub invisible {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{invisible} = 1;
    return $self;
  }
  return $self->{data}{invisible}
    if defined $self->{data}{invisible};                              #getting
  return $self->{data}{invisible} = 0;                                #default
}

sub language {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{language} = $self->validate_field(language => $value);
    return $self;
  }
  return $self->{data}{language};                                     #getting
}

sub protected {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{protected} = 1;
    return $self;
  }
  return $self->{data}{protected}
    if defined $self->{data}{protected};                              #getting
  return $self->{data}{protected} = 0;                                #default
}

sub bad {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{bad}++;
    return $self;
  }
  return $self->{data}{bad} if defined $self->{data}{bad};            #getting
  return $self->{data}{bad} = 0;                                      #default
}

1;

__END__


=head1 NAME

MYDLjE::M::Content - Base class for all semantic content data_types

=head1 DESCRIPTION

In MYDLjE all the content is stored in a database table - C<my_content>. There are several semantic types of content. This semantic type is determined by the column C<data_type>.

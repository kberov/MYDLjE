package MYDLjE::M::Content;
use MYDLjE::Base 'MYDLjE::M';

has TABLE => 'my_content';

has COLUMNS => sub {
  [ qw(
      id user_id pid alias title tags
      sorting data_type data_format time_created tstamp
      body invisible language groups protected bad
      )
  ];
};

#Make some attributes which are appropriate to any data_type content
sub id           { return shift->data('id',           @_) }
sub user_id      { return shift->data('user_id',      @_) }
sub pid          { return shift->data('pid',          @_) }
sub alias        { return shift->data('alias',        @_) }
sub title        { return shift->data('title',        @_) }
sub tags         { return shift->data('tags',         @_) }
sub sorting      { return shift->data('sorting',      @_) }
sub data_type    { return shift->data('data_type',    @_) }
sub data_format  { return shift->data('data_format',  @_) }
sub time_created { return shift->data('time_created', @_) }

sub tstamp    { return shift->data('tstamp',    @_) }
sub body      { return shift->data('body',      @_) }
sub invisible { return shift->data('invisible', @_) }
sub language  { return shift->data('language',  @_) }
sub groups    { return shift->data('groups',    @_) }
sub protected { return shift->data('protected', @_) }
sub bad       { return shift->data('bad',       @_) }

1;

__END__

=head1 NAME

MYDLjE::M::Content - Base class for all content data_types

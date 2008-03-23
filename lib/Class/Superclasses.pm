package Class::Superclasses;

use strict;
use warnings;
use PPI;

our $VERSION = '0.05';

sub new{
    my ($class,$doc) = @_,
    my $self         = {};
    bless $self,$class;
    
    $self->document($doc);
    
    return $self;
}# new

sub superclasses{
    my ($self) = @_; 
    return wantarray ? @{$self->{super}} : $self->{super};
}# superclasses

sub document{
    my ($self,$doc) = @_;
    if(defined $doc){
        $self->{document} = $doc;
        $self->{super}    = $self->_find_super($doc);
    }
}# document

sub _find_super{
    my ($self,$doc) = @_;
    my $ppi    = PPI::Document->new($doc) or die $!;
    
    my $varref = $ppi->find('PPI::Statement::Variable');
    my @vars   = ();
    if($varref){
        @vars    = $self->_get_isa_values($varref);
    }
    
    my $baseref  = $ppi->find('PPI::Statement::Include');
    my @base     = ();
    my @includes = qw(base parent);
    if($baseref){
        @base = $self->_get_include_values([grep{my $i = $_->module; grep{ $_ eq $i }@includes }@$baseref]);
    }
    return [@vars,@base];
} # _find_super

sub _get_include_values{
    my ($self,$baseref) = @_;
    my @parents;
    for my $base(@$baseref){
        my @tmp_array;
        if( $base->find_any('PPI::Statement::Expression') ){
            push(@parents,$self->_parse_expression( $base ));
        }
        elsif( $base->find_any('PPI::Token::QuoteLike::Words') ){
            push(@parents,$self->_parse_quotelike( $base ));
        }
        elsif( $base->find( \&_any_quotes ) ){
            push @parents,$self->_parse_quotes( $base );
        }
        @tmp_array = grep{ $_ ne '-norequire' }@tmp_array if $base->module eq 'parent';
        push @parents, @tmp_array;
    }
    return @parents;
}# _get_base_values

sub _any_quotes{
    my ($parent,$elem) = @_;
    
    $parent == $elem->parent and (
        $elem->isa( 'PPI::Token::Quote::Double' ) or
        $elem->isa( 'PPI::Token::Quote::Single' )
    );
}

sub _get_isa_values{
    my ($self,$varref) = @_;
    my @parents;
    for my $variable(@$varref){
        my @children = $variable->children();
        #print Dumper($variable);
        
        if(grep{$_->content() eq '@ISA'}@children){
            if($variable->find_any('PPI::Statement::Expression')){
                push(@parents,$self->_parse_expression($variable));
            }
            elsif($variable->find_any('PPI::Token::QuoteLike::Words')){
                push(@parents,$self->_parse_quotelike($variable));
            }
        }
    }
    return @parents;
}# _get_values

sub _parse_expression{
    my ($self,$variable) = @_;
    my $ref = $variable->find('PPI::Statement::Expression');
    my @parents;
    for my $element($ref->[0]->children()){
        if($element->class =~ /^PPI::Token::Quote::/){
            push( @parents,$element->string );
        }
    }
    return @parents;
}# _parse_expression

sub _parse_quotes{
    my ($self,$variable,$type) = @_;
    
    my @parents;
    
    for my $element( $variable->children ){
        my ($type) = ref($element) =~ /PPI::Token::Quote::([^:]+)$/;
        next unless $type;
        my $value  = $element->string;
        push @parents, $value;
    }

    return @parents;
}

sub _parse_quotelike{
    my ($self,$variable) = @_;
    my $words         = ($variable->find('PPI::Token::QuoteLike::Words'))[0]->[0];
    my $operator      = $words->{operator};
    my $section_type  = $words->{sections}->[0]->{type};
    my ($left,$right) = split(//,$section_type);
    $right            = $left unless defined $right;
    (my $value        = $words->content()) =~ s~$operator\Q$left\E(.*)\Q$right\E~$1~;
    my @parents       = split(/\s+/,$value);
    return @parents;
}# _parse_quotelike


1;

=pod

=head1 NAME

Class::Superclasses - Find all superclasses of a class

=head2 DESCRIPTION

C<Class::Superclasses> uses L<PPI> to get the superclasses of a class;

=head1 SYNOPSIS

  use Class::Superclasses;
  
  my $class_file = '/path/to/class_file.pm';
  my $parser = Class::Superclasses->new();
  $parser->document($class_file);
  my @superclasses = $parser->superclasses();
  
  print $_,"\n" for(@superclasses);

=head1 METHODS

=head2 new

creates a new object of C<Class::Superclasses>. 

  my $parser = Class::Superclasses->new();
  # or
  my $parser = Class::Superclasses->new($filename);

=head2 superclasses

returns in list context an array of all superclasses of the Perl class, in
scalar context it returns an arrayref.

  my $arrayref = $parser->superclasses();
  my @array = $parser->superclasses();

=head2 document

tells C<Class::Superclasses> which Perl class should be analyzed.

  $parser->document($filename);

=head1 PREREQUESITS

  PPI

=head1 SEE ALSO

L<PPI>, L<Class::Inheritance>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

copyright 2006 - 2007
Renee Baecker E<lt>module@renee-baecker.deE<gt>

=cut

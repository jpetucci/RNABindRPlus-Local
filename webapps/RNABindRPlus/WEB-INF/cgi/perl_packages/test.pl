#!usr/bin/perl -w
#use Thread;
use Thread  qw(async);
my $something='xue';
for my $t (Thread->list()) {
    printf "$t has tid = %d\n", $t->tid();
}
#my $t = async{ say($something);  };

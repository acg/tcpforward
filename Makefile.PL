use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'tcpforward',
  EXE_FILES     => [ 'tcpforward' ],
  VERSION_FROM  => 'tcpforward',
  PREREQ_PM     => {
    'IO::Socket::INET' => 0,
    'Pod::Usage'       => 0,
  },
($] >= 5.005 ?     ## Add these new keywords supported since 5.005
  (ABSTRACT_FROM    => 'tcpforward', 
   AUTHOR           => 'Alan Grow <agrow+nospam@thegotonerd.com>') : ()),
);


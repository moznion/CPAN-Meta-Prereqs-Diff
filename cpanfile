requires 'CPAN::Meta';
requires 'CPAN::Meta::Prereqs';
requires 'Data::Dumper::Concise';
requires 'Module::CPANfile';
requires 'Module::CoreList';
requires 'perl', '5.016003';
requires 'version';

on configure => sub {
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More', '0.98';
};

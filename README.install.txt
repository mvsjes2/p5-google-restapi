Google-RestApi version 0.5
==========================

This a collection of modules that is used for interfacing with
Google's various APIs. Currenly only paritial Drive support is
included, and more comprehensive support for Google Sheets.
Other APIs may be added in future (pull requests welcome).

VERSION
0.1 Initial version, beta status, partial support for Drive
and more comprehensive support for Sheets. New versions will
continue to build out these two APIs to be more complete.

0.2 Breaking change to OAuth2 login procedure. Minor updates
to POD, debug messages, comments etc.

0.3 Added an attrs cache, removed testing dependency for
Spreadsheets::Perl, fixed and added more tests.

0.4 Breaking change to allow for multiple authorization
mechanisms, added support for Google Service Accounts
as a mechanism. Cleaned up request range class and added
more formatting options. Minor bug fixes.

0.5 General code cleanup, documentaion improvements,
test imnprovements. No new features.

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

DEPENDENCIES

This module requires these other modules and libraries:

  aliased
  autodie 
  autovivification
  constant
  Cache::Memory::Simple
  Carp
  Exporter
  Furl 
  Hash::Merge 
  JSON 
  List::MoreUtils
  List::Util
  Net::OAuth2::Client 
  Net::OAuth2::Profile::WebServer 
  Scalar::Util
  Storable
  Sub::Retry 
  Tie::Hash 
  Time::Out
  Type::Params
  Types::Standard
  URI 
  URI::QueryParam 
  WWW::Google::Cloud::Auth::ServiceAccount
  YAML::Any
  Test::Class::Load
  Test::MockObject::Extends
  Test::Most

COPYRIGHT AND LICENCE

Copyright (C) 2019 by Robin Murray

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

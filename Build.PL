
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Report or omit duplicate file contents',
  'dist_author' => [
    'Steven Haryanto <stevenharyanto@gmail.com>'
  ],
  'dist_name' => 'App-UniqFiles',
  'dist_version' => '0.04',
  'license' => 'perl',
  'module_name' => 'App::UniqFiles',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Digest::MD5' => '0',
    'File::Slurp' => '0',
    'File::chdir' => '0',
    'Log::Any' => '0',
    'Log::Any::App' => '0',
    'Sub::Spec' => '0.14',
    'Sub::Spec::CmdLine' => '0',
    'Test::More' => '0.96',
    'perl' => '5.010000'
  },
  'script_files' => [
    'bin/uniq-files'
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;

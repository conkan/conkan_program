# source is CentOS6
FROM centos:centos6

MAINTAINER Studio-REM <rem@s-rem.jp>

#----------------------------------------------------------
# 基本設定
#----------------------------------------------------------
RUN yum -y install https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum -y install witch curl git htop man vim sudo unzip wget tar less perl-CPAN
RUN yum -y update
RUN curl -L http://cpanmin.us | perl - -- App::cpanminus

#----------------------------------------------------------
# shell環境等設定
#----------------------------------------------------------
ENV HOSTNAME conkan_program
ADD doccnf/bashrc /root/.bashrc
ADD doccnf/vimrc /root/.vimrc
RUN rm -f /etc/localtime; ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
ENV TERM xterm
ENV LANG ja_JP.UTF8
ENV LANGAGE ja_JP.UTF8
ENV LC_ALL C
ENV HOME /root
WORKDIR /root

#----------------------------------------------------------
# 対象インストール
#----------------------------------------------------------
# mysql-client
RUN yum -y install mysql mysql-devel
ADD doccnf/my.cnf /etc/my.cnf

# XML:Feedインストールのためのライブラリとgcc
RUN yum -y install gcc patch expat-devel libxml2-devel

#----------------------------------------------------------
# Perlライブラリインストール
#----------------------------------------------------------
# Install Perl Module (Catalyst)
RUN cpanm -in YAML DBI DBD::mysql DBIx::Class DBIx::Class::Cursor::Cached Email::MIME DateTime::Format::MySQL CGI FormValidator::Simple::Plugin::Japanese HTTP::Server::Simple Moose MooseX::Daemonize Test::Expect DBIx::Class::Schema::Loader MooseX::NonMoose LWP::Protocol::https Term::Size::Any XML::LibXML XML::RSS XML::Atom XML::Feed

# Install Perl Module (Catalyst)
RUN cpanm -in Catalyst::Runtime CatalystX::REPL Task::Catalyst Catalyst::Devel Catalyst::Engine::Apache Catalyst::View::TT Catalyst::View::TT::ForceUTF8 Catalyst::View::JSON Catalyst::View::Download::CSV Catalyst::Model::DBI Catalyst::Model::DBIC::Schema Catalyst::Helper::Model::Email Catalyst::Plugin::Session::FastMmap Catalyst::Plugin::Session::Store::FastMmap Catalyst::Plugin::Config::YAML

# OAuthは独自拡張版を使用するが、
# オリジナルも入れておかないと依存モジュールが入らない
RUN cpanm -in Catalyst::Authentication::Credential::OAuth

# Starman
RUN cpanm -i Starman

# cpanm work削除
RUN rm -rf .cpanm/*

#----------------------------------------------------------
# conkan_program実体格納(開発時はマウント)
# 大会独自設定ファイルをデフォルト上書き
#----------------------------------------------------------
COPY ./app /root/app
RUN cp -f /root/app/conkan/conkan.yml_default /root/app/conkan/conkan.yml
#----------------------------------------------------------
# 起動
#----------------------------------------------------------
EXPOSE 9002
CMD [ "/root/app/conkan_run" ]
